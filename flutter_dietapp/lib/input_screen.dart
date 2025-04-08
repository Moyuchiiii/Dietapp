import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用のパッケージをインポート
import 'database_helper.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _recordId; // 既存データのIDを保持

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecordForDate(_selectedDate); // 初期表示時にデータを読み込む
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecordForDate(_selectedDate); // 再表示時にデータを読み込む
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadRecordForDate(_selectedDate); // 日付変更時にデータを読み込む
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadRecordForDate(_selectedDate); // 選択した日付のデータを読み込む
    }
  }

  Future<void> _loadRecordForDate(DateTime date) async {
    final dbHelper = DatabaseHelper();
    final formattedDate = DateFormat('yyyy-MM-dd').format(date); // 日付をフォーマット
    final records = await dbHelper.getDailyRecordByDate(formattedDate); // フォーマット済みの日付を使用
    if (records != null) {
      if (!mounted) return;
      setState(() {
        _recordId = records['id']; // 記録IDを保持
        _weightController.text = records['weight'].toString(); // 体重を入力
        _bodyFatController.text = records['body_fat'].toString(); // 体脂肪率を入力
        _memoController.text = records['memo'] ?? ''; // メモを入力
      });
    } else {
      if (!mounted) return;
      setState(() {
        _recordId = null; // 記録IDをリセット
        _weightController.clear(); // 体重フィールドをクリア
        _bodyFatController.clear(); // 体脂肪率フィールドをクリア
        _memoController.clear(); // メモフィールドをクリア
      });
    }
  }

  Future<void> _saveRecord() async {
    final weight = double.tryParse(_weightController.text);
    final bodyFat = double.tryParse(_bodyFatController.text);
    final memo = _memoController.text;

    if (weight != null && bodyFat != null) {
      try {
        final dbHelper = DatabaseHelper();
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate); // 日付をフォーマット
        final data = {
          'weight': weight,
          'body_fat': bodyFat,
          'memo': memo,
          'date': formattedDate, // フォーマット済みの日付を使用
        };

        if (_recordId == null) {
          // 新規挿入
          await dbHelper.insertDailyRecord(data);
        } else {
          // 更新
          await dbHelper.updateDailyRecord(_recordId!, data);
          // logDailyRecordUpdate は updateDailyRecord 内で呼び出されるため、ここで再度呼び出さない
        }

        if (!mounted) return; // mounted チェックを追加

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('記録が保存されました')),
        );

        _loadRecordForDate(_selectedDate);
      } catch (e) {
        if (!mounted) return; // mounted チェックを追加

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } else {
      if (!mounted) return; // mounted チェックを追加

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('体重と体脂肪率を正しく入力してください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('記録確認'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('日付', style: TextStyle(fontSize: 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                GestureDetector(
                  onTap: _selectDate, // タップでカレンダーを開く
                  child: Text(
                    '${_selectedDate.year} ${_selectedDate.month}.${_selectedDate.day} (${['月', '火', '水', '木', '金', '土', '日'][_selectedDate.weekday - 1]})',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeDate(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('体重 (kg)', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: 60.5',
              ),
            ),
            const SizedBox(height: 16),
            const Text('体脂肪率 (%)', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _bodyFatController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: 20.5',
              ),
            ),
            const SizedBox(height: 16),
            const Text('メモ', style: TextStyle(fontSize: 16)),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例: 運動内容や食事内容など',
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _saveRecord,
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
