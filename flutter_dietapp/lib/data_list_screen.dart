// 日々の記録の変更履歴（ログ）を一覧表示・削除できる画面のウィジェット。

import 'package:flutter/material.dart';
import 'database_helper.dart';

// データベースのログ一覧を表示する画面
class DataListScreen extends StatefulWidget {
  const DataListScreen({super.key});

  @override
  State<DataListScreen> createState() => _DataListScreenState();
}

class _DataListScreenState extends State<DataListScreen> {
  // ログデータを格納するリスト
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    // 画面初期化時にログを読み込む
    _loadLogs();
  }

  // データベースからログを取得して_stateにセット
  Future<void> _loadLogs() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final result = await db.query(
      'daily_records_log',
      orderBy: 'updated_at DESC',
    );
    setState(() {
      _logs = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffoldで画面全体を構成
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログ'),
        actions: [
          // ログ全削除ボタン
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final dbHelper = DatabaseHelper();
              final db = await dbHelper.database;
              // 削除確認ダイアログを表示
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('確認'),
                  content: const Text('すべてのログを削除しますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('削除'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                // ログテーブルを全削除
                await db.delete('daily_records_log');
                if (!mounted) return;
                setState(() {
                  _logs.clear();
                });
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('すべてのログが削除されました')),
                );
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      // ログ一覧をListViewで表示
      body: ListView.builder(
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          return ListTile(
            title: Text('変更日: ${log['updated_at']}'),
            subtitle: Text(
              '変更した日: ${log['date']}\n'
              '体重: ${log['weight']}kg 体脂肪率: ${log['body_fat']}%\n'
              'スタンプ: ${log['stamp'] ?? 'なし'}\n'
              'メモ: ${log['memo']}',
            ),
          );
        },
      ),
    );
  }
}
