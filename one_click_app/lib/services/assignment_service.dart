import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../core/notifications/local_notifications_service.dart';
import 'classroom_service.dart';

class Assignment {
  final String id;
  final String title;
  final String course;
  final DateTime dueDate;
  final String status; // 'pending', 'completed', 'missing'
  final String description;
  final String? classroomId;
  final bool isDeleted;

  Assignment({
    required this.id,
    required this.title,
    required this.course,
    required this.dueDate,
    required this.status,
    required this.description,
    this.classroomId,
    this.isDeleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'course': course,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'description': description,
      'classroomId': classroomId,
      'isDeleted': isDeleted,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map, String docId) {
    return Assignment(
      id: docId,
      title: map['title'] ?? '',
      course: map['course'] ?? '',
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      status: map['status'] ?? 'pending',
      description: map['description'] ?? '',
      classroomId: map['classroomId'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }

  Assignment copyWith({
    String? id,
    String? title,
    String? course,
    DateTime? dueDate,
    String? status,
    String? description,
    String? classroomId,
    bool? isDeleted,
  }) {
    return Assignment(
      id: id ?? this.id,
      title: title ?? this.title,
      course: course ?? this.course,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      description: description ?? this.description,
      classroomId: classroomId ?? this.classroomId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class AssignmentState {
  final List<Assignment> assignments;
  final bool isSyncing;

  AssignmentState({
    required this.assignments,
    this.isSyncing = false,
  });

  AssignmentState copyWith({
    List<Assignment>? assignments,
    bool? isSyncing,
  }) {
    return AssignmentState(
      assignments: assignments ?? this.assignments,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class AssignmentNotifier extends StreamNotifier<AssignmentState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ClassroomService _classroomService = ClassroomService();

  @override
  Stream<AssignmentState> build() {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value(AssignmentState(assignments: []));
        }
        return _db
            .collection('users')
            .doc(user.id)
            .collection('assignments')
            .orderBy('dueDate')
            .snapshots()
            .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => Assignment.fromMap(doc.data(), doc.id))
              .where((a) => !a.isDeleted)
              .toList();
          final wasSyncing = state.valueOrNull?.isSyncing ?? false;
          return AssignmentState(assignments: list, isSyncing: wasSyncing);
        });
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error loading assignments stream: $e');
        return Stream.value(AssignmentState(assignments: []));
      },
    );
  }

  AssignmentState get currentState => state.valueOrNull ?? AssignmentState(assignments: []);

  Future<void> addAssignment(Assignment assignment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).collection('assignments').add(assignment.toMap());
    } catch (e) {
      debugPrint('Error adding assignment: $e');
    }
  }

