import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'institution_service.dart';
import 'onboarding_service.dart';

class AcademicEvent {
  final String id;
  final String title;
  final DateTime date;
  final String description;
  final String type; // 'exam', 'holiday', 'event'
  final IconData icon;
  final Color color;

  AcademicEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.type,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'date': Timestamp.fromDate(date),
    'description': description,
    'type': type,
  };

  factory AcademicEvent.fromMap(String id, Map<String, dynamic> map) {
    String type = map['type'] ?? 'event';
    DateTime date = DateTime.now();
    if (map['date'] is Timestamp) {
      date = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      date = DateTime.tryParse(map['date']) ?? DateTime.now();
    }

    return AcademicEvent(
      id: id,
      title: map['title'] ?? '',
      date: date,
      description: map['description'] ?? '',
      type: type,
      icon: _getIconForType(type),
      color: _getColorForType(type),
    );
  }

  static IconData _getIconForType(String type) {
    switch (type) {
      case 'exam':
        return Icons.assignment_late;
      case 'holiday':
        return Icons.beach_access;
      default:
        return Icons.event;
    }
  }

  static Color _getColorForType(String type) {
    switch (type) {
      case 'exam':
        return Colors.red;
      case 'holiday':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}

class EventsNotifier extends StreamNotifier<List<AcademicEvent>> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<AcademicEvent>> build() {
    final authState = ref.watch(authProvider);
    final institution = ref.watch(institutionProvider).valueOrNull;
    final collegeId = institution?.collegeId ?? 'iiitdm';

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value(<AcademicEvent>[]);
        }
        return _db
            .collection('institutions')
            .doc(collegeId)
            .collection('events')
            .orderBy('date')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => AcademicEvent.fromMap(doc.id, doc.data()))
                .toList());
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error loading events stream: $e');
        return Stream.value(<AcademicEvent>[]);
      },
    );
  }

  List<AcademicEvent> get events => state.valueOrNull ?? [];

  Future<void> addEvent(AcademicEvent event) async {
    final eventMap = event.toMap();
    final institution = ref.read(institutionProvider).valueOrNull;
    final onboardingState = ref.read(onboardingProvider).valueOrNull;
    final collegeId = institution?.collegeId ?? (onboardingState?.userData['collegeId'] as String?) ?? 'iiitdm';
    eventMap['collegeId'] = collegeId;
    await _db
        .collection('institutions')
        .doc(collegeId)
        .collection('events')
        .add(eventMap);
  }

  Future<void> deleteEvent(String id) async {
    final institution = ref.read(institutionProvider).valueOrNull;
    final collegeId = institution?.collegeId ?? 'iiitdm';
    await _db
        .collection('institutions')
        .doc(collegeId)
        .collection('events')
        .doc(id)
        .delete();
  }
}

final eventsProvider = StreamNotifierProvider<EventsNotifier, List<AcademicEvent>>(() {
  return EventsNotifier();
});
