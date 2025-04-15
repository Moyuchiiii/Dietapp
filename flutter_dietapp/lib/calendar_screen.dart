// カレンダー形式で日々の記録やスタンプを可視化し、詳細表示や入力画面への遷移を行う画面のウィジェット。

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_helper.dart';
import 'input_screen.dart';

// カレンダーで日々の記録を可視化する画面
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // 日付ごとの体重データ
  Map<String, String> _weightData = {};
  // 日付ごとのスタンプデータ
  Map<String, String> _stampData = {};
  double? _userHeight;

  @override
  void initState() {
    super.initState();
    // 体重データとユーザー身長を初期化時に取得
    _loadWeightData();
    _loadUserHeight();
  }

  // データベースから体重・スタンプデータを取得
  Future<void> _loadWeightData() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final records = await db.query('daily_records');
    setState(() {
      _weightData = {
        for (var record in records)
          record['date'] as String: record['weight'].toString()
      };
      _stampData = {
        for (var record in records)
          record['date'] as String: record['stamp']?.toString() ?? ''
      };
    });
  }

  // ユーザーの身長を取得（BMI計算用）
  Future<void> _loadUserHeight() async {
    final dbHelper = DatabaseHelper();
    final userData = await dbHelper.getUserData();
    if (userData != null) {
      setState(() {
        _userHeight = userData['height'] as double;
      });
    }
  }

  // 指定日付の入力画面を開く（長押し時）
  void _openInputScreenForDate(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InputScreen(),
        settings: RouteSettings(arguments: date),
      ),
    );
  }

  // 日付タップ時に詳細情報を表示
  void _showDayDetail(DateTime date) {
    final formattedDate = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final weight = _weightData[formattedDate];
    if (weight != null) {
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: DatabaseHelper().getDailyRecordByDate(formattedDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final record = snapshot.data;
              final bodyFatStr = record != null && record['body_fat'] != null ? record['body_fat'].toString() : '0';
              final memo = record != null && record['memo'] != null ? record['memo'].toString() : '';
              final bodyFat = double.tryParse(bodyFatStr) ?? 0;
              final weightValue = double.tryParse(weight) ?? 0;
              // BMI計算
              final bmi = _userHeight != null
                  ? weightValue / ((_userHeight! / 100) * (_userHeight! / 100))
                  : 0;
              return Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${date.year}年${date.month}月${date.day}日の記録',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailItem('体重', '$weight kg'),
                        _buildDetailItem('体脂肪率', '$bodyFat %'),
                        _buildDetailItem('BMI', bmi.toStringAsFixed(1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('メモ: $memo', style: Theme.of(context).textTheme.bodyLarge),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  // 詳細表示用のウィジェット
  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 24)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TableCalendarでカレンダーUIを構築
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー画面'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                rowHeight: 80.0,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  // 日付タップ時に詳細表示
                  _showDayDetail(selectedDay);
                },
                onDayLongPressed: (selectedDay, focusedDay) {
                  // 長押しで入力画面へ
                  _openInputScreenForDate(selectedDay);
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextFormatter: (date, locale) =>
                      '${date.year}年${date.month}月',
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekendStyle: const TextStyle(color: Colors.red),
                  weekdayStyle: const TextStyle(color: Colors.black),
                  dowTextFormatter: (date, locale) {
                    const days = ['日', '月', '火', '水', '木', '金', '土'];
                    return days[date.weekday % 7];
                  },
                ),
                calendarStyle: CalendarStyle(
                  cellMargin: EdgeInsets.zero,
                  defaultDecoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.lightBlueAccent.withAlpha(128),
                    border: Border.all(color: Colors.blue, width: 1.0),
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withAlpha(128),
                    border: Border.all(color: Colors.deepPurple, width: 1.0),
                  ),
                  outsideDecoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 0.5),
                  ),
                  defaultTextStyle:
                      const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                // 日付セルのカスタマイズ
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    final formattedDate =
                        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                    final weight = _weightData[formattedDate];
                    final stamp = _stampData[formattedDate];
                    return Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(day.day.toString(), style: const TextStyle(fontSize: 16)),
                          if (stamp != null) Text(stamp, style: const TextStyle(fontSize: 16)),
                          if (weight != null)
                            Text(
                              '$weight kg',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                            ),
                        ],
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    final formattedDate =
                        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                    final weight = _weightData[formattedDate];
                    final stamp = _stampData[formattedDate];
                    return Container(
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 0.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            day.day.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (stamp != null) Text(stamp, style: const TextStyle(fontSize: 16)),
                          if (weight != null)
                            Text(
                              '$weight kg',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                            ),
                        ],
                      ),
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final formattedDate =
                        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                    final weight = _weightData[formattedDate];
                    final stamp = _stampData[formattedDate];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withAlpha(128),
                        border: Border.all(color: Colors.deepPurple, width: 1.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            day.day.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          if (stamp != null) Text(stamp, style: const TextStyle(fontSize: 16)),
                          if (weight != null)
                            Text(
                              '$weight kg',
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
