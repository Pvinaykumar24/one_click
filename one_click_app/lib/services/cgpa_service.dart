import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/institution.dart';
import '../providers/auth_provider.dart';
import 'institution_service.dart';
import 'timetable_service.dart';

class SemesterData {
  String name;
  double sgpa;
  int totalCredits;

  SemesterData({required this.name, required this.sgpa, required this.totalCredits});

  Map<String, dynamic> toMap() => {
        'name': name,
        'sgpa': sgpa,
        'totalCredits': totalCredits,
      };

  factory SemesterData.fromMap(Map<String, dynamic> map) => SemesterData(
        name: map['name'] ?? '',
        sgpa: (map['sgpa'] ?? 0.0).toDouble(),
        totalCredits: map['totalCredits'] ?? 0,
      );
}

class SubjectGrade {
  String name;
  int credits;
  double gradePoint;

  SubjectGrade({required this.name, required this.credits, required this.gradePoint});

  Map<String, dynamic> toMap() => {
        'name': name,
        'credits': credits,
        'gradePoint': gradePoint,
      };

  factory SubjectGrade.fromMap(Map<String, dynamic> map) => SubjectGrade(
        name: map['name'] ?? '',
        credits: map['credits'] ?? 0,
        gradePoint: (map['gradePoint'] ?? 0.0).toDouble(),
      );

  String get gradeLetter => kDefaultGradingScale.getGradeLetter(gradePoint);
  String getGradeLetter(GradingScale scale) => scale.getGradeLetter(gradePoint);
}

class CgpaState {
  final List<SemesterData> pastSemesters;
  final List<SubjectGrade> currentSubjects;
  final String degreeType;
  final double targetCgpa;
  final double targetSGPA;

  CgpaState({
    required this.pastSemesters,
    required this.currentSubjects,
    required this.degreeType,
    required this.targetCgpa,
    required this.targetSGPA,
  });

  CgpaState copyWith({
    List<SemesterData>? pastSemesters,
    List<SubjectGrade>? currentSubjects,
    String? degreeType,
    double? targetCgpa,
    double? targetSGPA,
  }) {
    return CgpaState(
      pastSemesters: pastSemesters ?? this.pastSemesters,
      currentSubjects: currentSubjects ?? this.currentSubjects,
      degreeType: degreeType ?? this.degreeType,
      targetCgpa: targetCgpa ?? this.targetCgpa,
      targetSGPA: targetSGPA ?? this.targetSGPA,
    );
  }
}

