import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/money_manager_service.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _receiptUrlController = TextEditingController();

  String _category = 'Food';
  bool _isExpense = true;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _receiptUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitTransaction() async {
    final title = _titleController.text.trim();
    final rawAmount = _amountController.text.trim();
    final amount = double.tryParse(rawAmount) ?? 0.0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a valid title and amount greater than ₹0')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final txId = DateTime.now().millisecondsSinceEpoch.toString();
    final receiptUrl = _receiptUrlController.text.trim().isNotEmpty ? _receiptUrlController.text.trim() : null;

    final success = await ref.read(moneyManagerProvider.notifier).addTransaction(
      Transaction(
        id: txId,
        title: title,
        category: _category,
        amount: amount,
        date: _selectedDate,
        isExpense: _isExpense,
        receiptUrl: receiptUrl,
      ),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transaction "$title" saved successfully! ✅')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save transaction to cloud. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Add Transaction',
        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: 'e.g. Lunch, Bus Pass, Salary',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: 'e.g. 250',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Type:',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isExpense,
                  activeThumbColor: AppColors.error,
                  inactiveThumbColor: AppColors.success,
                  onChanged: (val) => setState(() => _isExpense = val),
                ),
                Text(
                  _isExpense ? 'Expense' : 'Income',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isExpense ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Category:', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    underline: Container(height: 1, color: AppColors.border),
                    items: [
                      'Food',
                      'Supplies',
                      'Transport',
                      'Academics',
                      'Income',
                      'Other',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date Picker Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transaction Date:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_month, size: 16, color: AppColors.primary),
                  label: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _receiptUrlController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Receipt URL / Web Link (Optional)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: 'https://...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                prefixIcon: Icon(Icons.link, color: Colors.cyan, size: 20),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(80, 38),
          ),
          onPressed: _isSaving ? null : _submitTransaction,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
