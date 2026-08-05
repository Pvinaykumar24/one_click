import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/recurring_transactions_service.dart';

class AddEditRecurringDialog extends ConsumerStatefulWidget {
  final RecurringTransaction? existingTx;

  const AddEditRecurringDialog({super.key, this.existingTx});

  @override
  ConsumerState<AddEditRecurringDialog> createState() => _AddEditRecurringDialogState();
}

class _AddEditRecurringDialogState extends ConsumerState<AddEditRecurringDialog> {
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late String _category;
  late String _recurrenceInterval;
  late bool _isExpense;
  late DateTime _nextDueDate;

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTx;
    _titleController = TextEditingController(text: tx?.title ?? '');
    _amountController = TextEditingController(text: tx != null ? tx.amount.toStringAsFixed(0) : '');
    _category = tx?.category ?? 'Housing';
    _recurrenceInterval = tx?.recurrenceInterval.toLowerCase() ?? 'monthly';
    _isExpense = tx?.isExpense ?? true;
    _nextDueDate = tx?.nextDueDate ?? DateTime.now();

    // Ensure initial category exists in our selectable list
    final categories = ['Housing', 'Food', 'Supplies', 'Transport', 'Academics', 'Subscriptions', 'Income', 'Other'];
    if (!categories.contains(_category)) {
      _category = 'Other';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
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
    if (picked != null && picked != _nextDueDate) {
      setState(() {
        _nextDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTx != null;
    final categories = ['Housing', 'Food', 'Supplies', 'Transport', 'Academics', 'Subscriptions', 'Income', 'Other'];

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEditing ? 'Edit Recurring Item' : 'New Recurring Item',
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
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
                labelText: 'Title (e.g., Hostel Fee, Mess Rent)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Type:', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                Switch(
                  value: _isExpense,
                  activeThumbColor: AppColors.error,
                  inactiveThumbColor: AppColors.success,
                  inactiveTrackColor: AppColors.success.withValues(alpha: 0.3),
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
                    items: categories.map((String value) {
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
            Row(
              children: [
                const Text('Frequency:', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _recurrenceInterval,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    underline: Container(height: 1, color: AppColors.border),
                    items: const [
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _recurrenceInterval = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Next Due:', style: TextStyle(color: AppColors.textSecondary)),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
                  label: Text(
                    "${_nextDueDate.day}/${_nextDueDate.month}/${_nextDueDate.year}",
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final title = _titleController.text.trim();
            final amount = double.tryParse(_amountController.text) ?? 0.0;

            if (title.isNotEmpty && amount > 0) {
              final tx = RecurringTransaction(
                id: widget.existingTx?.id ?? '',
                title: title,
                category: _category,
                amount: amount,
                recurrenceInterval: _recurrenceInterval,
                nextDueDate: _nextDueDate,
                lastProcessedDate: widget.existingTx?.lastProcessedDate,
                isActive: widget.existingTx?.isActive ?? true,
                isExpense: _isExpense,
              );

              if (isEditing) {
                ref.read(recurringTransactionsProvider.notifier).updateRecurring(tx);
              } else {
                ref.read(recurringTransactionsProvider.notifier).addRecurring(tx);
              }
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please provide a valid title and amount > 0')),
              );
            }
          },
          child: Text(isEditing ? 'Save Changes' : 'Add', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
