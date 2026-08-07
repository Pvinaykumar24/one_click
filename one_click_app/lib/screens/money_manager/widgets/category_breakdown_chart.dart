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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 144,
                height: 144,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 48,
                        startDegreeOffset: 270,
                        sections: _buildPieSections(ref),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.neoYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'SPENT',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${state.monthlySpend.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: _buildLegendItems(ref),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(WidgetRef ref) {
    final breakdown = ref.watch(moneyManagerProvider.notifier).getMonthlySpendByCategory();
    if (breakdown.isEmpty) {
      return [
        PieChartSectionData(
          color: const Color(0xFFE2E8F0),
          value: 1,
          showTitle: false,
          radius: 12,
        )
      ];
    }

    final colors = [
      AppColors.neoPink,
      AppColors.neoCyan,
      AppColors.neoLime,
      AppColors.neoPurple,
      AppColors.neoOrange,
      AppColors.neoYellow,
    ];

    int i = 0;
    return breakdown.entries.map((e) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: e.value,
        showTitle: false,
        radius: 14,
      );
    }).toList();
  }

  List<Widget> _buildLegendItems(WidgetRef ref) {
    final breakdown = ref.watch(moneyManagerProvider.notifier).getMonthlySpendByCategory();
    if (breakdown.isEmpty) {
      return [
        const Text(
          'No transactions this month',
          style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
        )
      ];
    }

    final colors = [
      AppColors.neoPink,
      AppColors.neoCyan,
      AppColors.neoLime,
      AppColors.neoPurple,
      AppColors.neoOrange,
      AppColors.neoYellow,
    ];

    int i = 0;
    return breakdown.entries.map((e) {
      final color = colors[i % colors.length];
      i++;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.key,
                style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '₹${e.value.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ],
        ),
      );
    }).toList();
  }
}
