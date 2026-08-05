import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../core/notifications/local_notifications_service.dart';
import 'money_manager_service.dart';

class RecurringTransaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String recurrenceInterval; // 'monthly', 'weekly', 'daily'
  final DateTime nextDueDate;
  final DateTime? lastProcessedDate;
  final bool isActive;
  final bool isExpense;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.recurrenceInterval,
    required this.nextDueDate,
    this.lastProcessedDate,
    this.isActive = true,
    this.isExpense = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'recurrenceInterval': recurrenceInterval,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'lastProcessedDate': lastProcessedDate != null ? Timestamp.fromDate(lastProcessedDate!) : null,
      'isActive': isActive,
      'isExpense': isExpense,
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map, String docId) {
    return RecurringTransaction(
      id: docId,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      recurrenceInterval: map['recurrenceInterval'] ?? 'monthly',
      nextDueDate: (map['nextDueDate'] as Timestamp).toDate(),
      lastProcessedDate: map['lastProcessedDate'] != null ? (map['lastProcessedDate'] as Timestamp).toDate() : null,
      isActive: map['isActive'] ?? true,
      isExpense: map['isExpense'] ?? true,
    );
  }

  RecurringTransaction copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    String? recurrenceInterval,
    DateTime? nextDueDate,
    DateTime? lastProcessedDate,
    bool? isActive,
    bool? isExpense,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastProcessedDate: lastProcessedDate ?? this.lastProcessedDate,
      isActive: isActive ?? this.isActive,
      isExpense: isExpense ?? this.isExpense,
    );
  }

  static DateTime calculateNextDueDate(DateTime current, String interval) {
    switch (interval.toLowerCase()) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
      default:
        // Handle end of month edge cases (e.g. Jan 31 -> Feb 28)
        final int targetMonth = (current.month % 12) + 1;
        final int targetYear = current.month == 12 ? current.year + 1 : current.year;
        final int daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
        final int targetDay = current.day > daysInTargetMonth ? daysInTargetMonth : current.day;
        return DateTime(targetYear, targetMonth, targetDay, current.hour, current.minute);
    }
  }
}

class RecurringTransactionsNotifier extends StreamNotifier<List<RecurringTransaction>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<RecurringTransaction>> build() {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) return Stream.value([]);
        return _db
            .collection('users')
            .doc(user.id)
            .collection('recurring_transactions')
            .orderBy('nextDueDate', descending: false)
            .snapshots()
            .map((snapshot) {
          return snapshot.docs.map((doc) => RecurringTransaction.fromMap(doc.data(), doc.id)).toList();
        });
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error loading recurring transactions: $e');
        return Stream.value([]);
      },
    );
  }

  Future<void> addRecurring(RecurringTransaction tx) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = tx.id.isNotEmpty
          ? _db.collection('users').doc(user.uid).collection('recurring_transactions').doc(tx.id)
          : _db.collection('users').doc(user.uid).collection('recurring_transactions').doc();
      await docRef.set(tx.toMap());
      await RecurringTransactionsService.processDueTransactions();
    }
  }

  Future<void> updateRecurring(RecurringTransaction tx) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && tx.id.isNotEmpty) {
      await _db.collection('users').doc(user.uid).collection('recurring_transactions').doc(tx.id).update(tx.toMap());
      await RecurringTransactionsService.processDueTransactions();
    }
  }

  Future<void> deleteRecurring(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && id.isNotEmpty) {
      await _db.collection('users').doc(user.uid).collection('recurring_transactions').doc(id).delete();
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && id.isNotEmpty) {
      await _db.collection('users').doc(user.uid).collection('recurring_transactions').doc(id).update({
        'isActive': !isActive,
      });
    }
  }
}

final recurringTransactionsProvider = StreamNotifierProvider<RecurringTransactionsNotifier, List<RecurringTransaction>>(() {
  return RecurringTransactionsNotifier();
});

class RecurringTransactionsService {
  static Future<void> processDueTransactions({bool triggerNotifications = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final db = FirebaseFirestore.instance;
      final snapshot = await db
          .collection('users')
          .doc(user.uid)
          .collection('recurring_transactions')
          .where('isActive', isEqualTo: true)
          .get();

      if (snapshot.docs.isEmpty) return;

      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final recurring = RecurringTransaction.fromMap(doc.data(), doc.id);
        DateTime currentDueDate = recurring.nextDueDate;
        DateTime? lastProcessed = recurring.lastProcessedDate;
        bool didProcess = false;
        int safetyLoop = 0;

        // While the due date is today or in the past, process the scheduled charge
        while (!currentDueDate.isAfter(now) && safetyLoop < 12) {
          safetyLoop++;

          // Build deterministic ID to prevent double billing across app opens or background runs
          final String deterministicTxId = "rec_${recurring.id}_${currentDueDate.year}_${currentDueDate.month}_${currentDueDate.day}";
          
          final txDocRef = db.collection('users').doc(user.uid).collection('finances').doc(deterministicTxId);
          final existingTx = await txDocRef.get();

          if (!existingTx.exists) {
            final transaction = Transaction(
              id: deterministicTxId,
              title: recurring.title,
              category: recurring.category,
              amount: recurring.amount,
              date: currentDueDate,
              isExpense: recurring.isExpense,
            );
            await txDocRef.set(transaction.toMap());
            didProcess = true;

            if (triggerNotifications) {
              await LocalNotificationsService.showInstantNotification(
                id: deterministicTxId.hashCode.abs() % 100000,
                title: 'Recurring ${recurring.isExpense ? 'Expense' : 'Income'} Recorded',
                body: '${recurring.title}: ₹${recurring.amount.toStringAsFixed(0)} (${recurring.category})',
              );
            }
          }

          lastProcessed = currentDueDate;
          currentDueDate = RecurringTransaction.calculateNextDueDate(currentDueDate, recurring.recurrenceInterval);
        }

        if (didProcess || lastProcessed != recurring.lastProcessedDate) {
          await db.collection('users').doc(user.uid).collection('recurring_transactions').doc(recurring.id).update({
            'lastProcessedDate': lastProcessed != null ? Timestamp.fromDate(lastProcessed) : null,
            'nextDueDate': Timestamp.fromDate(currentDueDate),
          });
          debugPrint("💰 [RECURRING TX] Advanced ${recurring.title} to next due date: $currentDueDate");
        }
      }
    } catch (e) {
      debugPrint("❌ [RECURRING TX] Error processing recurring transactions: $e");
    }
  }
}
