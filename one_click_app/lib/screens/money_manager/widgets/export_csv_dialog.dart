import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/money_manager_service.dart';
import '../../../services/export_service.dart';

class ExportCsvDialog extends StatefulWidget {
  final List<Transaction> transactions;

  const ExportCsvDialog({super.key, required this.transactions});

  @override
  State<ExportCsvDialog> createState() => _ExportCsvDialogState();
}

class _ExportCsvDialogState extends State<ExportCsvDialog> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
    _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
          if (_startDate.isAfter(_endDate)) {
            _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          }
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          if (_endDate.isBefore(_startDate)) {
            _startDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
          }
        }
      });
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final matchingTx = widget.transactions.where((tx) {
      return !tx.date.isBefore(_startDate) && !tx.date.isAfter(_endDate);
    }).toList();

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.black, width: 2.5),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.neoCyan,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Icon(Icons.table_chart, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Export Transactions (CSV)',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export your financial ledger in standard CSV format for Excel, Google Sheets, or auditing.',
            style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateTile(
                  title: 'From',
                  dateStr: _formatDate(_startDate),
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateTile(
                  title: 'To',
                  dateStr: _formatDate(_endDate),
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: matchingTx.isEmpty ? AppColors.neoPink : AppColors.neoLime,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  matchingTx.isEmpty ? Icons.info_outline : Icons.check_circle_outline,
                  color: matchingTx.isEmpty ? Colors.white : Colors.black,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  '${matchingTx.length} transaction${matchingTx.length == 1 ? '' : 's'} ready to export',
                  style: TextStyle(
                    fontSize: 13,
                    color: matchingTx.isEmpty ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neoYellow,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
          icon: const Icon(Icons.share, size: 16, color: Colors.black),
          label: const Text('Export & Share ⚡', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
          onPressed: matchingTx.isEmpty
              ? null
              : () async {
                  await ExportService.exportAndShare(
                    widget.transactions,
                    startDate: _startDate,
                    endDate: _endDate,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📄 CSV Export generated and shared successfully!')),
                    );
                  }
                },
        ),
      ],
    );
  }

  Widget _buildDateTile({required String title, required String dateStr, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.black, size: 14),
                const SizedBox(width: 6),
                Text(dateStr, style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
