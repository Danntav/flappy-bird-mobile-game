import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class TelaJogo extends StatefulWidget {
  @override
  _TelaJogoState createState() => _TelaJogoState();
}

class _TelaJogoState extends State<TelaJogo> {
  static const double gravidade = -1.25;
  static const double forcaPulo = 1;
  static const double intervaloAtualizacao = 0.04;

  double birdY = 0;
  double time = 0;
  double initialHeight = 0;

  double pipeX = 2;
  double gapSize = 0.45;
  double pipeHeight = 0.4;

  double pipeSpeed = 0.02;
  int pipesPassed = 0;
  int score = 0;
  int moedas = 0;

  Timer? gameTimer;
  Timer? volumeTimer;
  bool isGameRunning = false;
  Random random = Random();

  bool pointCounted = false;

  String? skinSelecionada;
  Uint8List? skinPersonalizadaCache;

  AudioPlayer? _audioPlayer;
  double volumeMusica = 0.5;

  @override
  void initState() {
    super.initState();
    carregarSkinSelecionada();
    carregarMoedas();
    carregarVolume().then((_) {
      iniciarMusicaDeFundo();
      iniciarMonitoramentoVolume();
    });
  }

  Future<void> carregarSkinSelecionada() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? skin = prefs.getString('skinSelecionada');

    if (skin != null && !skin.startsWith('assets/')) {
      try {
        skinPersonalizadaCache = base64Decode(skin);
      } catch (e) {
        print('Erro ao decodificar skin personalizada: $e');
        skin = 'assets/flappybird.png';
        await prefs.setString('skinSelecionada', skin);
        skinPersonalizadaCache = null;
      }
    }

    if (skin != null && !skin.startsWith('assets/') && (skinPersonalizadaCache == null || skin.isEmpty)) {
      print('Skin personalizada inválida. Voltando para padrão.');
      skin = 'assets/flappybird.png';
      await prefs.setString('skinSelecionada', skin);
      skinPersonalizadaCache = null;
    }

