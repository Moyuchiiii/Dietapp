// オプション画面（ログ確認・全データ削除・基本設定変更）を提供するウィジェット。
// ユーザーはここからログの閲覧、全データ削除、基本設定の変更が可能です。

import 'package:flutter/material.dart';
import 'data_list_screen.dart';
import 'database_helper.dart';
import 'firt.dart';

// オプション画面（ログ確認・全データ削除・基本設定変更）
class OptionsScreen extends StatelessWidget {
  const OptionsScreen({super.key});

  // すべてのデータを削除する処理
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
      // 各テーブルを全削除
      await db.delete('user_data');
      await db.delete('daily_records');
      await db.delete('daily_records_log');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('すべてのデータを削除しました'),
          ),
        );
        // 初期設定画面へ遷移
        if (await dbHelper.hasUserData() == false) {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const InitialSetupScreen()),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // オプション項目のリスト表示
    return Scaffold(
      appBar: AppBar(
        title: const Text('オプション画面'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('ログを確認する'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DataListScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('すべてのデータを削除', style: TextStyle(color: Colors.red)),
            onTap: () => _deleteAllData(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_applications),
            title: const Text('基本設定の変更'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InitialSetupScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
