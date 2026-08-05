// Pure, side-effect-free CGPA/SGPA calculation functions.
//
// These functions have no dependency on Firebase, Riverpod, or Flutter —
// they can be tested in a plain Dart test environment.

// ─── Grade mapping ───────────────────────────────────────────────────────────

/// Returns the grade letter for a given [gradePoint] using the 10-point scale.
///
/// Mapping:
/// - S : gradePoint >= 9.0
/// - A : gradePoint >= 8.0
/// - B : gradePoint >= 7.0
/// - C : gradePoint >= 6.0
/// - D : gradePoint >= 5.0
/// - E : gradePoint >= 4.0
/// - F : gradePoint < 4.0
String gradeLetterFromPoint(double gradePoint) {
  if (gradePoint >= 9.0) return 'S';
  if (gradePoint >= 8.0) return 'A';
  if (gradePoint >= 7.0) return 'B';
  if (gradePoint >= 6.0) return 'C';
  if (gradePoint >= 5.0) return 'D';
  if (gradePoint >= 4.0) return 'E';
  return 'F';
}

// ─── CGPA (across semesters) ─────────────────────────────────────────────────

/// Represents one completed semester for CGPA calculation.
class SemRecord {
  final double sgpa;
  final int credits;
  const SemRecord({required this.sgpa, required this.credits});
}

/// Calculates the cumulative CGPA from a list of [semesters].
///
/// Returns 0.0 if [semesters] is empty or total credits are 0.
/// Uses a credit-weighted average: sum(sgpa * credits) / sum(credits).
double calculateCGPA(List<SemRecord> semesters) {
  if (semesters.isEmpty) return 0.0;
  double totalPoints = 0;
  int totalCredits = 0;
  for (final sem in semesters) {
    totalPoints += sem.sgpa * sem.credits;
    totalCredits += sem.credits;
  }
  return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
}

// ─── SGPA (current semester) ─────────────────────────────────────────────────

/// Represents one subject in the current semester.
class SubjectRecord {
  final double gradePoint;
  final int credits;
  const SubjectRecord({required this.gradePoint, required this.credits});
}

/// Calculates the SGPA for the current semester from a list of [subjects].
///
/// Returns 0.0 if [subjects] is empty or total credits are 0.
double calculateSGPA(List<SubjectRecord> subjects) {
  if (subjects.isEmpty) return 0.0;
  double totalPoints = 0;
  int totalCredits = 0;
  for (final sub in subjects) {
    totalPoints += sub.gradePoint * sub.credits;
    totalCredits += sub.credits;
  }
  return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
}

// ─── Predicted CGPA ──────────────────────────────────────────────────────────

/// Predicts the final CGPA by combining [pastSemesters] with [currentSubjects].
///
/// The current semester's SGPA is derived from [currentSubjects] grades and
/// combined with the past semester totals via credit-weighted average.
///
/// Returns 0.0 if total credits across both past and current are 0.
double predictCGPA({
  required List<SemRecord> pastSemesters,
  required List<SubjectRecord> currentSubjects,
}) {
  double pastPoints = 0;
  int pastCredits = 0;
  for (final sem in pastSemesters) {
    pastPoints += sem.sgpa * sem.credits;
    pastCredits += sem.credits;
  }

  double currentPoints = 0;
  int currentCredits = 0;
  for (final sub in currentSubjects) {
    currentPoints += sub.gradePoint * sub.credits;
    currentCredits += sub.credits;
  }

  final totalCredits = pastCredits + currentCredits;
  if (totalCredits == 0) return 0.0;
  return (pastPoints + currentPoints) / totalCredits;
}

// ─── Required SGPA to hit target CGPA ───────────────────────────────────────

/// Calculates the SGPA needed in the current semester to achieve [targetCgpa].
///
/// [pastSemesters]    : completed semesters.
/// [currentSemCredits]: total credits in the current semester.
/// [targetCgpa]       : the desired cumulative CGPA.
///
/// Returns `null` when [currentSemCredits] is 0 (undefined).
/// The result may be > 10.0 (meaning the target is mathematically unreachable)
/// or < 0.0 (meaning the target is already exceeded regardless of this semester).
double? requiredSGPAForTargetCGPA({
  required List<SemRecord> pastSemesters,
  required int currentSemCredits,
  required double targetCgpa,
}) {
  if (currentSemCredits == 0) return null;

  double pastPoints = 0;
  int pastCredits = 0;
  for (final sem in pastSemesters) {
    pastPoints += sem.sgpa * sem.credits;
    pastCredits += sem.credits;
  }

  final totalCredits = pastCredits + currentSemCredits;
  final targetTotalPoints = targetCgpa * totalCredits;
  final neededPoints = targetTotalPoints - pastPoints;
  return neededPoints / currentSemCredits;
}
