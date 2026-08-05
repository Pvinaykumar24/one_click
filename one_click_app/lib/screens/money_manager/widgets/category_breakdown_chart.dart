import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/money_manager_service.dart';

class CategoryBreakdownChart extends ConsumerWidget {
  final MoneyManagerState state;

  const CategoryBreakdownChart({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 144, // size-36
                height: 144,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 48,
                        startDegreeOffset: 270,
                        sections: _buildPieSections(ref),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 96, // size-24
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'SPENT',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${state.monthlySpend.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(child: Column(children: _buildLegendItems(ref))),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(WidgetRef ref) {
    final Map<String, double> categories = ref.read(moneyManagerProvider.notifier)
        .getSpendByCategory();
    if (categories.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: const Color(0xFF1E293B),
          radius: 24,
          showTitle: false,
        ),
      ];
    }

    final List<Color> colors = [
      AppColors.primary,
      const Color(0xFF3B82F6),
      const Color(0xFF60A5FA),
      const Color(0xFF93C5FD),
      const Color(0xFFA5B4FC),
    ];

    int i = 0;
    return categories.entries.map((e) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        value: e.value,
        color: color,
        radius: 24,
        showTitle: false,
      );
    }).toList();
  }

  List<Widget> _buildLegendItems(WidgetRef ref) {
    final Map<String, double> categories = ref.read(moneyManagerProvider.notifier)
        .getSpendByCategory();
    if (categories.isEmpty) {
      return [
        const Text(
          'No expenses yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ];
    }

    final List<Color> colors = [
      AppColors.primary,
      const Color(0xFF3B82F6),
      const Color(0xFF60A5FA),
      const Color(0xFF93C5FD),
      const Color(0xFFA5B4FC),
    ];

    double total = categories.values.fold(0, (sum, val) => sum + val);

    int i = 0;
    return categories.entries.map((e) {
      final color = colors[i % colors.length];
      final pct = (e.value / total * 100).toStringAsFixed(0);
      i++;
      return _buildOverviewLegendItem(e.key, '$pct%', color);
    }).toList();
  }

  Widget _buildOverviewLegendItem(String label, String pct, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            pct,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
