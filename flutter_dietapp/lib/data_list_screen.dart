import 'package:flutter/material.dart';
import 'database_helper.dart';

class DataListScreen extends StatefulWidget {
  const DataListScreen({super.key});

  @override
  State<DataListScreen> createState() => _DataListScreenState();
}

class _DataListScreenState extends State<DataListScreen> {
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final result = await db.query(
      'daily_records_log',
      orderBy: 'updated_at DESC', // 更新日時の降順に並び替え
    );
    setState(() {
      _logs = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final dbHelper = DatabaseHelper();
              final db = await dbHelper.database;

              // 確認ダイアログを表示
              final confirm = await showDialog<bool>(
                // ignore: use_build_context_synchronously
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
                // ログを削除
                await db.delete('daily_records_log');

                if (!mounted) return;

                // ログリストをクリアして画面を更新
                setState(() {
                  _logs.clear();
                });

                if (!mounted) return;

                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('すべてのログが削除されました')),
                );

                if (!mounted) return;

                // オプション画面に戻る
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
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
