import 'package:flutter/material.dart';
import 'TelaTutorial.dart';
import 'TelaJogo.dart';
import 'TelaSkins.dart';
import 'TelaRanking.dart';
import 'TelaConfig.dart';

void main() {
  runApp(FlappyApp());
}

class FlappyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flappy - ADS',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: TelaInicial(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TelaInicial extends StatefulWidget {
  @override
  _TelaInicialState createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  int _indiceAtual = 0;

  final List<Widget> _paginas = [
    TelaJogo(),
    TelaSkins(),
    TelaRanking(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _indiceAtual = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flappy - Jogo de ADS'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'config') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TelaConfiguracoes()));
              } else if (value == 'ajuda') {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TelaTutorial()));
              }
            },
            itemBuilder: (BuildContext context) => const [
              PopupMenuItem<String>(
                value: 'config',
                child: Text('Configurações'),
              ),
              PopupMenuItem<String>(
                value: 'ajuda',
                child: Text('Ajuda / Tutorial'),
              ),
            ],
          ),
        ],
      ),
      body: _paginas[_indiceAtual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: 'Jogar'),
          BottomNavigationBarItem(icon: Icon(Icons.face), label: 'Skins'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Ranking'),
        ],
      ),
    );
  }
}