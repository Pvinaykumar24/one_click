import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/money_manager_service.dart';
import '../../../services/budget_service.dart';

class CategoryBudgetsSection extends ConsumerWidget {
  const CategoryBudgetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsState = ref.watch(categoryBudgetsProvider);
    ref.watch(moneyManagerProvider);

    final Map<String, double> spends = ref.read(moneyManagerProvider.notifier).getMonthlySpendByCategory();
    final Map<String, Budget> budgets = budgetsState.valueOrNull ?? {};

    final List<String> defaultCategories = ['Food', 'Supplies', 'Transport', 'Academics', 'Housing', 'Other'];
    final List<String> activeCategories = defaultCategories.where((c) => (spends[c] ?? 0) > 0 || (budgets[c]?.limitAmount ?? 0) > 0).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category Budgets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Month-to-Date Spend & Limits',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.primary, width: 1),
                  ),
                ),
                onPressed: () => _showSelectCategoryDialog(context, ref, defaultCategories, budgets),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Set Budget', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (activeCategories.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'No category budgets or expenses this month.\nTap "Set Budget" to define spending caps!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
              ),
            )
          else
            ...activeCategories.map((cat) {
              final spend = spends[cat] ?? 0.0;
              final limit = budgets[cat]?.limitAmount ?? 0.0;
              final ratio = limit > 0 ? (spend / limit).clamp(0.0, 1.0) : (spend > 0 ? 0.05 : 0.0);

              Color barColor = AppColors.primary;
              if (limit > 0 && spend >= limit) {
                barColor = AppColors.error;
              } else if (limit > 0 && spend >= limit * 0.8) {
                barColor = const Color(0xFFF59E0B);
              }

              IconData icon = Icons.category;
              if (cat == 'Food') icon = Icons.restaurant;
              if (cat == 'Supplies') icon = Icons.shopping_bag;
              if (cat == 'Transport') icon = Icons.directions_car;
              if (cat == 'Academics') icon = Icons.menu_book;
              if (cat == 'Housing') icon = Icons.home;

              return InkWell(
                onTap: () => _showEditCategoryBudgetDialog(context, ref, cat, limit),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(icon, color: barColor, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                cat,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            limit > 0
                                ? '₹${spend.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)} (${(spend / limit * 100).toStringAsFixed(0)}%)'
                                : '₹${spend.toStringAsFixed(0)} (No limit)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: limit > 0 && spend >= limit * 0.8 ? FontWeight.bold : FontWeight.normal,
                              color: limit > 0 && spend >= limit * 0.8 ? barColor : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showSelectCategoryDialog(BuildContext context, WidgetRef ref, List<String> categories, Map<String, Budget> budgets) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Category', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: categories.map((c) {
            return ListTile(
              title: Text(c, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
              onTap: () {
                Navigator.pop(ctx);
                _showEditCategoryBudgetDialog(context, ref, c, budgets[c]?.limitAmount ?? 0.0);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEditCategoryBudgetDialog(BuildContext context, WidgetRef ref, String category, double currentLimit) {
    final controller = TextEditingController(text: currentLimit > 0 ? currentLimit.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Set Budget: $category', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Define your maximum monthly expenditure allowance for $category to enable intelligent threshold alerts.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'Monthly Limit (₹)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          if (currentLimit > 0)
            TextButton(
              onPressed: () {
                ref.read(categoryBudgetsProvider.notifier).deleteBudget(category);
                Navigator.pop(ctx);
              },
              child: const Text('Remove Limit', style: TextStyle(color: AppColors.error)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final val = double.tryParse(controller.text.trim()) ?? 0.0;
              if (val > 0) {
                ref.read(categoryBudgetsProvider.notifier).setBudget(category, val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
