import 'package:cloud_firestore/cloud_firestore.dart';

/// Fallback attendance threshold (in percentage) used when an institution's
/// document is missing, unassigned, or not yet loaded from Firestore.
/// 75.0% is used as a safe default, matching most Indian university requirements.
const double kFallbackAttendanceThreshold = 75.0;

/// Fallback sample timetable codes used when an institution config is not yet loaded or empty.
const List<String> kFallbackSampleTimetableCodes = ['TOC', 'P&S', 'DBS', 'COA', 'COAP'];

/// Fallback departments used during onboarding when institution config is unloaded or empty.
const List<String> kFallbackDepartments = ['CSE', 'ECE', 'ME', 'CE', 'EE', 'BIO', 'DS'];

/// Fallback degree types used during onboarding when institution config is unloaded or empty.
const List<String> kFallbackDegreeTypes = ['B.Tech', 'M.Tech', 'Dual Degree'];

enum GradingScaleType {
  letter10pt,
  gpa4pt,
  percentage,
}

/// Default IIITDM 10-point letter grading scale used when institution config is unloaded or missing.
const GradingScale kDefaultGradingScale = GradingScale(
  type: GradingScaleType.letter10pt,
  maxPoints: 10.0,
  passingPoint: 4.0,
  letterMap: {
    'S': 9.0,
    'A': 8.0,
    'B': 7.0,
    'C': 6.0,
    'D': 5.0,
    'E': 4.0,
    'F': 0.0,
  },
);

class GradingScale {
  final GradingScaleType type;
  final double maxPoints;
  final double passingPoint;
  final Map<String, double> letterMap;

  const GradingScale({
    required this.type,
    required this.maxPoints,
    required this.passingPoint,
    required this.letterMap,
  });

  /// Converts a grade point into a string display representation (letter or percentage).
  String getGradeLetter(double gradePoint) {
    if (type == GradingScaleType.percentage) {
      return '${gradePoint.toStringAsFixed(0)}%';
    }
    if (letterMap.isNotEmpty) {
      final entries = letterMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in entries) {
        if (gradePoint >= entry.value - 0.01) {
          return entry.key;
        }
      }
    }
    return 'F';
  }

  /// Default grade point when adding a new subject or importing from timetable.
  double get defaultSubjectGradePoint {
    switch (type) {
      case GradingScaleType.gpa4pt:
        return 3.0;
      case GradingScaleType.percentage:
        return 80.0;
      case GradingScaleType.letter10pt:
        return 8.0;
    }
  }

  /// Default SGPA when adding a new past semester.
  double get defaultSemesterSgpa {
    switch (type) {
      case GradingScaleType.gpa4pt:
        return 3.5;
      case GradingScaleType.percentage:
        return 85.0;
      case GradingScaleType.letter10pt:
        return 8.5;
    }
  }

  /// Default target CGPA for new users or fallback.
  double get defaultTargetCgpa {
    switch (type) {
      case GradingScaleType.gpa4pt:
        return 4.0;
      case GradingScaleType.percentage:
        return 95.0;
      case GradingScaleType.letter10pt:
        return 10.0;
    }
  }

  /// Default target SGPA for new users or fallback.
  double get defaultTargetSgpa {
    switch (type) {
      case GradingScaleType.gpa4pt:
        return 3.5;
      case GradingScaleType.percentage:
        return 90.0;
      case GradingScaleType.letter10pt:
        return 9.0;
    }
  }

  factory GradingScale.fromMap(Map<String, dynamic> map) {
    GradingScaleType parseType(String? val) {
      switch (val) {
        case 'gpa_4pt':
          return GradingScaleType.gpa4pt;
        case 'percentage':
          return GradingScaleType.percentage;
        case 'letter_10pt':
        default:
          return GradingScaleType.letter10pt;
      }
    }

    final scaleType = parseType(map['type'] as String?);
    final rawMap = map['letterMap'] as Map<String, dynamic>? ?? {};
    final letterMap = rawMap.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    double defaultMax = 10.0;
    double defaultPassing = 4.0;
    Map<String, double> defaultLetters = const {
      'S': 9.0,
      'A': 8.0,
      'B': 7.0,
      'C': 6.0,
      'D': 5.0,
      'E': 4.0,
      'F': 0.0,
    };

    if (scaleType == GradingScaleType.gpa4pt) {
      defaultMax = 4.0;
      defaultPassing = 1.0;
      defaultLetters = const {'A': 4.0, 'B': 3.0, 'C': 2.0, 'D': 1.0, 'F': 0.0};
    } else if (scaleType == GradingScaleType.percentage) {
      defaultMax = 100.0;
      defaultPassing = 40.0;
      defaultLetters = const {};
    }

    return GradingScale(
      type: scaleType,
      maxPoints: (map['maxPoints'] ?? defaultMax).toDouble(),
      passingPoint: (map['passingPoint'] ?? defaultPassing).toDouble(),
      letterMap: letterMap.isNotEmpty ? letterMap : defaultLetters,
    );
  }

  Map<String, dynamic> toMap() {
    String typeStr;
    switch (type) {
      case GradingScaleType.gpa4pt:
        typeStr = 'gpa_4pt';
        break;
      case GradingScaleType.percentage:
        typeStr = 'percentage';
        break;
      case GradingScaleType.letter10pt:
        typeStr = 'letter_10pt';
        break;
    }

    return {
      'type': typeStr,
      'maxPoints': maxPoints,
      'passingPoint': passingPoint,
      'letterMap': letterMap,
    };
  }
}

