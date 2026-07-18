// lib/features/dashboard/presentation/widgets/stock_chart.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/dashboard_providers.dart';

class StockChart extends ConsumerStatefulWidget {
  const StockChart({Key? key}) : super(key: key);

  @override
  ConsumerState<StockChart> createState() => _StockChartState();
}

class _StockChartState extends ConsumerState<StockChart> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final chartData = ref.watch(stockChartDataProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Stock Balance by Product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ToggleButtons(
                  isSelected: [
                    _selectedIndex == 0,
                    _selectedIndex == 1,
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Bar'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Pie'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (chartData.isNotEmpty)
              SizedBox(
                height: 300,
                child: _selectedIndex == 0
                    ? _buildBarChart(chartData)
                    : _buildPieChart(chartData),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No data available'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<ChartData> data) {
    final maxValue = data.fold<double>(
      0.0,
      (max, d) => d.value > max ? d.value : max,
    );

    return BarChart(
      BarChartData(
        maxY: maxValue * 1.2,
        minY: 0,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return SizedBox(
                    width: 40,
                    child: Text(
                      data[index].label,
                      style: const TextStyle(fontSize: 9),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: entry.value.color,
                width: 20,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart(List<ChartData> data) {
    return PieChart(
      PieChartData(
        sections: data.asMap().entries.map((entry) {
          return PieChartSectionData(
            color: entry.value.color,
            value: entry.value.value,
            title: entry.value.value > 0
                ? '${(entry.value.value / data.fold<double>(0, (sum, d) => sum + d.value) * 100).toStringAsFixed(0)}%'
                : '',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: -90,
      ),
    );
  }
}