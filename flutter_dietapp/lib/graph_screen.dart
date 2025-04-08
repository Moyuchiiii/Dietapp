import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';

class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  Future<List<FlSpot>> _fetchWeightData() async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final result = await db.query(
      'daily_records',
      columns: ['date', 'weight'],
      orderBy: 'date ASC',
    );

    return result.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final weight = entry.value['weight'] as double;
      return FlSpot(index, weight);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('グラフ'),
      ),
      body: FutureBuilder<List<FlSpot>>(
        future: _fetchWeightData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          final spots = snapshot.data!;

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  '体重推移',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          gradient: LinearGradient(colors: [Colors.blue, Colors.lightBlueAccent]),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement 1-week graph logic
                    },
                    child: const Text('1週間'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement 1-month graph logic
                    },
                    child: const Text('1カ月'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement 3-month graph logic
                    },
                    child: const Text('3カ月'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement 1-year graph logic
                    },
                    child: const Text('1年'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement 3-year graph logic
                    },
                    child: const Text('3年'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
