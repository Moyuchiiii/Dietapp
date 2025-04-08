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

    debugPrint('Database records: $records');

    setState(() {
      _weightData = {
        for (var record in records)
          record['date'] as String: record['weight'].toString()
      };
    });

    debugPrint('Loaded weight data: $_weightData');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー画面'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final calendarHeight = constraints.maxHeight * 0.8;
          return Column(
            children: [
              SizedBox(
                height: calendarHeight,
                child: TableCalendar(
                  firstDay: DateTime(2000),
                  lastDay: DateTime(2100),
                  focusedDay: _focusedDay,
                  calendarFormat: CalendarFormat.month,
                  rowHeight: calendarHeight / 7,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  // 枠線を細く見せたい場合は cellMargin を小さめにするか zero にする
                  calendarStyle: CalendarStyle(
                    cellMargin: const EdgeInsets.all(2.0),
                    defaultDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.lightBlueAccent.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    defaultTextStyle:
                        const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  calendarBuilders: CalendarBuilders(
                    // 通常日
                    defaultBuilder: (context, day, focusedDay) {
                      final formattedDate =
                          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                      final weight = _weightData[formattedDate];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(
                          vertical: 2.0,
                          horizontal: 2.0,
                        ),
                        decoration: BoxDecoration(
                          // 枠線を細くする場合は width を小さめにする
                          border: Border.all(color: Colors.green[600]!, width: 0.5),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(day.day.toString(), style: const TextStyle(fontSize: 16)),
                            if (weight != null)
                              Text(
                                '$weight kg',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      );
                    },
                    // 今日
                    todayBuilder: (context, day, focusedDay) {
                      final formattedDate =
                          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                      final weight = _weightData[formattedDate];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(
                          vertical: 2.0,
                          horizontal: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withOpacity(0.5),
                          // 枠線を細くする場合は width を小さめにする
                          border: Border.all(color: Colors.green[600]!, width: 0.5),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              day.day.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            if (weight != null)
                              Text(
                                '$weight kg',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      );
                    },
                    // 選択日
                    selectedBuilder: (context, day, focusedDay) {
                      final formattedDate =
                          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                      final weight = _weightData[formattedDate];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.symmetric(
                          vertical: 2.0,
                          horizontal: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withOpacity(0.5),
                          // 選択日の枠線も細めにする (1.0 など)
                          border: Border.all(color: Colors.red[800]!, width: 1.0),
                          borderRadius: BorderRadius.circular(6.0),
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
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _selectedDay != null
                        ? '選択した日の体重: ${_weightData['${_selectedDay!.year.toString().padLeft(4, '0')}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}'] ?? 'データなし'} kg'
                        : '日付を選択してください',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
