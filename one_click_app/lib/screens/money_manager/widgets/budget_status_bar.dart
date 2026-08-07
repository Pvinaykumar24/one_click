import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/money_manager_service.dart';

class BudgetStatusBar extends ConsumerWidget {
  final MoneyManagerState state;

  const BudgetStatusBar({super.key, required this.state});

  void _showEditBudgetDialog(BuildContext context, WidgetRef ref, double currentBudget) {
    final controller = TextEditingController(text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '5000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2.5),
        ),
        title: const Text('Set Monthly Budget', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            labelText: 'Budget Amount (₹)',
            hintText: 'e.g. 5000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neoYellow),
            onPressed: () async {
              final newBudget = double.tryParse(controller.text.trim()) ?? 0.0;
              if (newBudget > 0) {
                await ref.read(moneyManagerProvider.notifier).updateMonthlyBudget(newBudget);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save Budget ⚡', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = state.monthlyBudget > 0 ? state.monthlyBudget : 1.0;
    final remaining = (budget - state.monthlySpend).clamp(0.0, budget);
    final ratio = (state.monthlySpend / budget).clamp(0.0, 1.0);

    Color barColor = AppColors.neoLime;
    if (ratio >= 1.0) {
      barColor = AppColors.neoPink;
    } else if (ratio >= 0.8) {
      barColor = AppColors.neoYellow;
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Budget Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showEditBudgetDialog(context, ref, state.monthlyBudget),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.neoYellow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 12, color: Colors.black),
                              SizedBox(width: 3),
                              Text('Edit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${remaining.toStringAsFixed(0)} remaining of ₹${budget.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text(
                  '${(ratio * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: ratio >= 1.0 ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(
                  color: barColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
