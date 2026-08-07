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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2.5),
        ),
        title: const Text('Delete Transaction', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to delete "$title"?', style: const TextStyle(color: Colors.black87, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neoPink),
            onPressed: () {
              ref.read(moneyManagerProvider.notifier).deleteTransaction(txId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "$title"')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(BuildContext context, String title, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black, width: 2.5),
        ),
        title: Text('Receipt: $title', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.neoCyan,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                if (state.transactions.isNotEmpty)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neoYellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ExportCsvDialog(transactions: state.transactions),
                      );
                    },
                    icon: const Icon(Icons.file_download_outlined, size: 16, color: Colors.black),
                    label: const Text('Export CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.transactions.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No transactions logged yet',
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ...state.transactions.take(15).map((tx) {
          IconData icon = Icons.payments;
          Color bg = AppColors.neoYellow;
          if (tx.category == 'Food') {
            icon = Icons.restaurant;
            bg = AppColors.neoPink;
          }
          if (tx.category == 'Supplies') {
            icon = Icons.shopping_bag;
            bg = AppColors.neoCyan;
          }
          if (tx.category == 'Transport') {
            icon = Icons.directions_car;
            bg = AppColors.neoOrange;
          }
          if (tx.category == 'Academics') {
            icon = Icons.menu_book;
            bg = AppColors.neoPurple;
          }

          return _buildTransactionItem(
            context: context,
            ref: ref,
            icon: icon,
            iconColor: bg == AppColors.neoPurple || bg == AppColors.neoPink ? Colors.white : Colors.black,
            iconBg: bg,
            title: tx.title,
            category: tx.category,
            time: '${tx.date.day}/${tx.date.month}/${tx.date.year}',
            amount: '${tx.isExpense ? '-' : '+'}₹${tx.amount.toStringAsFixed(0)}',
            amountColor: tx.isExpense ? Colors.black : const Color(0xFF00C853),
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
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1.5),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "$time • $category",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _showReceiptDialog(context, title, receiptUrl),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.neoCyan,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.link, size: 12, color: Colors.black),
                    SizedBox(width: 3),
                    Text('Link', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                  ],
                ),
              ),
            ),
          ],
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: amountColor,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black54, size: 20),
            onPressed: () => _confirmDelete(context, ref, txId, title),
          ),
        ],
      ),
    );
  }
}
