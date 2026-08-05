// Pure, side-effect-free attendance calculation functions.
//
// These functions have no dependency on Firebase, Riverpod, or Flutter —
// they can be tested in a plain Dart test environment.

// ─── Core attendance stats ────────────────────────────────────────────────────

/// All attendance numbers for a single subject.
class AttendanceStats {
  /// Total classes held (present + absent). Does NOT include cancelled classes.
  final int held;

  /// Classes the student attended.
  final int attended;

  /// Classes marked absent.
  final int absent;

  /// Classes cancelled (not counted in held or attended).
  final int cancelled;

  /// Total expected classes for the full semester.
  final int expected;

  /// Attendance percentage so far: (attended / held) * 100.
  /// Returns 100.0 when [held] == 0.
  double get currentPercentage =>
      held > 0 ? (attended / held) * 100.0 : 100.0;

  /// Classes remaining in the semester (expected - held - cancelled).
  int get remainingClasses => expected - held - cancelled;

  /// The number of future classes the student can skip (bunk) and still
  /// meet [requiredPercentage] by the end of the semester.
  ///
  /// Positive → can safely bunk that many.
  /// 0        → no bunks left but not in deficit.
  /// Negative → in deficit (use [recoveryClasses] for how many to recover).
  int safeBunksLeft(double requiredPercentage) {
    final totalAfterSemester = held + remainingClasses;
    final requiredTotal =
        (totalAfterSemester * (requiredPercentage / 100)).ceil();
    return attended + remainingClasses - requiredTotal;
  }

  /// Returns true when the student cannot meet [requiredPercentage] even by
  /// attending every remaining class.
  bool needsRecovery(double requiredPercentage) =>
      safeBunksLeft(requiredPercentage) < 0;

  /// How many consecutive classes the student must attend to recover.
  /// Returns 0 if not in deficit.
  int recoveryClasses(double requiredPercentage) {
    final deficit = safeBunksLeft(requiredPercentage);
    return deficit < 0 ? -deficit : 0;
  }

  const AttendanceStats({
    required this.held,
    required this.attended,
    required this.absent,
    required this.cancelled,
    required this.expected,
  });
}

// ─── Factory function ─────────────────────────────────────────────────────────

/// Builds an [AttendanceStats] object from raw counts.
///
/// [sessionsPerWeek] : how many times this subject appears per week in the
///                    timetable.
/// [semesterWeeks]   : total number of teaching weeks (default: 15).
AttendanceStats buildAttendanceStats({
  required int held,
  required int attended,
  required int absent,
  required int cancelled,
  int sessionsPerWeek = 1,
  int semesterWeeks = 15,
}) {
  final expected = sessionsPerWeek * semesterWeeks;
  return AttendanceStats(
    held: held,
    attended: attended,
    absent: absent,
    cancelled: cancelled,
    expected: expected,
  );
}

// ─── Overall percentage across subjects ──────────────────────────────────────

/// Calculates the overall attendance percentage across multiple subjects.
///
/// Returns 100.0 when total held is 0 (mirrors the per-subject behaviour).
double overallPercentage(List<AttendanceStats> subjects) {
  int totalHeld = 0;
  int totalAttended = 0;
  for (final s in subjects) {
    totalHeld += s.held;
    totalAttended += s.attended;
  }
  return totalHeld > 0 ? (totalAttended / totalHeld) * 100.0 : 100.0;
}
