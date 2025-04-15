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
  final TextEditingController _targetWeightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData(); // 追加: 既存のユーザーデータを読み込む
  }

  Future<void> _loadUserData() async {
    final dbHelper = DatabaseHelper();
    final userData = await dbHelper.getUserData();
    if (userData != null) {
      setState(() {
        _usernameController.text = userData['username'] ?? '';
        _heightController.text = userData['height'] != null
            ? userData['height'].toString()
            : '';
        _targetWeightController.text = userData['target_weight'] != null
            ? userData['target_weight'].toString()
            : '';
      });
    }
  }

  Future<void> _saveData() async {
    final username = _usernameController.text;
    final height = double.tryParse(_heightController.text);
    final targetWeight = double.tryParse(_targetWeightController.text);

    if (username.isNotEmpty && height != null && targetWeight != null) {
      try {
        final dbHelper = DatabaseHelper();
        final db = await dbHelper.database;
        // 既存のユーザーデータを削除
        await db.delete('user_data');
        await dbHelper.insertUserData({
          'username': username,
          'height': height,
          'target_weight': targetWeight,
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('データが保存されました')),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべてのフィールドを正しく入力してください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基本設定'),
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