// 日々の体重・体脂肪率・メモ・スタンプを入力・保存する画面のウィジェット。
// 日付ごとに記録の新規作成・編集が可能です。

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

// 日々の記録入力画面
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
  int? _recordId;
  final List<String> _stamps = ['😊', '😢', '🍚', '🍺', '🚻', '🏃', '⭐'];
  String? _selectedStamp;

  @override
  void initState() {
    super.initState();
    // 初期表示時に当日の記録を読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecordForDate(_selectedDate);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRecordForDate(_selectedDate);
  }

  // 日付を変更
  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadRecordForDate(_selectedDate);
  }

  // 日付選択ダイアログ
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
      _loadRecordForDate(_selectedDate);
    }
  }

  // 指定日の記録を読み込む
  Future<void> _loadRecordForDate(DateTime date) async {
    final dbHelper = DatabaseHelper();
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final records = await dbHelper.getDailyRecordByDate(formattedDate);
    if (records != null) {
      if (!mounted) return;
      setState(() {
        _recordId = records['id'];
        _weightController.text = records['weight'].toString();
        _bodyFatController.text = records['body_fat'].toString();
        _memoController.text = records['memo'] ?? '';
        _selectedStamp = records['stamp'];
      });
    } else {
      if (!mounted) return;
      setState(() {
        _recordId = null;
        _weightController.clear();
        _bodyFatController.clear();
        _memoController.clear();
        _selectedStamp = null;
      });
    }
  }

  // 記録を保存
  Future<void> _saveRecord() async {
    final weight = double.tryParse(_weightController.text);
    final bodyFat = double.tryParse(_bodyFatController.text);
    final memo = _memoController.text;

    if (weight != null && bodyFat != null) {
      try {
        final dbHelper = DatabaseHelper();
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
        final data = {
          'weight': weight,
          'body_fat': bodyFat,
          'memo': memo,
          'date': formattedDate,
          'stamp': _selectedStamp,
        };

        if (_recordId == null) {
          await dbHelper.insertDailyRecord(data);
        } else {
          await dbHelper.updateDailyRecord(_recordId!, data);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('記録が保存されました')),
        );
        _loadRecordForDate(_selectedDate);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('体重と体脂肪率を正しく入力してください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 入力フォームUI
    return Scaffold(
      appBar: AppBar(
        title: const Text('記録入力'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _changeDate(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  GestureDetector(
                    onTap: _selectDate,
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
              const Text('スタンプを選択:', style: TextStyle(fontSize: 16)),
              Wrap(
                spacing: 8.0,
                children: _stamps.map((stamp) {
                  return ChoiceChip(
                    label: Text(stamp),
                    selected: _selectedStamp == stamp,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStamp = selected ? stamp : null;
                      });
                    },
                  );
                }).toList(),
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
      ),
    );
  }
}
