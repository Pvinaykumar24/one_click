import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/money_manager_service.dart';
import 'export_csv_dialog.dart';

class TransactionList extends ConsumerWidget {
  final MoneyManagerState state;

  const TransactionList({super.key, required this.state});

  void _confirmDelete(BuildContext context, WidgetRef ref, String txId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F131C),
        title: const Text('Delete Transaction', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$title"?', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(moneyManagerProvider.notifier).deleteTransaction(txId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "$title"')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                if (state.transactions.isNotEmpty)
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
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ExportCsvDialog(transactions: state.transactions),
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 15),
                    label: const Text('Export CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (state.transactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No transactions logged yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ...state.transactions.take(15).map((tx) {
          IconData icon = Icons.payments;
          if (tx.category == 'Food') icon = Icons.restaurant;
          if (tx.category == 'Supplies') icon = Icons.shopping_bag;
          if (tx.category == 'Transport') icon = Icons.directions_car;
          if (tx.category == 'Academics') icon = Icons.menu_book;
          if (tx.category == 'Housing') icon = Icons.home;

          return _buildTransactionItem(
            context: context,
            ref: ref,
            icon: icon,
            iconColor: tx.isExpense ? AppColors.error : AppColors.success,
            iconBg: (tx.isExpense ? AppColors.error : AppColors.success).withValues(alpha: 0.2),
            title: tx.title,
            category: tx.category,
            time: '${tx.date.day}/${tx.date.month}/${tx.date.year}',
            amount: '${tx.isExpense ? '-' : '+'}₹${tx.amount.toStringAsFixed(0)}',
            amountColor: tx.isExpense ? AppColors.error : AppColors.success,
            txId: tx.id,
            receiptUrl: tx.receiptUrl,
          );
        }),
      ],
    );
  }

  Widget _buildTransactionItem({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String category,
    required String time,
    required String amount,
    required Color amountColor,
    required String txId,
    String? receiptUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        border: Border.all(color: const Color(0xFF1E2638)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$time • $category",
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
            Tooltip(
              message: 'View Receipt',
              child: InkWell(
                onTap: () => _showReceiptDialog(context, title, receiptUrl),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyan.withValues(alpha: 0.4)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: receiptUrl.startsWith('http') || receiptUrl.contains('firebasestorage')
                        ? Image.network(
                            receiptUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.receipt_long, color: Colors.cyan, size: 18),
                          )
                        : const Icon(Icons.receipt_long, color: Colors.cyan, size: 18),
                  ),
                ),
              ),
            ),
          ],
          Text(
            amount,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () => _confirmDelete(context, ref, txId, title),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, String title, String receiptUrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F131C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Colors.cyan, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Receipt: $title',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attached Voucher / Photo:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (receiptUrl.startsWith('http') || receiptUrl.contains('firebasestorage'))
              Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      receiptUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Center(
                        child: Text("Unable to load receipt preview", style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  receiptUrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace'),
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
