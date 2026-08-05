import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/auth_provider.dart';
import '../core/notifications/local_notifications_service.dart';
import 'budget_service.dart';

class Transaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String? receiptUrl;
  final String? receiptImageUrl;

  Transaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.isExpense = true,
    this.receiptUrl,
    this.receiptImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'isExpense': isExpense,
      'receiptUrl': receiptUrl ?? receiptImageUrl,
      'receiptImageUrl': receiptImageUrl ?? receiptUrl,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map, String docId) {
    return Transaction(
      id: map['id'] ?? docId,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      isExpense: map['isExpense'] ?? true,
      receiptUrl: map['receiptUrl'] as String? ?? map['receiptImageUrl'] as String?,
      receiptImageUrl: map['receiptImageUrl'] as String? ?? map['receiptUrl'] as String?,
    );
  }
}

class MoneyManagerState {
  final List<Transaction> transactions;
  final double initialBalance;
  final double totalBalance;
  final double monthlySpend;
  final double monthlyBudget;

  MoneyManagerState({
    required this.transactions,
    this.initialBalance = 0.0,
    this.totalBalance = 0.0,
    this.monthlySpend = 0.0,
    this.monthlyBudget = 20000.0,
  });

  MoneyManagerState copyWith({
    List<Transaction>? transactions,
    double? initialBalance,
    double? totalBalance,
    double? monthlySpend,
    double? monthlyBudget,
  }) {
    return MoneyManagerState(
      transactions: transactions ?? this.transactions,
      initialBalance: initialBalance ?? this.initialBalance,
      totalBalance: totalBalance ?? this.totalBalance,
      monthlySpend: monthlySpend ?? this.monthlySpend,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }
}

class MoneyManagerNotifier extends StreamNotifier<MoneyManagerState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<MoneyManagerState> build() {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value(MoneyManagerState(transactions: []));
        }

        final metadataStream = _db
            .collection('users')
            .doc(user.id)
            .collection('finances')
            .doc('--metadata--')
            .snapshots();

        final financesStream = _db
            .collection('users')
            .doc(user.id)
            .collection('finances')
            .orderBy('date', descending: true)
            .snapshots();

        final controller = StreamController<MoneyManagerState>();
        double initialBalance = 0.0;
        double monthlyBudget = 20000.0;
        List<Transaction> transactions = [];

        void update() {
          if (controller.isClosed) return;

          double totalBalance = initialBalance;
          double monthlySpend = 0.0;

          final now = DateTime.now();
          final currentMonth = now.month;
          final currentYear = now.year;

          for (var tx in transactions) {
            if (tx.isExpense) {
              totalBalance -= tx.amount;
              if (tx.date.month == currentMonth && tx.date.year == currentYear) {
                monthlySpend += tx.amount;
              }
            } else {
              totalBalance += tx.amount;
            }
          }

          if (monthlyBudget > 0) {
            final double ratio = monthlySpend / monthlyBudget;
            final settingsBox = Hive.isBoxOpen('settings_cache') ? Hive.box('settings_cache') : null;

            if (ratio >= 1.0) {
              final String alertKey = "budget_100_${now.year}_${now.month}";
              if (settingsBox != null && settingsBox.get(alertKey) != true) {
                settingsBox.put(alertKey, true);
                LocalNotificationsService.showInstantNotification(
                  id: alertKey.hashCode.abs() % 100000,
                  title: '🚨 Budget Exceeded!',
                  body: 'You have spent ₹${monthlySpend.toStringAsFixed(0)} this month, exceeding your ₹${monthlyBudget.toStringAsFixed(0)} allowance.',
                );
              }
            } else if (ratio >= 0.8) {
              final String alertKey = "budget_80_${now.year}_${now.month}";
              if (settingsBox != null && settingsBox.get(alertKey) != true) {
                settingsBox.put(alertKey, true);
                LocalNotificationsService.showInstantNotification(
                  id: alertKey.hashCode.abs() % 100000,
                  title: '⚠️ Budget Alert: 80% Reached',
                  body: 'You have spent ₹${monthlySpend.toStringAsFixed(0)} of your ₹${monthlyBudget.toStringAsFixed(0)} monthly allowance.',
                );
              }
            }
          }

          try {
            final categoryBudgets = ref.read(categoryBudgetsProvider).valueOrNull;
            if (categoryBudgets != null && categoryBudgets.isNotEmpty) {
              final Map<String, double> catSpend = {};
              for (var tx in transactions) {
                if (tx.isExpense && tx.date.month == currentMonth && tx.date.year == currentYear) {
                  catSpend[tx.category] = (catSpend[tx.category] ?? 0) + tx.amount;
                }
              }
              BudgetNotifier.evaluateCategoryAlerts(catSpend, categoryBudgets);
            }
          } catch (e) {
            debugPrint("Category budget alert evaluation error: $e");
          }

          controller.add(MoneyManagerState(
            transactions: transactions,
            initialBalance: initialBalance,
            totalBalance: totalBalance,
            monthlySpend: monthlySpend,
            monthlyBudget: monthlyBudget,
          ));
        }

        final sub1 = metadataStream.listen((doc) {
          if (doc.exists) {
            final data = doc.data() ?? {};
            initialBalance = (data['initialBalance'] ?? 0.0).toDouble();
            monthlyBudget = (data['monthlyBudget'] ?? 20000.0).toDouble();
            update();
          }
        });

        final sub2 = financesStream.listen((snapshot) {
          transactions = snapshot.docs
              .where((doc) => doc.id != '--metadata--')
              .map((doc) => Transaction.fromMap(doc.data(), doc.id))
              .toList();
          update();
        });

        ref.onDispose(() {
          sub1.cancel();
          sub2.cancel();
          controller.close();
        });

        return controller.stream;
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error loading money manager stream: $e');
        return Stream.value(MoneyManagerState(transactions: []));
      },
    );
  }

  MoneyManagerState get currentState => state.valueOrNull ?? MoneyManagerState(transactions: []);

  Future<void> addTransaction(Transaction tx) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('finances')
          .doc(tx.id)
          .set(tx.toMap());
    }
  }

  Future<void> updateInitialBalance(double balance) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).collection('finances').doc('--metadata--').set({
        'initialBalance': balance,
      }, SetOptions(merge: true));
    }
  }

  Future<void> updateMonthlyBudget(double budget) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).collection('finances').doc('--metadata--').set({
        'monthlyBudget': budget,
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteTransaction(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('finances')
          .doc(id)
          .delete();
    }
  }

  Map<String, double> getSpendByCategory() {
    Map<String, double> categories = {};
    for (var tx in currentState.transactions) {
      if (tx.isExpense) {
        categories[tx.category] = (categories[tx.category] ?? 0) + tx.amount;
      }
    }
    return categories;
  }

  Map<String, double> getMonthlySpendByCategory() {
    Map<String, double> categories = {};
    final now = DateTime.now();
    for (var tx in currentState.transactions) {
      if (tx.isExpense && tx.date.month == now.month && tx.date.year == now.year) {
        categories[tx.category] = (categories[tx.category] ?? 0) + tx.amount;
      }
    }
    return categories;
  }

  Future<String?> uploadReceiptImage(XFile imageFile, String transactionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('receipts')
          .child('$transactionId.jpg');

      final bytes = await imageFile.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading receipt image to Firebase Storage: $e');
      return null;
    }
  }
}

final moneyManagerProvider = StreamNotifierProvider<MoneyManagerNotifier, MoneyManagerState>(() {
  return MoneyManagerNotifier();
});
