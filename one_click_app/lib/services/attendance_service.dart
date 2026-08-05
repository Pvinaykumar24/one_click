import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/institution.dart';
import 'institution_service.dart';
import 'timetable_service.dart';

class AttendanceRecord {
  final String id;
  final String subject;
  final DateTime date;
  final String slot; // e.g. "09:00-09:50"
  String status; // 'present', 'absent', 'cancelled'

  AttendanceRecord({
    required this.id,
    required this.subject,
    required this.date,
    required this.slot,
    this.status = 'present',
  });

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'date': Timestamp.fromDate(date),
      'slot': slot,
      'status': status,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map, String docId) {
    return AttendanceRecord(
      id: docId,
      subject: map['subject'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      slot: map['slot'] ?? '',
      status: map['status'] ?? 'present',
    );
  }
}

class AttendanceNotifier extends StreamNotifier<List<AttendanceRecord>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  /// Returns the required attendance percentage from the user's institution config.
  /// Falls back to [kFallbackAttendanceThreshold] (75.0%) if institution config is unloaded or missing.
  double get requiredPercentage {
    final institution = ref.read(institutionProvider).valueOrNull;
    return institution?.attendanceThreshold ?? kFallbackAttendanceThreshold;
  }

  @override
  Stream<List<AttendanceRecord>> build() {
    ref.watch(timetableProvider); // Automatically rebuilds when timetable changes
    ref.watch(institutionProvider); // Automatically rebuilds when institution config changes

    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value(<AttendanceRecord>[]);
        }
        return _db
            .collection('users')
            .doc(user.id)
            .collection('attendance')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => AttendanceRecord.fromMap(doc.data(), doc.id))
                .toList());
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error loading attendance stream: $e');
        return Stream.value(<AttendanceRecord>[]);
      },
    );
  }

  List<AttendanceRecord> get records => state.valueOrNull ?? [];

  List<String> get subjects {
    final slots = ref.read(timetableProvider.notifier).slots;
    return slots.map((s) => s.subject).toSet().toList()..sort();
  }

  Map<String, int> get expectedClasses {
    Map<String, int> counts = {};
    final slots = ref.read(timetableProvider.notifier).slots;
    for (var subject in subjects) {
      int sessionsPerWeek = slots.where((s) => s.subject == subject).length;
      counts[subject] = sessionsPerWeek * 15; // Assume 15 week semester
    }
    return counts;
  }

  Future<void> _updateAttendanceStatus(String subject, DateTime date, String slot, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final currentRecords = records;
    var existing = currentRecords.where((r) => r.subject == subject && _isSameDay(r.date, date) && r.slot == slot);
    if (existing.isEmpty) {
      await _db.collection('users').doc(user.uid).collection('attendance').doc().set({
        'subject': subject,
        'date': Timestamp.fromDate(date),
        'slot': slot,
        'status': status,
      });
    } else {
      await _db.collection('users').doc(user.uid).collection('attendance').doc(existing.first.id).update({'status': status});
    }
  }

  Future<void> markAttended(String subject, DateTime date, String slot) async {
    await _updateAttendanceStatus(subject, date, slot, 'present');
  }

  Future<void> markAbsent(String subject, DateTime date, String slot) async {
    await _updateAttendanceStatus(subject, date, slot, 'absent');
  }

  Future<void> markCancelled(String subject, DateTime date, String slot) async {
    await _updateAttendanceStatus(subject, date, slot, 'cancelled');
  }

  Future<void> updatePreviousAttendance(String subject, DateTime date, String slot, bool wasPresent) async {
    if (wasPresent) {
      await markAttended(subject, date, slot);
    } else {
      await markAbsent(subject, date, slot);
    }
  }

  Map<String, dynamic> getSubjectInfo(String subject) {
    final currentRecords = records;
    var subjectRecords = currentRecords.where((r) => r.subject == subject).toList();
    int held = subjectRecords.where((r) => r.status != 'cancelled').length;
    int attended = subjectRecords.where((r) => r.status == 'present').length;
    int cancelled = subjectRecords.where((r) => r.status == 'cancelled').length;
    int absent = subjectRecords.where((r) => r.status == 'absent').length;
    int expected = expectedClasses[subject] ?? 45;

    double currentPercentage = held > 0 ? (attended / held) * 100 : 100.0;

    int remainingClasses = expected - held - cancelled;
    int totalAfterSemester = held + remainingClasses;
    int requiredTotal = (totalAfterSemester * (requiredPercentage / 100)).ceil();
    int safeBunksLeft = attended + remainingClasses - requiredTotal;

    return {
      'held': held,
      'attended': attended,
      'absent': absent,
      'cancelled': cancelled,
      'expected': expected,
      'remaining': remainingClasses,
      'currentPercentage': currentPercentage,
      'safeBunksLeft': safeBunksLeft > 0 ? safeBunksLeft : 0,
      'needsRecovery': safeBunksLeft < 0,
      'recoveryClasses': safeBunksLeft < 0 ? -safeBunksLeft : 0,
      'requiredPercentage': requiredPercentage,
    };
  }

  List<AttendanceRecord> getSubjectRecords(String subject) {
    final currentRecords = records;
    return currentRecords.where((r) => r.subject == subject).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  double getOverallPercentage() {
    int totalHeld = 0;
    int totalAttended = 0;
    for (var sub in subjects) {
      var info = getSubjectInfo(sub);
      totalHeld += info['held'] as int;
      totalAttended += info['attended'] as int;
    }
    return totalHeld > 0 ? (totalAttended / totalHeld) * 100 : 100.0;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

final attendanceProvider = StreamNotifierProvider<AttendanceNotifier, List<AttendanceRecord>>(() {
  return AttendanceNotifier();
});
