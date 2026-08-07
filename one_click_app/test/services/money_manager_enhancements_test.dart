import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:one_click_app/services/money_manager_service.dart';
import 'package:one_click_app/services/export_service.dart';

void main() {
  group('Money Manager Enhancements Tests (D5 Sub-tasks 2, 3, 4)', () {
    final sampleDate = DateTime(2026, 8, 5, 14, 30);

    test('Transaction model cleanly serializes and deserializes receiptUrl attribute', () {
      final tx = Transaction(
        id: 'tx_001',
        title: 'Textbook Purchase',
        category: 'Academics',
        amount: 850.0,
        date: sampleDate,
        isExpense: true,
        receiptUrl: 'https://invoice.google.com/doc123',
      );

      final map = tx.toMap();
      expect(map['title'], 'Textbook Purchase');
      expect(map['amount'], 850.0);
      expect(map['receiptUrl'], 'https://invoice.google.com/doc123');

      final fromMapTx = Transaction.fromMap(map, 'tx_001');
      expect(fromMapTx.id, 'tx_001');
      expect(fromMapTx.receiptUrl, 'https://invoice.google.com/doc123');
    });

    test('Transaction.fromMap defaults receiptUrl to null for legacy documents without the field', () {
      final legacyMap = {
        'title': 'Coffee',
        'category': 'Food',
        'amount': 50.0,
        'date': Timestamp.fromDate(sampleDate),
        'isExpense': true,
      };

      final legacyTx = Transaction.fromMap(legacyMap, 'tx_legacy');
      expect(legacyTx.id, 'tx_legacy');
      expect(legacyTx.receiptUrl, isNull);
    });

    test('Transaction model cleanly serializes receiptUrl', () {
      final tx = Transaction(
        id: 'tx_img',
        title: 'Lunch receipt photo',
        category: 'Food',
        amount: 250.0,
        date: sampleDate,
        receiptUrl: 'https://firebasestorage.googleapis.com/v0/b/one-click/receipts/img.jpg',
      );

      final map = tx.toMap();
      expect(map['receiptUrl'], 'https://firebasestorage.googleapis.com/v0/b/one-click/receipts/img.jpg');

      final fromMap = Transaction.fromMap(map, 'tx_img');
      expect(fromMap.receiptUrl, 'https://firebasestorage.googleapis.com/v0/b/one-click/receipts/img.jpg');
    });

    test('MoneyManagerState defaults monthlyBudget to 20000 and clones cleanly via copyWith', () {
      final state = MoneyManagerState(transactions: [], monthlySpend: 4500.0);
      expect(state.monthlyBudget, 20000.0);

      final updated = state.copyWith(monthlyBudget: 25000.0, monthlySpend: 5000.0);
      expect(updated.monthlyBudget, 25000.0);
      expect(updated.monthlySpend, 5000.0);
      expect(updated.initialBalance, 0.0);
    });

    test('ExportService.generateCsvString outputs RFC 4180 compliant CSV with required columns (Date, Category, Description, Amount, Currency)', () {
      final tx1 = Transaction(
        id: '101',
        title: 'Books & Supplies, Phase 1',
        category: 'Academics',
        amount: 1200.0,
        date: DateTime(2026, 8, 1, 10, 5),
        isExpense: true,
        receiptUrl: 'voucher_01.jpg',
      );
      final tx2 = Transaction(
        id: '102',
        title: 'Stipend "August"',
        category: 'Income',
        amount: 10000.0,
        date: DateTime(2026, 8, 2, 16, 45),
        isExpense: false,
      );

      final csv = ExportService.generateCsvString([tx1, tx2]);
      final lines = csv.trim().split('\n').map((l) => l.trim()).toList();

      expect(lines[0], 'Date,Category,Description,Amount,Currency');
      expect(lines[1], '2026-08-01,"Academics","Books & Supplies, Phase 1",-1200.00,INR');
      expect(lines[2], '2026-08-02,"Income","Stipend ""August""",10000.00,INR');
    });

    test('ExportService.generateCsvString accurately filters transactions by selectable startDate and endDate bounds', () {
      final txOld = Transaction(
        id: 'old_tx',
        title: 'July Rent',
        category: 'Housing',
        amount: 5000.0,
        date: DateTime(2026, 7, 15),
        isExpense: true,
      );
      final txCurrent = Transaction(
        id: 'current_tx',
        title: 'August Groceries',
        category: 'Food',
        amount: 850.0,
        date: DateTime(2026, 8, 5),
        isExpense: true,
      );
      final txFuture = Transaction(
        id: 'future_tx',
        title: 'September Advance',
        category: 'Other',
        amount: 2000.0,
        date: DateTime(2026, 9, 1),
        isExpense: true,
      );

      final augStart = DateTime(2026, 8, 1);
      final augEnd = DateTime(2026, 8, 31, 23, 59, 59);

      final csv = ExportService.generateCsvString(
        [txOld, txCurrent, txFuture],
        startDate: augStart,
        endDate: augEnd,
      );

      expect(csv.contains('August Groceries'), isTrue);
      expect(csv.contains('July Rent'), isFalse);
      expect(csv.contains('September Advance'), isFalse);
    });
  });
}

