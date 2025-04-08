import 'package:flutter/material.dart';

class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('グラフ画面'),
      ),
      body: const Center(
        child: Text(
          'ここにグラフを表示します。',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
