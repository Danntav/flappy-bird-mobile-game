import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {
  double volumeMusica = 0.5; // valor padrão 50%

  @override
  void initState() {
    super.initState();
    carregarVolume();
  }

  Future<void> carregarVolume() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      volumeMusica = prefs.getDouble('volumeMusica') ?? 0.5;
    });
  }

  Future<void> salvarVolume(double novoVolume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volumeMusica', novoVolume);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Volume da Música',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: volumeMusica,
              min: 0,
              max: 1,
              divisions: 10,
              label: '${(volumeMusica * 100).round()}%',
              onChanged: (double value) {
                setState(() {
                  volumeMusica = value;
                });
                salvarVolume(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
