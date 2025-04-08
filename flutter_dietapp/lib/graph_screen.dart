import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  List<FlSpot> weightSpots = [];
  List<FlSpot> bodyFatSpots = [];
  List<String> dates = [];
  double minY = 0;
  double maxY = 0;
  bool showWeight = true;
  bool showBodyFat = true;

  @override
  void initState() {
    super.initState();
    _loadGraphData();
  }

  Future<void> _loadGraphData() async {
    final dbHelper = DatabaseHelper();
    final data = await dbHelper.getGraphData();

    if (data.isEmpty) {
      setState(() {
        weightSpots = [];
        bodyFatSpots = [];
        dates = [];
      });
      return;
    }

    // データを日付でグループ化し、各日付の最新のデータのみを使用
    final dateMap = <String, Map<String, dynamic>>{};
    for (var record in data) {
      final date = record['date'] as String;
      // 同じ日付のデータが既にある場合は、IDが大きい（より新しい）データで上書き
      if (!dateMap.containsKey(date) || 
          (record['id'] as int) > (dateMap[date]!['id'] as int)) {
        dateMap[date] = record;
      }
    }

    // ソートされた日付のリストを作成
    final sortedDates = dateMap.keys.toList()..sort();
    final weightData = <FlSpot>[];
    final bodyFatData = <FlSpot>[];
    final datesList = <String>[];
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final record = dateMap[date]!;
      final weight = record['weight'] as double?;
      final bodyFat = record['body_fat'] as double?;

      if (weight != null || bodyFat != null) {
        datesList.add(date);

        if (weight != null) {
          weightData.add(FlSpot(i.toDouble(), weight));
          minValue = minValue < weight ? minValue : weight;
          maxValue = maxValue > weight ? maxValue : weight;
        }

        if (bodyFat != null) {
          bodyFatData.add(FlSpot(i.toDouble(), bodyFat));
          minValue = minValue < bodyFat ? minValue : bodyFat;
          maxValue = maxValue > bodyFat ? maxValue : bodyFat;
        }
      }
    }

    setState(() {
      weightSpots = weightData;
      bodyFatSpots = bodyFatData;
      dates = datesList;
      minY = minValue;
      maxY = maxValue;
    });
  }

  String _getDateLabel(int index) {
    if (index >= 0 && index < dates.length) {
      try {
        final dateStr = dates[index];
        final date = DateFormat('yyyy/MM/dd').parse(dateStr);
        return DateFormat('MM/dd').format(date);
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final interval = dates.isEmpty ? 1.0 : 
                    (dates.length <= 5 ? 1.0 : (dates.length / 5).ceil().toDouble());

    return Scaffold(
      appBar: AppBar(
        title: const Text('グラフ画面'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('体重'),
                  selected: showWeight,
                  onSelected: (bool value) {
                    setState(() {
                      showWeight = value;
                    });
                  },
                ),
                const SizedBox(width: 16),
                FilterChip(
                  label: const Text('体脂肪率'),
                  selected: showBodyFat,
                  onSelected: (bool value) {
                    setState(() {
                      showBodyFat = value;
                    });
                  },
                ),
              ],
            ),
          ),
          if (dates.isEmpty)
            const Expanded(
              child: Center(
                child: Text('データがありません'),
              ),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      if (showWeight)
                        LineChartBarData(
                          spots: weightSpots,
                          isCurved: false,
                          color: Colors.blue,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: Colors.blue,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              ),
                          ),
                          barWidth: 2,
                        ),
                      if (showBodyFat)
                        LineChartBarData(
                          spots: bodyFatSpots,
                          isCurved: false,
                          color: Colors.red,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: Colors.red,
                                strokeWidth: 1,
                                strokeColor: Colors.white,
                              ),
                          ),
                          barWidth: 2,
                        ),
                    ],
                    minY: minY * 0.95,
                    maxY: maxY * 1.05,
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 45,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text(
                            '日付',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: interval,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < dates.length) {
                              return Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  _getDateLabel(index),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: (maxY - minY) / 10,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.5),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot spot) {
                            final isWeight = spot.barIndex == 0;
                            return LineTooltipItem(
                              '${_getDateLabel(spot.x.toInt())}\n${isWeight ? "体重" : "体脂肪率"}: ${spot.y.toStringAsFixed(1)}${isWeight ? "kg" : "%"}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
