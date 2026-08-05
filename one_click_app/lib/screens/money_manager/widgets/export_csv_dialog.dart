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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
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
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.table_chart, color: AppColors.primary, size: 24),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Export Transactions (CSV)',
              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a date range (defaults to current month) to export your ledger in standard RFC 4180 format with columns: Date, Category, Description, Amount, Currency.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  matchingTx.isEmpty ? Icons.info_outline : Icons.check_circle_outline,
                  color: matchingTx.isEmpty ? AppColors.textSecondary : AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  '${matchingTx.length} transaction${matchingTx.length == 1 ? '' : 's'} ready to export',
                  style: TextStyle(
                    fontSize: 13,
                    color: matchingTx.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
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
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.share, size: 16),
          label: const Text('Export & Share', style: TextStyle(fontWeight: FontWeight.bold)),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Text(dateStr, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
