import 'package:flutter/material.dart';
import 'database_helper.dart'; // データベースヘルパーをインポート
import 'home.dart'; // ホーム画面をインポート

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _currentWeightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();

  Future<void> _saveData() async {
    final username = _usernameController.text;
    final height = double.tryParse(_heightController.text);
    final currentWeight = double.tryParse(_currentWeightController.text);
    final targetWeight = double.tryParse(_targetWeightController.text);

    if (username.isNotEmpty && height != null && currentWeight != null && targetWeight != null) {
      try {
        // データをローカルデータベースに保存
        final dbHelper = DatabaseHelper();
        await dbHelper.insertUserData({
          'username': username,
          'height': height,
          'current_weight': currentWeight,
          'target_weight': targetWeight,
        });

        if (!mounted) return; // mounted チェックを追加

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('データが保存されました')),
        );

        if (!mounted) return; // mounted チェックを追加

        // ホーム画面に遷移
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } catch (e) {
        if (!mounted) return; // mounted チェックを追加

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } else {
      if (!mounted) return; // mounted チェックを追加

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべてのフィールドを正しく入力してください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('初期設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ユーザー名', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: 山田太郎',
              ),
            ),
            const SizedBox(height: 16),
            const Text('身長 (cm)', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: 170',
              ),
            ),
            const SizedBox(height: 16),
            const Text('現在の体重 (kg)', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _currentWeightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: 60',
              ),
            ),
            const SizedBox(height: 16),
            const Text('目標体重 (kg)', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _targetWeightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: 55',
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _saveData,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}