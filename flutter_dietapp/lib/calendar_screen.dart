import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_helper.dart';
import 'input_screen.dart'; // 記録画面をインポート

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, String> _weightData = {};
  Map<String, String> _stampData = {}; // スタンプデータを保持するマップ

  @override
  void initState() {
    super.initState();
    _loadWeightData(); // スタンプデータは_loadWeightDataで一緒に取得するため_loadStampData()は削除
  }

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

  void _openInputScreenForDate(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InputScreen(),
        settings: RouteSettings(arguments: date), // 日付を渡す
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー画面'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              rowHeight: 90.0,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onDayLongPressed: (selectedDay, focusedDay) {
                _openInputScreenForDate(selectedDay); // 長押しで記録画面を開く
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
                  color: Colors.lightBlueAccent.withOpacity(0.5),
                  border: Border.all(color: Colors.blue, width: 1.0),
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.deepPurpleAccent.withOpacity(0.5),
                  border: Border.all(color: Colors.deepPurple, width: 1.0),
                ),
                outsideDecoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 0.5),
                ),
                defaultTextStyle:
                    const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final formattedDate =
                      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final weight = _weightData[formattedDate];
                  final stamp = _stampData[formattedDate]; // スタンプデータを取得
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
                        if (stamp != null) Text(stamp, style: const TextStyle(fontSize: 16)), // スタンプを表示
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
                  final stamp = _stampData[formattedDate]; // スタンプデータを取得
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
                        if (stamp != null) Text(stamp, style: const TextStyle(fontSize: 16)), // スタンプを表示
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
                  final stamp = _stampData[formattedDate]; // スタンプデータを取得
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.5),
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
                        if (stamp != null) Text(stamp, style: const TextStyle(fontSize: 16)), // スタンプを表示
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _selectedDay != null
                    ? '選択した日の体重: ${_weightData['${_selectedDay!.year.toString().padLeft(4, '0')}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}'] ?? 'データなし'} kg'
                    : '日付を選択してください',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
