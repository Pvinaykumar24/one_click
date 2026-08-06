import 'package:flutter/foundation.dart';
import 'package:googleapis/classroom/v1.dart' as classroom;
import 'google_auth_service.dart';

class ClassroomService {
  final GoogleAuthService _authService = GoogleAuthService();

  ClassroomService();

  Future<List<Map<String, dynamic>>> fetchAllAssignments() async {
    final client = await _authService.getAuthenticatedClient();
    if (client == null) {
      if (kDebugMode) {
        print('No authenticated client for Classroom');
      }
      return [];
    }

    final classroomApi = classroom.ClassroomApi(client);

    try {
      // Fix Bug #1 and #2: Fetch student courses and teacher courses separately with full pagination, then merge by course ID.
      final Map<String, classroom.Course> mergedCourses = {};

      // 1. Fetch all courses where user is enrolled as a student
      String? pageToken;
      do {
        final response = await classroomApi.courses.list(
          studentId: 'me',
          pageToken: pageToken,
        );
        if (response.courses != null) {
          for (final c in response.courses!) {
            if (c.id != null) {
              mergedCourses[c.id!] = c;
            }
          }
        }
        pageToken = response.nextPageToken;
      } while (pageToken != null && pageToken.isNotEmpty);

      // 2. Fetch all courses where user is teaching
      pageToken = null;
      do {
        final response = await classroomApi.courses.list(
          teacherId: 'me',
          pageToken: pageToken,
        );
        if (response.courses != null) {
          for (final c in response.courses!) {
            if (c.id != null) {
              mergedCourses[c.id!] = c;
            }
          }
        }
        pageToken = response.nextPageToken;
      } while (pageToken != null && pageToken.isNotEmpty);

      final courses = mergedCourses.values;
      final List<Map<String, dynamic>> allAssignments = [];

      for (final course in courses) {
        // Fetch all pages of coursework (assignments) for each individual course
        String? workPageToken;
        do {
          final courseWorkResponse = await classroomApi.courses.courseWork.list(
            course.id!,
            pageToken: workPageToken,
          );
          final courseWorks = courseWorkResponse.courseWork ?? [];

          for (final work in courseWorks) {
            final dueDate = work.dueDate;
            DateTime dueDateTime = DateTime.now().add(const Duration(days: 7)); // default
            if (dueDate != null &&
                dueDate.year != null &&
                dueDate.month != null &&
                dueDate.day != null) {
              dueDateTime = DateTime(
                dueDate.year!,
                dueDate.month!,
                dueDate.day!,
              );
            }

            String gcrStatus = 'pending';
            try {
              if (course.id != null && work.id != null) {
                final subs = await classroomApi.courses.courseWork.studentSubmissions.list(
                  course.id!,
                  work.id!,
                  userId: 'me',
                );
                final subState = subs.studentSubmissions != null && subs.studentSubmissions!.isNotEmpty
                    ? subs.studentSubmissions!.first.state
                    : null;
                if (subState == 'TURNED_IN' || subState == 'RETURNED') {
                  gcrStatus = 'completed';
                } else if (dueDateTime.isBefore(DateTime.now())) {
                  gcrStatus = 'missing';
                } else {
                  gcrStatus = 'pending';
                }
              }
            } catch (e) {
              if (dueDateTime.isBefore(DateTime.now())) {
                gcrStatus = 'missing';
              }
            }

            final assignmentMap = {
              'courseId': course.id ?? '',
              'courseName': course.name ?? '',
              'assignment': {
                'id': work.id ?? '',
                'title': work.title ?? 'Untitled Assignment',
                'description': work.description ?? '',
                'status': gcrStatus,
                'dueDate': {
                  'year': dueDateTime.year,
                  'month': dueDateTime.month,
                  'day': dueDateTime.day,
                },
              },
            };
            allAssignments.add(assignmentMap);
          }
          workPageToken = courseWorkResponse.nextPageToken;
        } while (workPageToken != null && workPageToken.isNotEmpty);
      }

      return allAssignments;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching classroom data: $e');
      }
      return [];
    } finally {
      client.close();
    }
  }
}