// 体重・体脂肪率の推移をグラフで表示する画面のウィジェット。
// データベースから取得した記録を折れ線グラフで可視化します。

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'dart:math';

// グラフ画面（体重・体脂肪率の推移を表示）
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
  double minX = 0;
  double maxX = 0;
  bool showWeight = true;
  bool showBodyFat = true;
  double? targetWeight;

  @override
  void initState() {
    super.initState();
    // グラフ用データを読み込む
    _loadGraphData();
  }

  // データベースからグラフ用データを取得
  Future<void> _loadGraphData() async {
    final dbHelper = DatabaseHelper();
    final data = await dbHelper.getGraphData();
    final userData = await dbHelper.getUserData();
    final target = userData != null ? userData['target_weight'] as double? : null;

    if (data.isEmpty) {
      setState(() {
        weightSpots = [];
        bodyFatSpots = [];
        dates = [];
        targetWeight = target;
      });
      return;
    }

    final dateMap = <String, Map<String, dynamic>>{};
    for (var record in data) {
      final date = record['date'] as String;
      if (!dateMap.containsKey(date) ||
          (record['id'] as int) > (dateMap[date]!['id'] as int)) {
        dateMap[date] = record;
      }
    }

    final sortedDates = dateMap.keys.toList()..sort();
    final firstDate = DateFormat('yyyy/MM/dd').parse(sortedDates.first);
    final lastDate = DateFormat('yyyy/MM/dd').parse(sortedDates.last);

    final allDates = List.generate(
      lastDate.difference(firstDate).inDays + 1,
      (index) => DateFormat('yyyy/MM/dd').format(
        firstDate.add(Duration(days: index)),
      ),
    );

    final weightData = <FlSpot>[];
    final bodyFatData = <FlSpot>[];
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;

    for (int i = 0; i < allDates.length; i++) {
      final date = allDates[i];
      final record = dateMap[date];
      if (record != null) {
        final weight = record['weight'] as double?;
        final bodyFat = record['body_fat'] as double?;
        if (weight != null) {
          weightData.add(FlSpot(i.toDouble(), weight));
          minValue = min(minValue, weight);
          maxValue = max(maxValue, weight);
        }
        if (bodyFat != null) {
          bodyFatData.add(FlSpot(i.toDouble(), bodyFat));
          minValue = min(minValue, bodyFat);
          maxValue = max(maxValue, bodyFat);
        }
      }
    }

    if (target != null) {
      minValue = min(minValue, target);
      maxValue = max(maxValue, target);
    }

    setState(() {
      weightSpots = weightData;
      bodyFatSpots = bodyFatData;
      dates = allDates;
      minY = minValue;
      maxY = maxValue;
      minX = 0;
      maxX = (dates.length - 1).toDouble();
      targetWeight = target;
    });
  }

  // X軸の日付ラベルを取得
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
    const interval = 1.0;

    // グラフUI
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
          if (targetWeight != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '目標体重: ${targetWeight!.toStringAsFixed(1)} kg',
                style: const TextStyle(fontSize: 14, color: Colors.green),
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
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: max(MediaQuery.of(context).size.width, dates.length * 65.0),
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
                          if (targetWeight != null)
                            LineChartBarData(
                              spots: [FlSpot(minX, targetWeight!), FlSpot(maxX, targetWeight!)],
                              isCurved: false,
                              color: Colors.grey.withOpacity(0.5),
                              dotData: FlDotData(show: false),
                              dashArray: [5, 5],
                              barWidth: 1,
                            ),
                        ],
                        minX: minX,
                        maxX: maxX,
                        minY: minY * 0.95,
                        maxY: maxY * 1.05,
                        clipData: FlClipData.none(),
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
                              padding: EdgeInsets.only(top: 45),
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
                              reservedSize: 90,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < dates.length) {
                                  return Container(
                                    padding: const EdgeInsets.only(top: 8.0),
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
                              color: Color.fromRGBO(128, 128, 128, 0.3),
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Color.fromRGBO(128, 128, 128, 0.3),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Color.fromRGBO(128, 128, 128, 0.5),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Color.fromRGBO(96, 125, 139, 0.8),
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
              ),
            ),
        ],
      ),
    );
  }
}
