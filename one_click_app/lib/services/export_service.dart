import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'money_manager_service.dart';

class ExportService {
  static String generateCsvString(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Category,Description,Amount,Currency');
    
    for (var tx in transactions) {
      if (startDate != null && tx.date.isBefore(startDate)) continue;
      if (endDate != null && tx.date.isAfter(endDate)) continue;

      final dateStr = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}";
      final categoryStr = '"${tx.category.replaceAll('"', '""')}"';
      final descStr = '"${tx.title.replaceAll('"', '""')}"';
      final amountVal = tx.isExpense ? -tx.amount : tx.amount;
      final amountStr = amountVal.toStringAsFixed(2);
      
      buffer.writeln('$dateStr,$categoryStr,$descStr,$amountStr,INR');
    }
    
    return buffer.toString();
  }

  static Future<void> exportAndShare(
    List<Transaction> transactions, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final csvContent = generateCsvString(transactions, startDate: startDate, endDate: endDate);
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/one_click_transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final file = File(filePath);
      await file.writeAsString(csvContent, flush: true);
      
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'One Click App Transaction History (CSV)',
          subject: 'My Transaction Export',
        ),
      );
      debugPrint("📄 [EXPORT] Successfully exported and opened share menu for CSV: $filePath");
    } catch (e) {
      debugPrint("❌ [EXPORT] Error exporting CSV ledger: $e");
    }
  }
}
