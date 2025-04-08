import 'package:flutter/material.dart';
import 'data_list_screen.dart'; // データリスト画面をインポート

class OptionsScreen extends StatelessWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('オプション画面'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DataListScreen()),
            );
          },
          child: const Text('ログを確認する'),
        ),
      ),
    );
  }
}
