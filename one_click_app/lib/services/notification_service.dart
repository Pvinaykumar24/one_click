import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timetable_slot.dart';
import '../providers/auth_provider.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'class', 'meal', 'attendance', 'academic', 'general'
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, String docId) {
    return AppNotification(
      id: docId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'general',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }
}

class NotificationNotifier extends StreamNotifier<List<AppNotification>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<AppNotification>> build() {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value(<AppNotification>[]);
        }
        return _db
            .collection('users')
            .doc(user.id)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => AppNotification.fromMap(doc.data(), doc.id))
                .toList());
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error loading notifications stream: $e');
        return Stream.value(<AppNotification>[]);
      },
    );
  }

  List<AppNotification> get notifications => state.valueOrNull ?? [];

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bool exists = notifications.any((n) =>
          n.title == title &&
          n.body == body &&
          DateTime.now().difference(n.timestamp).inMinutes < 60);

      if (!exists) {
        await _db
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add({
          'title': title,
          'body': body,
          'type': type,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }

  Future<void> markAllRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final unreadDocs = notifications.where((n) => !n.isRead).toList();
    if (unreadDocs.isEmpty) return;

    final batch = _db.batch();
    for (var doc in unreadDocs) {
      final docRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(doc.id);
      batch.update(docRef, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> refresh(TimetableSlot? nextClass) async {
    final now = DateTime.now();

    if (nextClass != null) {
      String start = nextClass.start;
      int startHour = int.parse(start.split(':')[0]);
      int startMin = int.parse(start.split(':')[1]);
      DateTime classStart =
          DateTime(now.year, now.month, now.day, startHour, startMin);
      bool isTodaySlot = nextClass.day == now.weekday;

      if (isTodaySlot) {
        bool isLive = now.isAfter(classStart) &&
            now.isBefore(classStart
                .add(const Duration(hours: 1)));
        if (isLive) {
          await addNotification(
            title: '${nextClass.subject} is LIVE',
            body: 'Class in Room ${nextClass.room} is happening now!',
            type: 'class',
          );
        } else {
          int minsUntil = classStart.difference(now).inMinutes;
          if (minsUntil > 0 && minsUntil <= 30) {
            await addNotification(
              title: '${nextClass.subject} starts in $minsUntil min',
              body: 'Room ${nextClass.room} • ${nextClass.type}',
              type: 'class',
            );
          }
        }
      }
    }

    double currentTime = now.hour + now.minute / 60.0;
    if (currentTime >= 6.5 && currentTime < 7.0) {
      await addNotification(
          title: 'Breakfast Starting Soon',
          body: 'Mess opens at 7:00 AM',
          type: 'meal');
    } else if (currentTime >= 11.5 && currentTime < 12.0) {
      await addNotification(
          title: 'Lunch Starting Soon',
          body: 'Lunch service begins at 12:00 PM',
          type: 'meal');
    } else if (currentTime >= 16.25 && currentTime < 16.75) {
      await addNotification(
          title: 'Snacks Time',
          body: 'Snacks available 4:45 – 6:00 PM',
          type: 'meal');
    } else if (currentTime >= 18.5 && currentTime < 19.0) {
      await addNotification(
          title: 'Dinner Starting Soon',
          body: 'Dinner service at 7:00 PM',
          type: 'meal');
    }
  }
}

final notificationProvider = StreamNotifierProvider<NotificationNotifier, List<AppNotification>>(() {
  return NotificationNotifier();
});
