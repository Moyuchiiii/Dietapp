import 'package:flutter/material.dart';
import 'data_list_screen.dart';
import 'database_helper.dart';

class OptionsScreen extends StatelessWidget {
  const OptionsScreen({super.key});

  Future<void> _deleteAllData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('警告'),
        content: const Text('すべてのデータを削除します。この操作は取り消せません。\n本当によろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      
      // すべてのテーブルのデータを削除
      await db.delete('user_data');
      await db.delete('daily_records');
      await db.delete('daily_records_log');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('すべてのデータを削除しました'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('オプション画面'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DataListScreen()),
                );
              },
              child: const Text('ログを確認する'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _deleteAllData(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('すべてのデータを削除'),
            ),
          ],
        ),
      ),
    );
  }
}