    setState(() {
      skinSelecionada = skin;
    });
  }

  Future<void> carregarMoedas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      moedas = prefs.getInt('moedas') ?? 30;
    });
  }

  Future<void> carregarVolume() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    volumeMusica = prefs.getDouble('volumeMusica') ?? 0.5;
  }

  void iniciarMusicaDeFundo() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer!.setVolume(volumeMusica);
    await _audioPlayer!.play(AssetSource('audio/background.mp3'));
  }

  void iniciarMonitoramentoVolume() {
    volumeTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      double novoVolume = prefs.getDouble('volumeMusica') ?? 0.5;

      if (novoVolume != volumeMusica) {
        setState(() {
          volumeMusica = novoVolume;
        });
        _audioPlayer?.setVolume(volumeMusica);
      }
    });
  }

  Widget personagem() {
    if (skinSelecionada != null) {
      if (skinSelecionada!.startsWith('assets/')) {
        return Image.asset(
          skinSelecionada!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        );
      } else if (skinPersonalizadaCache != null) {
        return Image.memory(
          skinPersonalizadaCache!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        );
      }
    }

    return Image.asset(
      'assets/flappybird.png',
      width: 50,
      height: 50,
      fit: BoxFit.cover,
    );
  }

  Future<void> _salvarMoedas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('moedas', moedas);
  }

  Future<void> salvarScores() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int recordeAtual = prefs.getInt('recorde') ?? 0;
    if (score > recordeAtual) {
      await prefs.setInt('recorde', score);
    }

    List<String> historico = prefs.getStringList('historicoScores') ?? [];
    historico.insert(0, score.toString());
    if (historico.length > 5) {
      historico = historico.sublist(0, 5);
    }
    await prefs.setStringList('historicoScores', historico);
  }

  bool checkCollision(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final birdWidth = 50.0;
    final birdHeight = 50.0;

    final birdCenterX = screenWidth / 2;
    final birdCenterY = (screenHeight / 2) * (1 + birdY);

    final birdRect = Rect.fromCenter(
      center: Offset(birdCenterX, birdCenterY),
      width: birdWidth,
      height: birdHeight,
    );

    final pipeWidth = 60.0;
    final pipeGap = gapSize * screenHeight;

    final pipeCenterX = (pipeX + 1) * screenWidth / 2;

    final pipeHeightPixels = pipeHeight * screenHeight;
    final pipeTopHeightPixels = screenHeight - pipeHeightPixels - pipeGap;

    final topPipeRect = Rect.fromLTWH(
      pipeCenterX - pipeWidth / 2,
      0,
      pipeWidth,
      pipeTopHeightPixels,
    );

    final bottomPipeRect = Rect.fromLTWH(
      pipeCenterX - pipeWidth / 2,
      pipeTopHeightPixels + pipeGap,
      pipeWidth,
      pipeHeightPixels,
    );

    if (birdCenterY - birdHeight / 2 < 0 || birdCenterY + birdHeight / 2 > screenHeight) {
      return true;
    }

    if (birdRect.overlaps(topPipeRect) || birdRect.overlaps(bottomPipeRect)) {
      return true;
    }

    return false;
  }

  void startGame() {
    isGameRunning = true;
    time = 0;
    initialHeight = birdY;
    pipeX = 2;
    pipeSpeed = 0.02;
    pipesPassed = 0;
    score = 0;
    pointCounted = false;

    gameTimer = Timer.periodic(
      Duration(milliseconds: (intervaloAtualizacao * 1000).toInt()),
      (timer) {
        time += intervaloAtualizacao;
        double height = gravidade * time * time + forcaPulo * time;

        setState(() {
          birdY = initialHeight - height;
          pipeX -= pipeSpeed;

          if (pipeX < -1.5) {
            pipeX = 2;
            pipeHeight = 0.1 + random.nextDouble() * (1 - gapSize - 0.2);
            pipesPassed++;
            pointCounted = false;

            if (pipesPassed % 5 == 0) {
              pipeSpeed += 0.005;
            }
          }

          if (pipeX < 0 && !pointCounted) {
            score++;
            if (score % 2 == 0) {
              moedas++;
              _salvarMoedas();
            }
            pointCounted = true;
          }
        });

        if (checkCollision(context)) {
          gameTimer?.cancel();
          isGameRunning = false;
          salvarScores();
          showGameOverDialog();
        }
      },
    );
  }

  void jump() {
    setState(() {
      time = 0;
      initialHeight = birdY;
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Você bateu! Pontos: $score\nMoedas coletadas: $moedas'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              resetGame();
            },
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    setState(() {
      birdY = 0;
      time = 0;
      pipeX = 2;
      pipeSpeed = 0.02;
      pipesPassed = 0;
      score = 0;
      isGameRunning = false;
      pointCounted = false;
    });
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    volumeTimer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final pipeTopHeight = max(0.1, 1 - pipeHeight - gapSize);

    return GestureDetector(
      onTap: () {
        if (isGameRunning) {
          jump();
        } else {
          startGame();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            AnimatedContainer(
              alignment: Alignment(pipeX, -1 + pipeTopHeight / 2),
              duration: const Duration(milliseconds: 0),
              child: Container(
                width: 60,
                height: screenHeight * pipeTopHeight,
                color: Colors.green,
              ),
            ),
            AnimatedContainer(
              alignment: Alignment(pipeX, 1 - pipeHeight / 2),
              duration: const Duration(milliseconds: 0),
              child: Container(
                width: 60,
                height: screenHeight * pipeHeight,
                color: Colors.green,
              ),
            ),
            AnimatedContainer(
              alignment: Alignment(0, birdY),
              duration: const Duration(milliseconds: 0),
              child: personagem(),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: Text(
                'Score: $score  |  Moedas: $moedas',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
              ),
            ),
            if (!isGameRunning)
              const Center(
                child: Text(
                  'Toque para começar',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
