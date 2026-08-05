import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/timetable_slot.dart';
import '../providers/auth_provider.dart';
import '../core/cache/local_cache_service.dart';

/// Carries freshness metadata for the timetable — kept separate from the main
/// provider so no consuming widget needs to change its `data: (slots)` call.
class TimetableCacheMeta {
  final bool fromCache;
  final DateTime? lastUpdated;
  const TimetableCacheMeta({this.fromCache = false, this.lastUpdated});
}

class TimetableNotifier extends StreamNotifier<List<TimetableSlot>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<TimetableSlot>> build() {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value(<TimetableSlot>[]);
        }

        // ── 1. Seed from Hive cache immediately (before Firestore fires) ───────
        Future.microtask(() {
          if (state is AsyncLoading) {
            final cached = LocalCacheService.readTimetable(user.id);
            if (cached != null) {
              state = AsyncData(cached.slots);
              // Update the sidecar meta provider
              ref.read(_timetableCacheMetaNotifierProvider.notifier).state =
                  TimetableCacheMeta(
                    fromCache: true,
                    lastUpdated: cached.lastUpdated,
                  );
            }
          }
        });

        // ── 2. Attach Firestore stream ───────────────────────────────────────
        return _db
            .collection('users')
            .doc(user.id)
            .collection('timetable')
            .snapshots()
            .asyncMap((snapshot) async {
          final slots = snapshot.docs
              .map((doc) => TimetableSlot.fromMap(doc.data(), doc.id))
              .toList();

          // ── 3. Write back to Hive cache + clear cached indicator ──────────
          LocalCacheService.writeTimetable(user.id, slots);
          ref.read(_timetableCacheMetaNotifierProvider.notifier).state =
              TimetableCacheMeta(
                fromCache: false,
                lastUpdated: DateTime.now(),
              );

          return slots;
        });
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error loading timetable stream: $e');
        return Stream.value(<TimetableSlot>[]);
      },
    );
  }

  List<TimetableSlot> get slots => state.valueOrNull ?? [];

  List<String> get allSubjects {
    return slots.map((s) => s.subject).toSet().toList();
  }

  Future<void> addSlot(Map<String, dynamic> slotData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).collection('timetable').add(slotData);
    }
  }

  Future<void> addSlots(List<Map<String, dynamic>> slotsData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final batch = _db.batch();
      for (var slot in slotsData) {
        final docRef = _db.collection('users').doc(user.uid).collection('timetable').doc();
        batch.set(docRef, slot);
      }
      await batch.commit();
    }
  }

  Future<void> deleteSlot(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).collection('timetable').doc(id).delete();
    }
  }

  List<TimetableSlot> getClassesForDay(int weekday) {
    return slots.where((slot) => slot.day == weekday).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  Map<String, dynamic> getUpcomingClassesAndDay(DateTime now) {
    List<TimetableSlot> todayClasses = getClassesForDay(now.weekday);
    String currentTimeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    List<TimetableSlot> remainingToday = todayClasses.where((cls) => currentTimeStr.compareTo(cls.start) < 0).toList();
    if (remainingToday.isNotEmpty) {
      return {'dayName': 'Today', 'classes': remainingToday};
    }
    
    for (int i = 1; i <= 7; i++) {
        int nextDay = (now.weekday + i - 1) % 7 + 1;
        List<TimetableSlot> futureClasses = getClassesForDay(nextDay);
        if (futureClasses.isNotEmpty) {
           String dayName = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][nextDay - 1];
           if (i == 1) dayName = 'Tomorrow';
           return {'dayName': dayName, 'classes': futureClasses};
        }
    }
    
    return {'dayName': 'No Classes Scheduled', 'classes': <TimetableSlot>[]};
  }

  TimetableSlot? getNextClass(DateTime now) {
      var upcoming = getUpcomingClassesAndDay(now);
      var classes = upcoming['classes'] as List<TimetableSlot>;
      if (classes.isNotEmpty) return classes.first;
      return null;
  }
}

final timetableProvider = StreamNotifierProvider<TimetableNotifier, List<TimetableSlot>>(() {
  return TimetableNotifier();
});

/// Internal state notifier for cache metadata — not exposed directly;
/// use [timetableCacheMetaProvider] for read-only access.
final _timetableCacheMetaNotifierProvider =
    StateProvider<TimetableCacheMeta>((ref) => const TimetableCacheMeta());

/// Read-only sidecar provider that carries [TimetableCacheMeta].
/// Widgets can watch this to show a freshness indicator without changing
/// how they consume the main [timetableProvider].
final timetableCacheMetaProvider = Provider<TimetableCacheMeta>((ref) {
  return ref.watch(_timetableCacheMetaNotifierProvider);
});
