import 'package:flutter/material.dart';

class TelaTutorial extends StatelessWidget {
  const TelaTutorial({super.key});

  Widget _itemTutorial(IconData icon, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _itemTutorial(Icons.clear, 'Desvie dos canos para não perder o jogo.'),
            _itemTutorial(Icons.star, 'Colete moedas passando pelos canos.'),
            _itemTutorial(Icons.style, 'Compre e equipe skins na loja para mudar o visual do pássaro.'),
            _itemTutorial(Icons.info, 'O jogo fica mais difícil com o tempo, fique atento!'),
            const SizedBox(height: 20),
            const Text(
              'Toque na tela para dar um pulo e começar o jogo.',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
