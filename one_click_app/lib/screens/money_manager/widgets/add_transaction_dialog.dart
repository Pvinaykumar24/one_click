import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/money_manager_service.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  String _title = '';
  String _category = 'Food';
  double _amount = 0.0;
  bool _isExpense = true;
  String _receiptUrl = '';
  XFile? _pickedImage;
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _pickedImage = picked);
      }
    } catch (e) {
      debugPrint("Error picking receipt photo: $e");
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
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              onChanged: (val) => _title = val,
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              onChanged: (val) => _amount = double.tryParse(val) ?? 0,
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
                    onChanged: (val) => setState(() => _category = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Attach Receipt Photo:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Camera', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyan,
                      side: const BorderSide(color: Colors.cyan),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Gallery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (_pickedImage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.cyan.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: kIsWeb
                          ? Image.network(_pickedImage!.path, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.receipt_long, color: Colors.cyan, size: 24))
                          : Image.file(File(_pickedImage!.path), width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.receipt_long, color: Colors.cyan, size: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _pickedImage!.name,
                        style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                      onPressed: _isUploading ? null : () => setState(() => _pickedImage = null),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Receipt URL / Note (Optional)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.receipt_long, color: AppColors.textSecondary, size: 20),
              ),
              onChanged: (val) => _receiptUrl = val.trim(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
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
          onPressed: _isUploading
              ? null
              : () async {
                  if (_title.isNotEmpty && _amount > 0) {
                    setState(() => _isUploading = true);
                    final txId = DateTime.now().millisecondsSinceEpoch.toString();
                    String? finalReceiptUrl = _receiptUrl.isNotEmpty ? _receiptUrl : null;

                    if (_pickedImage != null) {
                      final uploaded = await ref.read(moneyManagerProvider.notifier).uploadReceiptImage(_pickedImage!, txId);
                      if (uploaded != null) {
                        finalReceiptUrl = uploaded;
                      }
                    }

                    await ref.read(moneyManagerProvider.notifier).addTransaction(
                      Transaction(
                        id: txId,
                        title: _title,
                        category: _category,
                        amount: _amount,
                        date: DateTime.now(),
                        isExpense: _isExpense,
                        receiptUrl: finalReceiptUrl,
                        receiptImageUrl: finalReceiptUrl,
                      ),
                    );

                    if (context.mounted) {
                      setState(() => _isUploading = false);
                      Navigator.pop(context);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide a valid title and amount > 0')),
                    );
                  }
                },
          child: _isUploading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
