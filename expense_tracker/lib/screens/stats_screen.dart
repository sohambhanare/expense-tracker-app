import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/summary.dart';
import '../state/finance_state.dart';
import '../state/settings_state.dart';
import '../theme.dart';
import '../utils/format.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsState>();
    final finance = context.watch<FinanceState>();
    final summary = finance.summary;
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => finance.loadSummary(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            const Text('Statistics', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text('Where your money goes this month',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 20),
            if (summary == null)
              const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
            else ...[
              if (summary.topCategories.isEmpty)
                _panel(context,
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(children: [
                        Icon(Icons.pie_chart_outline, size: 40, color: cs.onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text('No expenses this month yet',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Add a few expenses to see the breakdown.',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                      ]),
                    ))
              else
                _panel(context, child: Padding(padding: const EdgeInsets.all(20), child: _CategoryPie(summary: summary))),
              const SizedBox(height: 16),
              _panel(context, child: Padding(padding: const EdgeInsets.all(20), child: _TrendChart(summary: summary))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _panel(BuildContext context, {required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: child,
      );
}

class _CategoryPie extends StatelessWidget {
  final Summary summary;
  const _CategoryPie({required this.summary});

  @override
  Widget build(BuildContext context) {
    final slices = summary.topCategories;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Spending by category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      const SizedBox(height: 18),
      SizedBox(
        height: 210,
        child: Center(
          child: PieChart(PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 46,
            startDegreeOffset: -90,
            sections: slices.map((s) {
              final color = parseHexColor(s.color);
              return PieChartSectionData(
                value: s.total,
                color: color,
                radius: s.share > 0.25 ? 42 : 34,
                showTitle: s.share >= 0.06,
                title: '${(s.share * 100).round()}%',
                titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
              );
            }).toList(),
          )),
        ),
      ),
      const SizedBox(height: 16),
      // 2-column grid below — 1 → left, 2 → left+right, 4 → 2×2, halves vertical space
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 2,
          mainAxisExtent: 28,
        ),
        itemCount: slices.length,
        itemBuilder: (context, i) {
          final s = slices[i];
          return Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: parseHexColor(s.color), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
          ]);
        },
      ),
    ]);
  }
}

class _TrendChart extends StatelessWidget {
  final Summary summary;
  const _TrendChart({required this.summary});

  @override
  Widget build(BuildContext context) {
    final points = summary.trend;
    final cs = Theme.of(context).colorScheme;
    final sem = context.sem;
    final maxY = points.expand((p) => [p.income, p.expense]).reduce((a, b) => a > b ? a : b);
    final niceMax = _niceCeil(maxY == 0 ? 100 : maxY);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Last 6 months', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(children: [
        _legend(sem.income, 'Income', cs),
        const SizedBox(width: 16),
        _legend(sem.expense, 'Expense', cs),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        height: 220,
        child: BarChart(BarChartData(
          maxY: niceMax,
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(color: cs.outlineVariant, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (v, meta) => Text(Money.compact(v),
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)))),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= points.length) return const SizedBox.shrink();
                      return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(Dates.monthShort(points[i].month),
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)));
                    })),
          ),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                    toY: points[i].income,
                    color: sem.income,
                    width: 10,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                BarChartRodData(
                    toY: points[i].expense,
                    color: sem.expense,
                    width: 10,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
              ]),
          ],
          barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      '${ri == 0 ? 'Income' : 'Expense'}: ${Money.compact(rod.toY)}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
        )),
      ),
    ]);
  }

  Widget _legend(Color color, String label, ColorScheme cs) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
      ]);

  double _niceCeil(double v) {
    if (v <= 0) return 100;
    final digits = v.toInt().toString().length - 1;
    final mag = _pow10(digits == 0 ? 0 : digits);
    return (v / mag).ceil() * mag;
  }

  double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}
