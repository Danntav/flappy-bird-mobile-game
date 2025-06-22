import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelaRanking extends StatefulWidget {
  @override
  _TelaRankingState createState() => _TelaRankingState();
}

class _TelaRankingState extends State<TelaRanking> {
  int recorde = 0;
  List<String> historicoScores = [];

  @override
  void initState() {
    super.initState();
    carregarRecordeEHistorico();
  }

  Future<void> carregarRecordeEHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recorde = prefs.getInt('recorde') ?? 0;
      historicoScores = prefs.getStringList('historicoScores') ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recorde: $recorde pontos',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Últimas 5 partidas:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            historicoScores.isEmpty
                ? const Text('Nenhum jogo registrado ainda.')
                : Expanded(
                    child: ListView.builder(
                      itemCount: historicoScores.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.star),
                          title: Text('Partida ${index + 1}: ${historicoScores[index]} pontos'),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

