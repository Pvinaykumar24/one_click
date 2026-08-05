import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/recurring_transactions_service.dart';
import 'add_edit_recurring_dialog.dart';

class RecurringTransactionsSection extends ConsumerWidget {
  const RecurringTransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringList = ref.watch(recurringTransactionsProvider).valueOrNull ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Recurring Bills & Income',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Automated fees, rent & stipends',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.primary, width: 1),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => const AddEditRecurringDialog(),
                  );
                },
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recurringList.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.autorenew, color: AppColors.textSecondary, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No recurring items configured yet. Add your hostel rent, mess fees, or monthly allowance for automatic tracking!',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recurringList.length,
              separatorBuilder: (ctx, index) => const Divider(color: Color(0xFF334155), height: 16),
              itemBuilder: (context, index) {
                final tx = recurringList[index];
                final color = tx.isExpense ? AppColors.error : AppColors.success;
                final icon = tx.isExpense ? Icons.arrow_outward : Icons.arrow_downward;

                return Opacity(
                  opacity: tx.isActive ? 1.0 : 0.5,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    tx.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: tx.isActive ? AppColors.textPrimary : AppColors.textSecondary,
                                      decoration: tx.isActive ? null : TextDecoration.lineThrough,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    tx.recurrenceInterval.toUpperCase(),
                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Due: ${tx.nextDueDate.day}/${tx.nextDueDate.month}/${tx.nextDueDate.year} • ${tx.category}",
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${tx.isExpense ? '-' : '+'}₹${tx.amount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: tx.isActive ? 'Pause execution' : 'Resume execution',
                                child: Transform.scale(
                                  scale: 0.75,
                                  child: Switch(
                                    value: tx.isActive,
                                    activeThumbColor: AppColors.primary,
                                    inactiveThumbColor: AppColors.textSecondary,
                                    onChanged: (val) {
                                      ref.read(recurringTransactionsProvider.notifier).toggleActive(tx.id, tx.isActive);
                                    },
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AddEditRecurringDialog(existingTx: tx),
                                  );
                                },
                                child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppColors.surface,
                                      title: const Text('Delete Recurring Item', style: TextStyle(color: AppColors.textPrimary)),
                                      content: Text('Are you sure you want to delete "${tx.title}"? This will stop future recurring billing.', style: const TextStyle(color: AppColors.textSecondary)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                          onPressed: () {
                                            ref.read(recurringTransactionsProvider.notifier).deleteRecurring(tx.id);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
