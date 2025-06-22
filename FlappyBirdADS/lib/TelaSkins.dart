import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaSkins extends StatefulWidget {
  @override
  _TelaSkinsState createState() => _TelaSkinsState();
}

class _TelaSkinsState extends State<TelaSkins> {
  List<String> lojaSkins = [
    'assets/FlappyBug.png',
    'assets/FlappyRed.png',
    'assets/FlappyDragon.png',
  ];

  List<String> skinsPersonalizadas = [];
  List<String> skinsCompradas = []; // Lista de skins da loja já compradas
  int moedas = 0;
  String? skinSelecionada;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      moedas = prefs.getInt('moedas') ?? 30;
      skinsPersonalizadas = prefs.getStringList('skinsPersonalizadas') ?? [];
      skinsCompradas = prefs.getStringList('skinsCompradas') ?? [];
      skinSelecionada = prefs.getString('skinSelecionada') ?? 'assets/flappybird.png';
    });
  }

  Future<void> _salvarSkinsPersonalizadas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('skinsPersonalizadas', skinsPersonalizadas);
  }

  Future<void> _salvarSkinsCompradas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('skinsCompradas', skinsCompradas);
  }

  Future<void> _selecionarImagem() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagemSelecionada = await picker.pickImage(source: ImageSource.gallery);

    if (imagemSelecionada != null) {
      final bytes = await imagemSelecionada.readAsBytes();

      if (bytes.length > 300 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagem muito grande! Máximo de 300KB.')),
        );
        return;
      }

      String base64Imagem = base64Encode(bytes);

      setState(() {
        skinsPersonalizadas.add(base64Imagem);
      });

      _salvarSkinsPersonalizadas();
    }
  }

  Future<void> _deletarSkinPersonalizada(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String skinDeletar = skinsPersonalizadas[index];

    String? skinAtual = prefs.getString('skinSelecionada');
    if (skinAtual == skinDeletar) {
      await prefs.setString('skinSelecionada', 'assets/flappybird.png');
      setState(() {
        skinSelecionada = 'assets/flappybird.png';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Skin em uso foi deletada. Voltando para a padrão!')),
      );
    }

    setState(() {
      skinsPersonalizadas.removeAt(index);
    });

    await _salvarSkinsPersonalizadas();
  }

  Future<void> _selecionarSkin(String skinPathOrBase64) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('skinSelecionada', skinPathOrBase64);
    setState(() {
      skinSelecionada = skinPathOrBase64;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Skin selecionada!')),
    );
  }

  void _comprarSkin(int index) async {
    String skin = lojaSkins[index];

    if (skinsCompradas.contains(skin)) {
      _selecionarSkin(skin);
      return;
    }

    if (moedas >= 10) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        moedas -= 10;
        skinsCompradas.add(skin);
      });
      prefs.setInt('moedas', moedas);
      await _salvarSkinsCompradas();

      _selecionarSkin(skin);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moedas insuficientes!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loja de Skins'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            Text('Moedas: $moedas', style: TextStyle(fontSize: 18)),
            Divider(),

            Text('Skin Padrão', style: TextStyle(fontSize: 20)),
            ListTile(
              leading: Image.asset(
                'assets/flappybird.png',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
              title: Text('Flappy Bird (Padrão)'),
              trailing: TextButton(
                onPressed: () => _selecionarSkin('assets/flappybird.png'),
                child: Text(
                  skinSelecionada == 'assets/flappybird.png' ? 'Equipado' : 'Selecionar',
                ),
              ),
            ),

            Divider(),

            Text('Skins da Loja', style: TextStyle(fontSize: 20)),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: lojaSkins.length,
              itemBuilder: (context, index) {
                String skin = lojaSkins[index];
                bool comprada = skinsCompradas.contains(skin);
                bool selecionada = skinSelecionada == skin;

                return ListTile(
                  leading: Image.asset(
                    skin,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text('Skin Loja ${index + 1}'),
                  trailing: ElevatedButton(
                    onPressed: () => _comprarSkin(index),
                    child: Text(
                      selecionada
                          ? 'Equipado'
                          : comprada
                              ? 'Selecionar'
                              : 'Comprar (10 moedas)',
                    ),
                  ),
                );
              },
            ),

            Divider(),

            Text('Minhas Skins Personalizadas', style: TextStyle(fontSize: 20)),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: skinsPersonalizadas.length,
              itemBuilder: (context, index) {
                Uint8List imageBytes = base64Decode(skinsPersonalizadas[index]);
                bool selecionada = skinSelecionada == skinsPersonalizadas[index];

                return ListTile(
                  leading: Image.memory(
                    imageBytes,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text('Skin Personalizada ${index + 1}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deletarSkinPersonalizada(index),
                      ),
                      TextButton(
                        onPressed: () => _selecionarSkin(skinsPersonalizadas[index]),
                        child: Text(selecionada ? 'Equipado' : 'Selecionar'),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: _selecionarImagem,
              child: Text('Adicionar Nova Skin'),
            ),
          ],
        ),
      ),
    );
  }
}
