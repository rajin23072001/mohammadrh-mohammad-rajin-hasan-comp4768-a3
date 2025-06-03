import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

/* ---------- colour palette ---------- */
const _palette = [
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  Colors.red,
  Colors.cyan,
  Colors.pink,
  Colors.teal,
  Colors.amber,
  Colors.indigo,
];

class ChartsScreen extends ConsumerWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider);

    /* ---------- aggregate ---------- */
    final Map<String, double> byCategory = {};
    final Map<DateTime, double> byDay = {};
    for (final e in expenses) {
      byCategory.update(e.category, (v) => v + e.amount,
          ifAbsent: () => e.amount);
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      byDay.update(d, (v) => v + e.amount, ifAbsent: () => e.amount);
    }

    if (expenses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Expense Charts')),
        body: const Center(child: Text('No data yet')),
      );
    }

    /* ---------- colours ---------- */
    final categories = byCategory.keys.toList()..sort();
    final colourOf = {
      for (var i = 0; i < categories.length; i++)
        categories[i]: _palette[i % _palette.length],
    };

    /* ---------- PIE (percent labels) ---------- */
    final total = byCategory.values.fold<double>(0, (a, b) => a + b);

    double _offsetFor(double share) {
      // center the label for single-slice pies; otherwise use default
      if (share == 1) return .5;
      if (share < .08) return .88; // tiny slice, push outwards
      if (share > .55) return .6;  // big slice, pull inwards
      return .75;                  // normal slice
    }

    String _percentText(double share) =>
        '${share * 100 % 1 == 0 ? share * 100 ~/ 1 : (share * 100).toStringAsFixed(1)}%';

    final pieSections = categories.map((c) {
      final value = byCategory[c]!;
      final share = value / total;
      return PieChartSectionData(
        value: value,
        color: colourOf[c],
        radius: 70,
        title: _percentText(share),
        titleStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: _offsetFor(share),
      );
    }).toList();

    /* ---------- legend below pie ---------- */
    Widget buildLegend() => Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: categories
              .map(
                (c) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colourOf[c],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(c, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )
              .toList(),
        );

    /* ---------- BAR ---------- */
    final barGroups = List.generate(categories.length, (i) {
      final c = categories[i];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: byCategory[c]!,
            width: 22,
            color: colourOf[c],
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    Widget barBottom(double v, TitleMeta _) {
      final i = v.toInt();
      if (i < 0 || i >= categories.length) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(categories[i], style: const TextStyle(fontSize: 10)),
      );
    }

    final maxBar =
        byCategory.values.fold<double>(0, (p, e) => e > p ? e : p);

    /* ---------- LINE ---------- */
    final sortedDays = byDay.keys.toList()..sort();
    final lineSpots = [
      for (var i = 0; i < sortedDays.length; i++)
        FlSpot(i.toDouble(), byDay[sortedDays[i]]!)
    ];

    Widget lineBottom(double v, TitleMeta _) {
      if (v % 1 != 0) return const SizedBox.shrink();
      final i = v.toInt();
      if (i < 0 || i >= sortedDays.length) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(DateFormat.Md().format(sortedDays[i]),
            style: const TextStyle(fontSize: 10)),
      );
    }

    final maxLine =
        byDay.values.fold<double>(0, (p, e) => e > p ? e : p) * 1.2;

    /* ---------- UI ---------- */
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expense Charts'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pie_chart), text: 'Pie'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Bar'),
              Tab(icon: Icon(Icons.show_chart), text: 'Line'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            /* ----- PIE ----- */
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 240,
                    width: 240,
                    child: PieChart(
                      PieChartData(
                        sections: pieSections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  buildLegend(),
                ],
              ),
            ),

            /* ----- BAR ----- */
            Padding(
              padding: const EdgeInsets.all(16),
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxBar == 0 ? 1 : maxBar * 1.2,
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: maxBar / 4,
                        getTitlesWidget: (value, _) => Text(
                          NumberFormat.compact().format(value),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: barBottom,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /* ----- LINE ----- */
            Padding(
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: lineSpots.length <= 1
                      ? 1
                      : (lineSpots.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxLine == 0 ? 1 : maxLine,
                  lineBarsData: [
                    LineChartBarData(
                      spots: lineSpots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: maxLine / 4,
                        getTitlesWidget: (value, _) => Text(
                          NumberFormat.compact().format(value),
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 32,
                        getTitlesWidget: lineBottom,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
