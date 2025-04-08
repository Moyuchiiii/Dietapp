import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database_helper.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, String> _weightData = {};

  @override
  void initState() {
    super.initState();
    _loadWeightData();
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
    });
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
                  return Container(
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 0.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(day.day.toString(), style: const TextStyle(fontSize: 16)),
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
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.5),
                      border: Border.all(color: Colors.deepPurple, width: 1.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          day.day.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
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
