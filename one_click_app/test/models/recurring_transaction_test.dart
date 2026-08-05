import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:one_click_app/services/recurring_transactions_service.dart';

void main() {
  group('RecurringTransaction Model & Calculation Tests', () {
    final sampleDate = DateTime(2026, 8, 15);

    test('toMap correctly serializes all fields', () {
      final tx = RecurringTransaction(
        id: 'rec_1',
        title: 'Hostel Fee',
        category: 'Housing',
        amount: 4500.0,
        recurrenceInterval: 'monthly',
        nextDueDate: sampleDate,
        lastProcessedDate: DateTime(2026, 7, 15),
        isActive: true,
        isExpense: true,
      );

      final map = tx.toMap();
      expect(map['title'], 'Hostel Fee');
      expect(map['category'], 'Housing');
      expect(map['amount'], 4500.0);
      expect(map['recurrenceInterval'], 'monthly');
      expect(map['isActive'], true);
      expect((map['nextDueDate'] as Timestamp).toDate(), sampleDate);
      expect((map['lastProcessedDate'] as Timestamp).toDate(), DateTime(2026, 7, 15));
    });

    test('fromMap correctly parses Firestore data and defaults optional flags', () {
      final map = {
        'title': 'Stipend',
        'category': 'Income',
        'amount': 8000.0,
        'recurrenceInterval': 'monthly',
        'nextDueDate': Timestamp.fromDate(sampleDate),
        'isExpense': false,
      };

      final tx = RecurringTransaction.fromMap(map, 'doc_stipend');
      expect(tx.id, 'doc_stipend');
      expect(tx.title, 'Stipend');
      expect(tx.amount, 8000.0);
      expect(tx.isExpense, false);
      expect(tx.isActive, true); // default
      expect(tx.lastProcessedDate, isNull);
    });

    test('calculateNextDueDate advances correctly for daily interval', () {
      final current = DateTime(2026, 8, 15, 10, 0);
      final next = RecurringTransaction.calculateNextDueDate(current, 'daily');
      expect(next, DateTime(2026, 8, 16, 10, 0));
    });

    test('calculateNextDueDate advances correctly for weekly interval', () {
      final current = DateTime(2026, 8, 15, 10, 0);
      final next = RecurringTransaction.calculateNextDueDate(current, 'weekly');
      expect(next, DateTime(2026, 8, 22, 10, 0));
    });

    test('calculateNextDueDate advances correctly for monthly interval across standard months', () {
      final current = DateTime(2026, 8, 15, 10, 0);
      final next = RecurringTransaction.calculateNextDueDate(current, 'monthly');
      expect(next, DateTime(2026, 9, 15, 10, 0));
    });

    test('calculateNextDueDate handles month-end boundary cleanly (e.g. Jan 31 -> Feb 28)', () {
      final current = DateTime(2026, 1, 31, 8, 30);
      final next = RecurringTransaction.calculateNextDueDate(current, 'monthly');
      expect(next, DateTime(2026, 2, 28, 8, 30));
    });

    test('calculateNextDueDate handles year transition (Dec -> Jan)', () {
      final current = DateTime(2026, 12, 10, 12, 0);
      final next = RecurringTransaction.calculateNextDueDate(current, 'monthly');
      expect(next, DateTime(2027, 1, 10, 12, 0));
    });
  });
}