class SemesterStructure {
  final int totalWeeks;
  final int semestersPerYear;
  final DateTime? currentSemesterStart;
  final DateTime? currentSemesterEnd;

  const SemesterStructure({
    required this.totalWeeks,
    required this.semestersPerYear,
    this.currentSemesterStart,
    this.currentSemesterEnd,
  });

  factory SemesterStructure.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return SemesterStructure(
      totalWeeks: map['totalWeeks'] ?? 15,
      semestersPerYear: map['semestersPerYear'] ?? 2,
      currentSemesterStart: parseDate(map['currentSemesterStart']),
      currentSemesterEnd: parseDate(map['currentSemesterEnd']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalWeeks': totalWeeks,
      'semestersPerYear': semestersPerYear,
      'currentSemesterStart': currentSemesterStart != null
          ? Timestamp.fromDate(currentSemesterStart!)
          : null,
      'currentSemesterEnd': currentSemesterEnd != null
          ? Timestamp.fromDate(currentSemesterEnd!)
          : null,
    };
  }
}

class Institution {
  final String collegeId;
  final String displayName;
  final String shortName;
  final String country;
  final String state;
  final GradingScale gradingScale;
  final double attendanceThreshold;
  final SemesterStructure semesterStructure;
  final bool hasMessMenu;
  final String messMenuRef;
  final String eventsCollectionId;
  final List<String> sampleTimetableCodes;
  final List<String> departments;
  final List<String> degreeTypes;

  const Institution({
    required this.collegeId,
    required this.displayName,
    required this.shortName,
    required this.country,
    required this.state,
    required this.gradingScale,
    required this.attendanceThreshold,
    required this.semesterStructure,
    required this.hasMessMenu,
    required this.messMenuRef,
    required this.eventsCollectionId,
    required this.sampleTimetableCodes,
    required this.departments,
    required this.degreeTypes,
  });

  factory Institution.fromMap(Map<String, dynamic> map, String id) {
    return Institution(
      collegeId: id,
      displayName: map['displayName'] ?? '',
      shortName: map['shortName'] ?? '',
      country: map['country'] ?? 'IN',
      state: map['state'] ?? '',
      gradingScale: GradingScale.fromMap(
        Map<String, dynamic>.from(map['gradingScale'] ?? {}),
      ),
      attendanceThreshold: (map['attendanceThreshold'] ?? kFallbackAttendanceThreshold).toDouble(),
      semesterStructure: SemesterStructure.fromMap(
        Map<String, dynamic>.from(map['semesterStructure'] ?? {}),
      ),
      hasMessMenu: map['hasMessMenu'] ?? true,
      messMenuRef: map['messMenuRef'] ?? id,
      eventsCollectionId: map['eventsCollectionId'] ?? id,
      sampleTimetableCodes: (map['sampleTimetableCodes'] as List?)?.isNotEmpty == true
          ? List<String>.from(map['sampleTimetableCodes'])
          : kFallbackSampleTimetableCodes,
      departments: (map['departments'] as List?)?.isNotEmpty == true
          ? List<String>.from(map['departments'])
          : kFallbackDepartments,
      degreeTypes: (map['degreeTypes'] as List?)?.isNotEmpty == true
          ? List<String>.from(map['degreeTypes'])
          : kFallbackDegreeTypes,
    );
  }

  factory Institution.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Institution.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'shortName': shortName,
      'country': country,
      'state': state,
      'gradingScale': gradingScale.toMap(),
      'attendanceThreshold': attendanceThreshold,
      'semesterStructure': semesterStructure.toMap(),
      'hasMessMenu': hasMessMenu,
      'messMenuRef': messMenuRef,
      'eventsCollectionId': eventsCollectionId,
      'sampleTimetableCodes': sampleTimetableCodes,
      'departments': departments,
      'degreeTypes': degreeTypes,
    };
  }
}