  Future<void> updateAssignmentStatus(String id, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).collection('assignments').doc(id).update({
        'status': status,
      });
    } catch (e) {
      debugPrint('Error updating assignment status: $e');
    }
  }

  Future<void> deleteAssignment(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).collection('assignments').doc(id).delete();
    } catch (e) {
      debugPrint('Error deleting assignment: $e');
    }
  }

  Future<void> syncWithClassroom({bool isBackground = false, bool triggerNotifications = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!isBackground) {
      try {
        state = AsyncValue.data(currentState.copyWith(isSyncing: true));
      } catch (_) {}
    }

    try {
      final classroomData = await _classroomService.fetchAllAssignments();
      final existingSnapshot = await _db.collection('users').doc(user.uid).collection('assignments').get();
      final existingAssignments = existingSnapshot.docs.map((d) => Assignment.fromMap(d.data(), d.id)).toList();
      final List<String> fetchedClassroomIds = [];

      for (var item in classroomData) {
        final courseName = item['courseName'] as String? ?? '';
        final cw = item['assignment'] as Map<String, dynamic>? ?? {};
        final cwId = cw['id'] as String? ?? '';
        if (cwId.isNotEmpty) {
          fetchedClassroomIds.add(cwId);
        }

        DateTime dueDate = DateTime.now().add(const Duration(days: 7));
        final dueDateMap = cw['dueDate'] as Map<String, dynamic>?;
        if (dueDateMap != null) {
          final y = dueDateMap['year'] as int?;
          final m = dueDateMap['month'] as int?;
          final d = dueDateMap['day'] as int?;
          if (y != null && m != null && d != null) {
            dueDate = DateTime(y, m, d);
          }
        }

        final newTitle = cw['title'] as String? ?? 'Untitled Assignment';
        final newDesc = cw['description'] as String? ?? '';

        // Match on stable Classroom ID first; fall back to (title, course) for legacy un-migrated assignments
        Assignment? match;
        try {
          match = existingAssignments.firstWhere((a) => (a.classroomId != null && a.classroomId == cwId) ||
              (a.classroomId == null && a.title == newTitle && a.course == courseName));
        } catch (_) {
          match = null;
        }

        if (match != null) {
          // Check if due date, title, description, or missing classroomId changed
          final bool changed = match.classroomId != cwId ||
              match.title != newTitle ||
              match.description != newDesc ||
              match.dueDate.year != dueDate.year ||
              match.dueDate.month != dueDate.month ||
              match.dueDate.day != dueDate.day ||
              match.isDeleted; // un-delete if re-appeared!

          if (changed && match.id.isNotEmpty) {
            await _db.collection('users').doc(user.uid).collection('assignments').doc(match.id).update({
              'classroomId': cwId,
              'title': newTitle,
              'description': newDesc,
              'dueDate': Timestamp.fromDate(dueDate),
              'isDeleted': false,
            });
            if (triggerNotifications && (match.dueDate.year != dueDate.year || match.dueDate.month != dueDate.month || match.dueDate.day != dueDate.day)) {
              await LocalNotificationsService.showInstantNotification(
                id: newTitle.hashCode.abs() % 100000,
                title: 'Assignment Due Date Updated',
                body: '$courseName: $newTitle moved to ${dueDate.day}/${dueDate.month}',
              );
            }
          }
        } else {
          final assignment = Assignment(
            id: '',
            title: newTitle,
            course: courseName,
            dueDate: dueDate,
            status: 'pending',
            description: newDesc,
            classroomId: cwId.isNotEmpty ? cwId : null,
            isDeleted: false,
          );
          await addAssignment(assignment);
          existingAssignments.add(assignment);
          if (triggerNotifications) {
            await LocalNotificationsService.showInstantNotification(
              id: newTitle.hashCode.abs() % 100000,
              title: 'New Classroom Assignment',
              body: '$courseName: $newTitle',
            );
            try {
              await _db.collection('users').doc(user.uid).collection('notifications').add({
                'title': 'New Classroom Assignment',
                'body': '$courseName: $newTitle',
                'type': 'academic',
                'timestamp': FieldValue.serverTimestamp(),
                'isRead': false,
              });
            } catch (e) {
              debugPrint('Failed to save assignment notification to feed: $e');
            }
          }
        }
      }

      // Soft-delete local Classroom assignments whose ID was not returned in the fresh sync
      for (final existing in existingAssignments) {
        if (existing.classroomId != null &&
            existing.classroomId!.isNotEmpty &&
            !existing.isDeleted &&
            !fetchedClassroomIds.contains(existing.classroomId) &&
            existing.id.isNotEmpty) {
          try {
            await _db.collection('users').doc(user.uid).collection('assignments').doc(existing.id).update({
              'isDeleted': true,
            });
            debugPrint('🗑️ [SYNC] Soft-deleted assignment missing from Classroom: ${existing.title}');
          } catch (e) {
            debugPrint('Failed to soft-delete assignment ${existing.id}: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
    } finally {
      if (!isBackground) {
        try {
          state = AsyncValue.data(currentState.copyWith(isSyncing: false));
        } catch (_) {}
      }
    }
  }
}

final assignmentProvider = StreamNotifierProvider<AssignmentNotifier, AssignmentState>(() {
  return AssignmentNotifier();
});