class CgpaNotifier extends StreamNotifier<CgpaState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns the active [GradingScale] from [institutionProvider].
  /// Falls back to [kDefaultGradingScale] if institution config is unloaded or missing.
  GradingScale get gradingScale {
    final institution = ref.read(institutionProvider).valueOrNull;
    return institution?.gradingScale ?? kDefaultGradingScale;
  }

  @override
  Stream<CgpaState> build() {
    ref.watch(institutionProvider); // Automatically rebuilds when institution config changes
    final authState = ref.watch(authProvider);
    final scale = gradingScale;

    return authState.when(
      data: (user) {
        if (user == null) {
          return Stream.value(CgpaState(
            pastSemesters: [],
            currentSubjects: [],
            degreeType: 'B.Tech',
            targetCgpa: scale.defaultTargetCgpa,
            targetSGPA: scale.defaultTargetSgpa,
          ));
        }
        return _db
            .collection('users')
            .doc(user.id)
            .collection('cgpa')
            .doc('data')
            .snapshots()
            .map((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            final targetSGPA = (data['targetSGPA'] ?? scale.defaultTargetSgpa).toDouble();
            final targetCgpa = (data['targetCgpa'] ?? scale.defaultTargetCgpa).toDouble();
            final degreeType = (data['degreeType'] ?? 'B.Tech') as String;
            
            List<SemesterData> pastSemesters = [];
            if (data.containsKey('pastSemesters')) {
              pastSemesters = (data['pastSemesters'] as List).map((e) => SemesterData.fromMap(e)).toList();
            }
            
            List<SubjectGrade> currentSubjects = [];
            if (data.containsKey('currentSubjects')) {
              currentSubjects = (data['currentSubjects'] as List).map((e) => SubjectGrade.fromMap(e)).toList();
            }

            return CgpaState(
              pastSemesters: pastSemesters,
              currentSubjects: currentSubjects,
              degreeType: degreeType,
              targetCgpa: targetCgpa,
              targetSGPA: targetSGPA,
            );
          } else {
            return CgpaState(
              pastSemesters: [],
              currentSubjects: [],
              degreeType: 'B.Tech',
              targetCgpa: scale.defaultTargetCgpa,
              targetSGPA: scale.defaultTargetSgpa,
            );
          }
        });
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error loading CGPA stream: $e');
        return Stream.value(CgpaState(
          pastSemesters: [],
          currentSubjects: [],
          degreeType: 'B.Tech',
          targetCgpa: scale.defaultTargetCgpa,
          targetSGPA: scale.defaultTargetSgpa,
        ));
      },
    );
  }

  CgpaState get currentState => state.valueOrNull ?? CgpaState(
        pastSemesters: [],
        currentSubjects: [],
        degreeType: 'B.Tech',
        targetCgpa: gradingScale.defaultTargetCgpa,
        targetSGPA: gradingScale.defaultTargetSgpa,
      );

  List<SemesterData> get pastSemesters => currentState.pastSemesters;
  
  set pastSemesters(List<SemesterData> val) {
    _save(currentState.copyWith(pastSemesters: val));
  }

  List<SubjectGrade> get currentSubjects => currentState.currentSubjects;

  String get degreeType => currentState.degreeType;
  
  set degreeType(String val) {
    _save(currentState.copyWith(degreeType: val));
  }

  double get targetCgpa => currentState.targetCgpa;
  double get targetSGPA => currentState.targetSGPA;

  Future<void> _save(CgpaState newState) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).collection('cgpa').doc('data').set({
        'targetSGPA': newState.targetSGPA,
        'targetCgpa': newState.targetCgpa,
        'degreeType': newState.degreeType,
        'pastSemesters': newState.pastSemesters.map((e) => e.toMap()).toList(),
        'currentSubjects': newState.currentSubjects.map((e) => e.toMap()).toList(),
      });
    }
  }

  Future<void> addSubject(SubjectGrade subject) async {
    final current = currentState;
    final updatedSubjects = List<SubjectGrade>.from(current.currentSubjects)..add(subject);
    await _save(current.copyWith(currentSubjects: updatedSubjects));
  }

  Future<void> updateSubject(int index, SubjectGrade subject) async {
    final current = currentState;
    if (index < current.currentSubjects.length) {
      final updatedSubjects = List<SubjectGrade>.from(current.currentSubjects);
      updatedSubjects[index] = subject;
      await _save(current.copyWith(currentSubjects: updatedSubjects));
    }
  }

  Future<void> deleteSubject(int index) async {
    final current = currentState;
    if (index < current.currentSubjects.length) {
      final updatedSubjects = List<SubjectGrade>.from(current.currentSubjects)..removeAt(index);
      await _save(current.copyWith(currentSubjects: updatedSubjects));
    }
  }

  Future<void> addSemester(SemesterData semester) async {
    final current = currentState;
    final updatedSemesters = List<SemesterData>.from(current.pastSemesters)..add(semester);
    await _save(current.copyWith(pastSemesters: updatedSemesters));
  }

  Future<void> updateTargetCgpa(double value) async {
    final current = currentState;
    await _save(current.copyWith(targetCgpa: value));
  }

  Future<void> updateTargetSGPA(double value) async {
    final current = currentState;
    await _save(current.copyWith(targetSGPA: value));
  }

  Future<void> recalculate() async {
    await _save(currentState);
  }

  Future<void> syncFromTimetable() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final slots = ref.read(timetableProvider.notifier).slots;
    
    final Map<String, int> subjectCreditsMap = {};
    for (var slot in slots) {
      final subName = slot.subject;
      final credits = slot.credits;
      subjectCreditsMap[subName.toLowerCase()] = credits;
    }

    final allSubjects = ref.read(timetableProvider.notifier).allSubjects;
    final current = currentState;
    final updatedSubjects = List<SubjectGrade>.from(current.currentSubjects);
    bool addedAny = false;

    for (var subName in allSubjects) {
      final exists = updatedSubjects.any((s) => s.name.toLowerCase() == subName.toLowerCase());
      if (!exists) {
        final credits = subjectCreditsMap[subName.toLowerCase()] ?? 3;
        updatedSubjects.add(SubjectGrade(
          name: subName,
          credits: credits, 
          gradePoint: gradingScale.defaultSubjectGradePoint, 
        ));
        addedAny = true;
      }
    }

    if (addedAny) {
      await _save(current.copyWith(currentSubjects: updatedSubjects));
    }
  }

  double calculateCurrentCGPA() {
    final sems = pastSemesters;
    if (sems.isEmpty) return 0.0;
    double totalPoints = 0;
    int totalCredits = 0;
    for (var sem in sems) {
      totalPoints += sem.sgpa * sem.totalCredits;
      totalCredits += sem.totalCredits;
    }
    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  double calculateCurrentSGPA() {
    final subjects = currentState.currentSubjects;
    if (subjects.isEmpty) return 0.0;
    double totalPoints = 0;
    int totalCredits = 0;
    for (var sub in subjects) {
      totalPoints += sub.gradePoint * sub.credits;
      totalCredits += sub.credits;
    }
    return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
  }

  double predictCGPA() {
    final sems = pastSemesters;
    double currentTotalPoints = 0;
    int currentTotalCredits = 0;
    for (var sem in sems) {
      currentTotalPoints += sem.sgpa * sem.totalCredits;
      currentTotalCredits += sem.totalCredits;
    }
    
    final subjects = currentState.currentSubjects;
    double semesterPoints = 0;
    int semesterCredits = 0;
    for (var sub in subjects) {
      semesterPoints += sub.gradePoint * sub.credits;
      semesterCredits += sub.credits;
    }
    
    int totalCredits = currentTotalCredits + semesterCredits;
    if (totalCredits == 0) return 0.0;
    return (currentTotalPoints + semesterPoints) / totalCredits;
  }

  List<double> getSemesterTrend() {
    return pastSemesters.map((s) => s.sgpa).toList();
  }

  List<Map<String, dynamic>> getRequiredGradesForTargetSGPA() {
    List<Map<String, dynamic>> result = [];
    final subjects = currentState.currentSubjects;
    final scale = gradingScale;
    for (var sub in subjects) {
      result.add({
        'subject': sub.name,
        'credits': sub.credits,
        'currentGrade': sub.getGradeLetter(scale),
        'currentGP': sub.gradePoint,
        'neededGrade': scale.getGradeLetter(currentState.targetSGPA),
        'neededGP': currentState.targetSGPA,
      });
    }
    return result;
  }

  String getNeededGradeForCGPA() {
    return 'Any';
  }

  List<Map<String, dynamic>> predictNeeds() {
    final sems = pastSemesters;
    double currentPoints = 0;
    int currentCredits = 0;
    for (var sem in sems) {
      currentPoints += sem.sgpa * sem.totalCredits;
      currentCredits += sem.totalCredits;
    }

    final subjects = currentState.currentSubjects;
    int currentSemCredits = 0;
    for (var sub in subjects) {
      currentSemCredits += sub.credits;
    }

    int totalCredits = currentCredits + currentSemCredits;
    if (totalCredits == 0) return [];

    double targetTotalPoints = currentState.targetCgpa * totalCredits;
    double neededFromThisSem = targetTotalPoints - currentPoints;
    double neededSGPA = neededFromThisSem / currentSemCredits;
    final scale = gradingScale;
    final clampedGP = neededSGPA.clamp(0.0, scale.maxPoints);

    List<Map<String, dynamic>> suggestions = [];
    for (var sub in subjects) {
       suggestions.add({
         'subject': sub.name,
         'credits': sub.credits,
         'currentGrade': sub.getGradeLetter(scale),
         'currentGP': sub.gradePoint,
         'neededGP': clampedGP,
         'neededGrade': scale.getGradeLetter(clampedGP),
       });
     }
     return suggestions;
  }
}

final cgpaProvider = StreamNotifierProvider<CgpaNotifier, CgpaState>(() {
  return CgpaNotifier();
});
