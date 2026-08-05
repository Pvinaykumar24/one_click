import 'package:flutter_test/flutter_test.dart';
import 'package:one_click_app/utils/attendance_math.dart';

void main() {
  const double req = 85.0; // Sample required attendance threshold for testing configurable limits

  // ─── AttendanceStats.currentPercentage ────────────────────────────────────

  group('AttendanceStats.currentPercentage', () {
    test('0 held classes → returns 100.0 (no data = perfect)', () {
      const s = AttendanceStats(
        held: 0, attended: 0, absent: 0, cancelled: 0, expected: 45,
      );
      expect(s.currentPercentage, 100.0);
    });

    test('all attended → 100%', () {
      const s = AttendanceStats(
        held: 10, attended: 10, absent: 0, cancelled: 0, expected: 45,
      );
      expect(s.currentPercentage, closeTo(100.0, 1e-9));
    });

    test('none attended → 0%', () {
      const s = AttendanceStats(
        held: 10, attended: 0, absent: 10, cancelled: 0, expected: 45,
      );
      expect(s.currentPercentage, closeTo(0.0, 1e-9));
    });

    test('half attended → 50%', () {
      const s = AttendanceStats(
        held: 10, attended: 5, absent: 5, cancelled: 0, expected: 45,
      );
      expect(s.currentPercentage, closeTo(50.0, 1e-9));
    });

    test('cancelled classes are NOT counted in held or percentage', () {
      // 10 held, 8 attended, 2 absent, 5 cancelled
      const s = AttendanceStats(
        held: 10, attended: 8, absent: 2, cancelled: 5, expected: 45,
      );
      // Percentage is based on held (10), not held+cancelled
      expect(s.currentPercentage, closeTo(80.0, 1e-9));
    });
  });

  // ─── AttendanceStats.remainingClasses ────────────────────────────────────

  group('remainingClasses', () {
    test('remaining = expected - held - cancelled', () {
      const s = AttendanceStats(
        held: 10, attended: 8, absent: 2, cancelled: 3, expected: 45,
      );
      expect(s.remainingClasses, 32); // 45 - 10 - 3
    });

    test('zero remaining when all classes done', () {
      const s = AttendanceStats(
        held: 42, attended: 36, absent: 6, cancelled: 3, expected: 45,
      );
      expect(s.remainingClasses, 0); // 45 - 42 - 3
    });
  });

  // ─── safeBunksLeft ────────────────────────────────────────────────────────

  group('safeBunksLeft', () {
    // Scenario: full semester (45 classes), none held yet.
    // requiredTotal = ceil(45 * 0.85) = ceil(38.25) = 39
    // safeBunks = 0 + 45 - 39 = 6
    test('beginning of semester, 0 held — safe bunks = 6 (for 45-class semester, 85%)', () {
      const s = AttendanceStats(
        held: 0, attended: 0, absent: 0, cancelled: 0, expected: 45,
      );
      expect(s.safeBunksLeft(req), 6);
    });

    test('100% attendance halfway through — more safe bunks', () {
      // held=22, attended=22, remaining=23
      // totalAfter = 22+23 = 45, requiredTotal = 39
      // safeBunks = 22+23-39 = 6 (same as before since attendance was perfect)
      const s = AttendanceStats(
        held: 22, attended: 22, absent: 0, cancelled: 0, expected: 45,
      );
      expect(s.safeBunksLeft(req), 6);
    });

    test('exactly at 85% with no remaining classes — safeBunks = 0', () {
      // 39 attended / 45 held = 86.7%... let's pick exact: held=20, attended=17
      // 17/20 = 85%. No remaining classes (expected=20).
      // totalAfter=20, requiredTotal=ceil(20*0.85)=ceil(17)=17
      // safeBunks = 17 + 0 - 17 = 0
      const s = AttendanceStats(
        held: 20, attended: 17, absent: 3, cancelled: 0, expected: 20,
      );
      expect(s.safeBunksLeft(req), 0);
    });

    test('below threshold with no remaining — negative bunks (deficit)', () {
      // held=20, attended=10 (50%), expected=20 (no remaining)
      // requiredTotal = ceil(20 * 0.85) = 17
      // safeBunks = 10 + 0 - 17 = -7
      const s = AttendanceStats(
        held: 20, attended: 10, absent: 10, cancelled: 0, expected: 20,
      );
      expect(s.safeBunksLeft(req), -7);
    });

    test('zero throughout semester — safe bunks still positive at start', () {
      const s = AttendanceStats(
        held: 0, attended: 0, absent: 0, cancelled: 0, expected: 30,
      );
      // requiredTotal = ceil(30*0.85) = ceil(25.5) = 26
      // safeBunks = 0 + 30 - 26 = 4
      expect(s.safeBunksLeft(req), 4);
    });

    test('safe bunks varies with required percentage', () {
      const s = AttendanceStats(
        held: 0, attended: 0, absent: 0, cancelled: 0, expected: 45,
      );
      // At 75%: requiredTotal = ceil(45*0.75) = ceil(33.75) = 34
      // safeBunks = 0 + 45 - 34 = 11
      expect(s.safeBunksLeft(75.0), 11);
    });
  });

  // ─── needsRecovery ────────────────────────────────────────────────────────

  group('needsRecovery', () {
    test('false when safe bunks are positive', () {
      const s = AttendanceStats(
        held: 0, attended: 0, absent: 0, cancelled: 0, expected: 45,
      );
      expect(s.needsRecovery(req), isFalse);
    });

    test('false when safeBunksLeft == 0', () {
      // held=20, attended=17, expected=20, no remaining
      const s = AttendanceStats(
        held: 20, attended: 17, absent: 3, cancelled: 0, expected: 20,
      );
      expect(s.needsRecovery(req), isFalse);
    });

    test('true when attendance is below required with no remaining classes', () {
      const s = AttendanceStats(
        held: 20, attended: 10, absent: 10, cancelled: 0, expected: 20,
      );
      expect(s.needsRecovery(req), isTrue);
    });
  });

  // ─── recoveryClasses ──────────────────────────────────────────────────────

  group('recoveryClasses', () {
    test('returns 0 when not in deficit', () {
      const s = AttendanceStats(
        held: 0, attended: 0, absent: 0, cancelled: 0, expected: 45,
      );
      expect(s.recoveryClasses(req), 0);
    });

    test('returns absolute value of deficit when negative', () {
      // safeBunks = -7 from earlier test
      const s = AttendanceStats(
        held: 20, attended: 10, absent: 10, cancelled: 0, expected: 20,
      );
      expect(s.recoveryClasses(req), 7);
    });
  });

  // ─── buildAttendanceStats ─────────────────────────────────────────────────

  group('buildAttendanceStats', () {
    test('expected = sessionsPerWeek * semesterWeeks', () {
      final s = buildAttendanceStats(
        held: 0, attended: 0, absent: 0, cancelled: 0,
        sessionsPerWeek: 3, semesterWeeks: 15,
      );
      expect(s.expected, 45);
    });

    test('default sessionsPerWeek=1, semesterWeeks=15 → expected=15', () {
      final s = buildAttendanceStats(
        held: 0, attended: 0, absent: 0, cancelled: 0,
      );
      expect(s.expected, 15);
    });
  });

  // ─── overallPercentage ────────────────────────────────────────────────────

  group('overallPercentage', () {
    test('empty subject list → 100.0', () {
      expect(overallPercentage([]), 100.0);
    });

    test('all attended across two subjects → 100%', () {
      final subjects = [
        const AttendanceStats(held: 10, attended: 10, absent: 0, cancelled: 0, expected: 45),
        const AttendanceStats(held: 15, attended: 15, absent: 0, cancelled: 0, expected: 45),
      ];
      expect(overallPercentage(subjects), closeTo(100.0, 1e-9));
    });

    test('mixed attendance — overall is credit-weighted across classes held', () {
      // Subject A: 8/10 = 80%, Subject B: 15/15 = 100%
      // Overall: 23/25 = 92%
      final subjects = [
        const AttendanceStats(held: 10, attended: 8, absent: 2, cancelled: 0, expected: 45),
        const AttendanceStats(held: 15, attended: 15, absent: 0, cancelled: 0, expected: 45),
      ];
      expect(overallPercentage(subjects), closeTo(92.0, 1e-9));
    });

    test('all subjects with 0 held → 100.0', () {
      final subjects = [
        const AttendanceStats(held: 0, attended: 0, absent: 0, cancelled: 0, expected: 45),
        const AttendanceStats(held: 0, attended: 0, absent: 0, cancelled: 0, expected: 45),
      ];
      expect(overallPercentage(subjects), 100.0);
    });
  });
}
