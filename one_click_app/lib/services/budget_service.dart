import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/auth_provider.dart';
import '../core/notifications/local_notifications_service.dart';

class Budget {
  final String category;
  final double limitAmount;

  Budget({
    required this.category,
    required this.limitAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'limitAmount': limitAmount,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map, String docId) {
    return Budget(
      category: map['category'] ?? docId,
      limitAmount: (map['limitAmount'] ?? 0.0).toDouble(),
    );
  }

  Budget copyWith({String? category, double? limitAmount}) {
    return Budget(
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
    );
  }
}

class BudgetNotifier extends StreamNotifier<Map<String, Budget>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<Map<String, Budget>> build() {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value({});
        }

        final budgetsStream = _db
            .collection('users')
            .doc(user.id)
            .collection('budgets')
            .snapshots();

        return budgetsStream.map((snapshot) {
          final Map<String, Budget> budgets = {};
          for (var doc in snapshot.docs) {
            final b = Budget.fromMap(doc.data(), doc.id);
            budgets[b.category] = b;
          }
          return budgets;
        }).handleError((e) {
          debugPrint("Error loading category budgets stream: $e");
          return <String, Budget>{};
        });
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint("Error in budget provider auth state: $e");
        return Stream.value({});
      },
    );
  }

  Future<void> setBudget(String category, double limitAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(category)
          .set({
        'category': category,
        'limitAmount': limitAmount,
      });
    }
  }

  Future<void> deleteBudget(String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('budgets')
          .doc(category)
          .delete();
    }
  }

  static void evaluateCategoryAlerts(
    Map<String, double> categorySpends,
    Map<String, Budget> budgets, [
    Box? providedBox,
    bool triggerNotification = true,
  ]) {
    final now = DateTime.now();
    final box = providedBox ?? (Hive.isBoxOpen('settings_cache') ? Hive.box('settings_cache') : null);

    for (var entry in budgets.entries) {
      final category = entry.key;
      final limit = entry.value.limitAmount;
      if (limit <= 0) continue;

      final spend = categorySpends[category] ?? 0.0;
      final ratio = spend / limit;

      if (ratio >= 1.0) {
        final key100 = "cat_100_${category}_${now.year}_${now.month}";
        if (box == null || box.get(key100) != true) {
          box?.put(key100, true);
          if (triggerNotification) {
            LocalNotificationsService.showInstantNotification(
              id: key100.hashCode.abs() % 100000,
              title: '🚨 $category Budget Exceeded!',
              body: "You have spent ₹${spend.toStringAsFixed(0)} this month against your ₹${limit.toStringAsFixed(0)} limit for $category.",
            );
          }
        }
      } else if (ratio >= 0.8) {
        final key80 = "cat_80_${category}_${now.year}_${now.month}";
        if (box == null || box.get(key80) != true) {
          box?.put(key80, true);
          if (triggerNotification) {
            LocalNotificationsService.showInstantNotification(
              id: key80.hashCode.abs() % 100000,
              title: '⚠️ $category Budget Alert: 80% Reached',
              body: "You have spent ₹${spend.toStringAsFixed(0)} of your ₹${limit.toStringAsFixed(0)} monthly allowance for $category.",
            );
          }
        }
      }
    }
  }
}

final categoryBudgetsProvider = StreamNotifierProvider<BudgetNotifier, Map<String, Budget>>(() {
  return BudgetNotifier();
});
