import 'package:flutter_test/flutter_test.dart';
import 'package:one_click_app/utils/cgpa_math.dart';

void main() {
  // ─── gradeLetterFromPoint ───────────────────────────────────────────────────

  group('gradeLetterFromPoint', () {
    test('returns S for 10.0', () => expect(gradeLetterFromPoint(10.0), 'S'));
    test('returns S for exactly 9.0', () => expect(gradeLetterFromPoint(9.0), 'S'));
    test('returns A for 8.5', () => expect(gradeLetterFromPoint(8.5), 'A'));
    test('returns A for exactly 8.0', () => expect(gradeLetterFromPoint(8.0), 'A'));
    test('returns B for 7.5', () => expect(gradeLetterFromPoint(7.5), 'B'));
    test('returns B for exactly 7.0', () => expect(gradeLetterFromPoint(7.0), 'B'));
    test('returns C for 6.5', () => expect(gradeLetterFromPoint(6.5), 'C'));
    test('returns C for exactly 6.0', () => expect(gradeLetterFromPoint(6.0), 'C'));
    test('returns D for 5.5', () => expect(gradeLetterFromPoint(5.5), 'D'));
    test('returns D for exactly 5.0', () => expect(gradeLetterFromPoint(5.0), 'D'));
    test('returns E for 4.5', () => expect(gradeLetterFromPoint(4.5), 'E'));
    test('returns E for exactly 4.0', () => expect(gradeLetterFromPoint(4.0), 'E'));
    test('returns F for 3.9', () => expect(gradeLetterFromPoint(3.9), 'F'));
    test('returns F for 0.0', () => expect(gradeLetterFromPoint(0.0), 'F'));
  });

  // ─── calculateCGPA ─────────────────────────────────────────────────────────

  group('calculateCGPA', () {
    test('returns 0.0 for empty list', () {
      expect(calculateCGPA([]), 0.0);
    });

    test('single semester — CGPA equals that semester SGPA', () {
      final sems = [const SemRecord(sgpa: 8.5, credits: 20)];
      expect(calculateCGPA(sems), closeTo(8.5, 1e-9));
    });

    test('two equal semesters — CGPA equals the common SGPA', () {
      final sems = [
        const SemRecord(sgpa: 9.0, credits: 20),
        const SemRecord(sgpa: 9.0, credits: 20),
      ];
      expect(calculateCGPA(sems), closeTo(9.0, 1e-9));
    });

    test('credit-weighted average (unequal credits)', () {
      // (8.0*10 + 6.0*30) / 40 = (80 + 180) / 40 = 260/40 = 6.5
      final sems = [
        const SemRecord(sgpa: 8.0, credits: 10),
        const SemRecord(sgpa: 6.0, credits: 30),
      ];
      expect(calculateCGPA(sems), closeTo(6.5, 1e-9));
    });

    test('all same grade (all 10) equals 10.0', () {
      final sems = List.generate(
          8, (_) => const SemRecord(sgpa: 10.0, credits: 20));
      expect(calculateCGPA(sems), closeTo(10.0, 1e-9));
    });

    test('zero credits semester is ignored in weighted average', () {
      // Only the 20-credit semester should count.
      final sems = [
        const SemRecord(sgpa: 9.0, credits: 20),
        const SemRecord(sgpa: 5.0, credits: 0),
      ];
      expect(calculateCGPA(sems), closeTo(9.0, 1e-9));
    });

    test('all zero credits → returns 0.0', () {
      final sems = [const SemRecord(sgpa: 8.0, credits: 0)];
      expect(calculateCGPA(sems), 0.0);
    });
  });

  // ─── calculateSGPA ─────────────────────────────────────────────────────────

  group('calculateSGPA', () {
    test('returns 0.0 for empty list', () {
      expect(calculateSGPA([]), 0.0);
    });

    test('single subject — SGPA equals its grade point', () {
      expect(calculateSGPA([const SubjectRecord(gradePoint: 9.0, credits: 3)]),
          closeTo(9.0, 1e-9));
    });

    test('two subjects with equal credits — simple average', () {
      final subjects = [
        const SubjectRecord(gradePoint: 8.0, credits: 3),
        const SubjectRecord(gradePoint: 6.0, credits: 3),
      ];
      expect(calculateSGPA(subjects), closeTo(7.0, 1e-9));
    });

    test('credit-weighted: high-credit F subject drags SGPA down', () {
      // (9.0*2 + 0.0*6) / 8 = 18/8 = 2.25
      final subjects = [
        const SubjectRecord(gradePoint: 9.0, credits: 2),
        const SubjectRecord(gradePoint: 0.0, credits: 6), // failing
      ];
      expect(calculateSGPA(subjects), closeTo(2.25, 1e-9));
    });

    test('all subjects with gradePoint 0.0 → SGPA is 0.0', () {
      final subjects = List.generate(
          5, (_) => const SubjectRecord(gradePoint: 0.0, credits: 3));
      expect(calculateSGPA(subjects), 0.0);
    });

    test('includes F-grade (0.0) in weighted average — no special exclusion', () {
      // NOTE: The current implementation does NOT exclude failing grades from
      // the average. This test documents that behavior explicitly.
      // (8.0*3 + 0.0*3) / 6 = 24/6 = 4.0
      final subjects = [
        const SubjectRecord(gradePoint: 8.0, credits: 3),
        const SubjectRecord(gradePoint: 0.0, credits: 3), // F grade
      ];
      expect(calculateSGPA(subjects), closeTo(4.0, 1e-9));
    });
  });

  // ─── predictCGPA ───────────────────────────────────────────────────────────

  group('predictCGPA', () {
    test('no past, no current → 0.0', () {
      expect(predictCGPA(pastSemesters: [], currentSubjects: []), 0.0);
    });

    test('no past semesters — prediction equals current SGPA', () {
      final subjects = [
        const SubjectRecord(gradePoint: 8.0, credits: 20),
      ];
      expect(
          predictCGPA(pastSemesters: [], currentSubjects: subjects),
          closeTo(8.0, 1e-9));
    });

    test('no current subjects — prediction equals existing CGPA', () {
      final sems = [const SemRecord(sgpa: 7.5, credits: 20)];
      expect(
          predictCGPA(pastSemesters: sems, currentSubjects: []),
          closeTo(7.5, 1e-9));
    });

    test('prediction is credit-weighted across past + current', () {
      // Past: 9.0 * 20 = 180 pts
      // Current: 6.0 * 20 = 120 pts
      // Total: 300/40 = 7.5
      final sems = [const SemRecord(sgpa: 9.0, credits: 20)];
      final subjects = [const SubjectRecord(gradePoint: 6.0, credits: 20)];
      expect(
          predictCGPA(pastSemesters: sems, currentSubjects: subjects),
          closeTo(7.5, 1e-9));
    });

    test('perfect current semester improves prediction', () {
      final sems = [const SemRecord(sgpa: 7.0, credits: 20)];
      final subjects = [const SubjectRecord(gradePoint: 10.0, credits: 20)];
      // (7*20 + 10*20) / 40 = 340/40 = 8.5
      expect(
          predictCGPA(pastSemesters: sems, currentSubjects: subjects),
          closeTo(8.5, 1e-9));
    });

    test('F grade in current semester lowers prediction', () {
      final sems = [const SemRecord(sgpa: 9.0, credits: 20)];
      final subjects = [const SubjectRecord(gradePoint: 0.0, credits: 20)];
      // (9*20 + 0*20) / 40 = 180/40 = 4.5
      expect(
          predictCGPA(pastSemesters: sems, currentSubjects: subjects),
          closeTo(4.5, 1e-9));
    });
  });

  // ─── requiredSGPAForTargetCGPA ──────────────────────────────────────────────

  group('requiredSGPAForTargetCGPA', () {
    test('returns null when currentSemCredits is 0', () {
      expect(
        requiredSGPAForTargetCGPA(
          pastSemesters: [],
          currentSemCredits: 0,
          targetCgpa: 8.0,
        ),
        isNull,
      );
    });

    test('no past semesters — needed SGPA equals targetCgpa', () {
      final result = requiredSGPAForTargetCGPA(
        pastSemesters: [],
        currentSemCredits: 20,
        targetCgpa: 8.5,
      );
      expect(result, closeTo(8.5, 1e-9));
    });

    test('already at target — needed SGPA equals target exactly', () {
      // Past CGPA = (8.0*20)/20 = 8.0, target 8.0, one more 20-credit sem
      // needed = (8.0*40 - 8.0*20) / 20 = 8.0
      final sems = [const SemRecord(sgpa: 8.0, credits: 20)];
      final result = requiredSGPAForTargetCGPA(
        pastSemesters: sems,
        currentSemCredits: 20,
        targetCgpa: 8.0,
      );
      expect(result, closeTo(8.0, 1e-9));
    });

    test('above target — needed SGPA is less than target', () {
      final sems = [const SemRecord(sgpa: 9.0, credits: 20)];
      final result = requiredSGPAForTargetCGPA(
        pastSemesters: sems,
        currentSemCredits: 20,
        targetCgpa: 8.0,
      );
      // (8*40 - 9*20) / 20 = (320-180)/20 = 7.0
      expect(result, closeTo(7.0, 1e-9));
    });

    test('target is mathematically unreachable — result exceeds 10.0', () {
      // Past CGPA = 5.0*20 = 100pts, target 9.0 over 40 credits = 360 pts needed
      // Current must supply 360-100=260 in 20 credits → 13.0 > 10
      final sems = [const SemRecord(sgpa: 5.0, credits: 20)];
      final result = requiredSGPAForTargetCGPA(
        pastSemesters: sems,
        currentSemCredits: 20,
        targetCgpa: 9.0,
      );
      expect(result, greaterThan(10.0));
    });
  });
}
