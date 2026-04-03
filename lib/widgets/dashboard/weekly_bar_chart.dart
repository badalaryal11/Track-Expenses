import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeeklyBarChart extends StatelessWidget {
  final Map<int, double> dailySpending;

  const WeeklyBarChart({super.key, required this.dailySpending});

  @override
  Widget build(BuildContext context) {
    if (dailySpending.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxY = dailySpending.values.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) return const SizedBox.shrink();

    // Give some top padding
    maxY = maxY + (maxY * 0.2);

    List<BarChartGroupData> barGroups = [];
    final sortedKeys = dailySpending.keys.toList()..sort();
    
    for (var day in sortedKeys) {
      final amount = dailySpending[day]!;
      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: amount,
              color: Theme.of(context).colorScheme.primary,
              width: 14,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Weekly Spending Tracker',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return BarTooltipItem(
                          '${days[group.x - 1]}\n${rod.toY.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          int index = value.toInt() - 1;
                          if (index >= 0 && index < 7) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                days[index],
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false), 
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                    drawVerticalLine: false,
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
