import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:one_click_app/services/assignment_service.dart';

void main() {
  group('Assignment Model Tests', () {
    final sampleDate = DateTime(2026, 8, 10);

    test('toMap includes classroomId and isDeleted fields', () {
      final assignment = Assignment(
        id: 'doc1',
        title: 'Math Homework',
        course: 'Mathematics',
        dueDate: sampleDate,
        status: 'pending',
        description: 'Complete calculus problems',
        classroomId: 'cw_12345',
        isDeleted: false,
      );

      final map = assignment.toMap();

      expect(map['title'], 'Math Homework');
      expect(map['course'], 'Mathematics');
      expect(map['classroomId'], 'cw_12345');
      expect(map['isDeleted'], false);
      expect((map['dueDate'] as Timestamp).toDate(), sampleDate);
    });

    test('fromMap correctly parses classroomId and defaults isDeleted to false when missing', () {
      final map = {
        'title': 'Physics Lab Report',
        'course': 'Physics',
        'dueDate': Timestamp.fromDate(sampleDate),
        'status': 'completed',
        'description': 'Write lab report',
        'classroomId': 'cw_98765',
      };

      final assignment = Assignment.fromMap(map, 'doc2');

      expect(assignment.id, 'doc2');
      expect(assignment.title, 'Physics Lab Report');
      expect(assignment.classroomId, 'cw_98765');
      expect(assignment.isDeleted, false);
    });

    test('fromMap correctly parses explicit isDeleted = true', () {
      final map = {
        'title': 'Old Assignment',
        'course': 'History',
        'dueDate': Timestamp.fromDate(sampleDate),
        'status': 'missing',
        'description': '',
        'classroomId': 'cw_old',
        'isDeleted': true,
      };

      final assignment = Assignment.fromMap(map, 'doc3');

      expect(assignment.isDeleted, true);
    });

    test('copyWith updates fields without altering existing attributes', () {
      final orig = Assignment(
        id: 'doc4',
        title: 'Draft Project',
        course: 'Computer Science',
        dueDate: sampleDate,
        status: 'pending',
        description: 'Initial draft',
        classroomId: 'cw_cs101',
        isDeleted: false,
      );

      final modified = orig.copyWith(
        title: 'Final Project',
        status: 'completed',
      );

      expect(modified.id, 'doc4');
      expect(modified.title, 'Final Project');
      expect(modified.status, 'completed');
      expect(modified.course, 'Computer Science');
      expect(modified.classroomId, 'cw_cs101');
      expect(modified.isDeleted, false);
    });
  });
}
