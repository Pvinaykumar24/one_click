import 'package:flutter_test/flutter_test.dart';
import 'package:one_click_app/models/institution.dart';

void main() {
  group('Institution Model & Attendance Threshold Fallback Tests', () {
    test('uses kFallbackAttendanceThreshold (75.0%) when attendanceThreshold field is missing or null', () {
      final institution = Institution.fromMap(
        {
          'displayName': 'Test Institute',
        },
        'test-institute',
      );

      expect(institution.attendanceThreshold, kFallbackAttendanceThreshold);
      expect(institution.attendanceThreshold, 75.0);
    });

    test('honors explicit attendanceThreshold when present in map', () {
      final institution = Institution.fromMap(
        {
          'displayName': 'Custom Institute',
          'attendanceThreshold': 85.0,
        },
        'custom-institute',
      );

      expect(institution.attendanceThreshold, 85.0);
    });

    test('correctly maps lower custom attendance thresholds (e.g. 70.0%)', () {
      final institution = Institution.fromMap(
        {
          'displayName': 'Lenient University',
          'attendanceThreshold': 70,
        },
        'lenient-uni',
      );

      expect(institution.attendanceThreshold, 70.0);
    });
  });

  group('GradingScale Strategy & Conversion Tests', () {
    test('kDefaultGradingScale (letter_10pt) converts points correctly and acts as fallback', () {
      expect(kDefaultGradingScale.getGradeLetter(10.0), 'S');
      expect(kDefaultGradingScale.getGradeLetter(9.0), 'S');
      expect(kDefaultGradingScale.getGradeLetter(8.5), 'A');
      expect(kDefaultGradingScale.getGradeLetter(4.0), 'E');
      expect(kDefaultGradingScale.getGradeLetter(3.5), 'F');
      expect(kDefaultGradingScale.maxPoints, 10.0);
    });

    test('gpa_4pt scale uses standard 4.0 defaults when fields missing in fromMap', () {
      final scale = GradingScale.fromMap({'type': 'gpa_4pt'});
      expect(scale.maxPoints, 4.0);
      expect(scale.passingPoint, 1.0);
      expect(scale.getGradeLetter(4.0), 'A');
      expect(scale.getGradeLetter(3.3), 'B');
      expect(scale.defaultSubjectGradePoint, 3.0);
    });

    test('percentage scale formats numbers as percentage string', () {
      final scale = GradingScale.fromMap({'type': 'percentage'});
      expect(scale.maxPoints, 100.0);
      expect(scale.passingPoint, 40.0);
      expect(scale.getGradeLetter(85.3), '85%');
      expect(scale.defaultSubjectGradePoint, 80.0);
    });
  });

  group('Curriculum & Sample Course Code Fallbacks', () {
    test('uses fallback lists when sampleTimetableCodes, departments, or degreeTypes are empty/missing', () {
      final institution = Institution.fromMap(
        {'displayName': 'Generic College'},
        'generic-college',
      );

      expect(institution.sampleTimetableCodes, kFallbackSampleTimetableCodes);
      expect(institution.departments, kFallbackDepartments);
      expect(institution.degreeTypes, kFallbackDegreeTypes);
    });

    test('honors custom curriculum values when provided in map', () {
      final customCodes = ['CS101', 'PHY102', 'MATH201'];
      final customDepts = ['Arts', 'Science', 'Law'];
      final customDegrees = ['B.Sc', 'M.Sc', 'Ph.D'];

      final institution = Institution.fromMap(
        {
          'displayName': 'Arts & Science Uni',
          'sampleTimetableCodes': customCodes,
          'departments': customDepts,
          'degreeTypes': customDegrees,
        },
        'arts-uni',
      );

      expect(institution.sampleTimetableCodes, customCodes);
      expect(institution.departments, customDepts);
      expect(institution.degreeTypes, customDegrees);
    });
  });
}
