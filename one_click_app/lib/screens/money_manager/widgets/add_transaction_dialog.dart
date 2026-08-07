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
              color: _isExpense ? AppColors.neoPink : AppColors.neoLime,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Icon(_isExpense ? Icons.north_east : Icons.south_west, color: Colors.black, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'Add Entry',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                hintText: 'e.g. Lunch, Bus Pass, Salary',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                hintText: 'e.g. 250',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Type:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Switch(
                  value: _isExpense,
                  activeThumbColor: Colors.black,
                  activeTrackColor: AppColors.neoPink,
                  inactiveThumbColor: Colors.black,
                  inactiveTrackColor: AppColors.neoLime,
                  onChanged: (val) => setState(() => _isExpense = val),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isExpense ? AppColors.neoPink : AppColors.neoLime,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Text(
                    _isExpense ? 'Expense' : 'Income',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: _isExpense ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Category:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Date:', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
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
                  icon: const Icon(Icons.calendar_month, size: 16, color: Colors.black),
                  label: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _receiptUrlController,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Receipt URL / Web Link (Optional)',
                labelStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                hintText: 'https://...',
                hintStyle: TextStyle(color: Colors.black38, fontSize: 12),
                prefixIcon: Icon(Icons.link, color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neoYellow,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
          ),
          onPressed: _isSaving ? null : _submitTransaction,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Add Entry ⚡', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
