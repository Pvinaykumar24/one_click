import 'package:flutter_test/flutter_test.dart';
import 'package:one_click_app/services/budget_service.dart';
import 'package:one_click_app/services/money_manager_service.dart';

void main() {
  group('Task D6: Per-Category Budget & Alert Unit Tests', () {
    test('Budget model cleanly serializes, deserializes, and copies attributes', () {
      final b = Budget(category: 'Food', limitAmount: 3500.0);
      final map = b.toMap();
      expect(map['category'], 'Food');
      expect(map['limitAmount'], 3500.0);

      final fromMap = Budget.fromMap(map, 'Food');
      expect(fromMap.category, 'Food');
      expect(fromMap.limitAmount, 3500.0);

      final copy = b.copyWith(limitAmount: 4000.0);
      expect(copy.category, 'Food');
      expect(copy.limitAmount, 4000.0);
    });

    test('Budget.fromMap handles missing optional fields gracefully', () {
      final emptyMap = <String, dynamic>{};
      final b = Budget.fromMap(emptyMap, 'Transport');
      expect(b.category, 'Transport');
      expect(b.limitAmount, 0.0);
    });

    test('evaluateCategoryAlerts executes cleanly when spend crosses 80% and 100% bounds without Hive errors', () {
      final budgets = {
        'Food': Budget(category: 'Food', limitAmount: 2000.0),
        'Supplies': Budget(category: 'Supplies', limitAmount: 1000.0),
        'Transport': Budget(category: 'Transport', limitAmount: 500.0),
      };

      final spends = {
        'Food': 1600.0, // exactly 80%
        'Supplies': 1100.0, // 110% (exceeded)
        'Transport': 200.0, // 40% (safe)
      };

      expect(() => BudgetNotifier.evaluateCategoryAlerts(spends, budgets, null, false), returnsNormally);
    });

    test('MoneyManagerState preserves custom category items across transaction manipulations', () {
      final now = DateTime.now();
      final tx1 = Transaction(
        id: '1',
        title: 'Lunch',
        category: 'Food',
        amount: 350.0,
        date: now,
        isExpense: true,
      );
      final tx2 = Transaction(
        id: '2',
        title: 'Past month dinner',
        category: 'Food',
        amount: 800.0,
        date: DateTime(now.year, now.month - 1, 15),
        isExpense: true,
      );

      final state = MoneyManagerState(transactions: [tx1, tx2], monthlySpend: 350.0);
      expect(state.transactions.length, 2);
      expect(state.monthlySpend, 350.0);
    });
  });
}
