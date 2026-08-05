import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/money_manager_service.dart';
import 'widgets/money_manager_header.dart';
import 'widgets/balance_cards.dart';
import 'widgets/budget_status_bar.dart';
import 'widgets/category_breakdown_chart.dart';
import 'widgets/cashflow_summary.dart';
import 'widgets/transaction_list.dart';
import 'widgets/add_transaction_dialog.dart';
import 'widgets/recurring_transactions_section.dart';
import 'widgets/category_budgets_section.dart';

class MoneyManagerScreen extends ConsumerWidget {
  const MoneyManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moneyState = ref.watch(moneyManagerProvider).valueOrNull ?? MoneyManagerState(transactions: []);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const MoneyManagerHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BalanceCards(state: moneyState),
                    const SizedBox(height: 24),
                    const RecurringTransactionsSection(),
                    const SizedBox(height: 24),
                    BudgetStatusBar(state: moneyState),
                    const SizedBox(height: 24),
                    const CategoryBudgetsSection(),
                    const SizedBox(height: 24),
                    CategoryBreakdownChart(state: moneyState),
                    const SizedBox(height: 24),
                    CashflowSummary(state: moneyState),
                    const SizedBox(height: 24),
                    TransactionList(state: moneyState),
                    const SizedBox(height: 80), // For FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const AddTransactionDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        elevation: 8,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
