import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../models/institution.dart';
import '../services/cgpa_service.dart';

class GpaPredictorScreen extends ConsumerStatefulWidget {
  const GpaPredictorScreen({super.key});

  @override
  ConsumerState<GpaPredictorScreen> createState() => _GpaPredictorScreenState();
}

class _GpaPredictorScreenState extends ConsumerState<GpaPredictorScreen> {
  @override
  Widget build(BuildContext context) {
    final cgpaState = ref.watch(cgpaProvider);
    final cgpaNotifier = ref.read(cgpaProvider.notifier);
    final scale = cgpaNotifier.gradingScale;

    final stateValue = cgpaState.valueOrNull ?? CgpaState(
      pastSemesters: [],
      currentSubjects: [],
      degreeType: 'B.Tech',
      targetCgpa: scale.defaultTargetCgpa,
      targetSGPA: scale.defaultTargetSgpa,
    );

    double currentCGPA = cgpaNotifier.calculateCurrentCGPA();
    double predictedCGPA = cgpaNotifier.predictCGPA();
    double currentSGPA = cgpaNotifier.calculateCurrentSGPA();
    final isEmpty = stateValue.pastSemesters.isEmpty && stateValue.currentSubjects.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 120),
                          child: Column(
                            children: [
                              _buildMainCgpaGauge(currentCGPA, predictedCGPA),
                              _buildCurrentSemesterSGPA(currentSGPA),
                              const SizedBox(height: 8),
                              _buildSemesterTrendsChart(),
                              const SizedBox(height: 8),
                              _buildTargetSGPASection(),
                              const SizedBox(height: 8),
                              _buildWhatIfAnalysis(),
                              _buildGradeAdvisor(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                ),
              ],
            ),
            if (!isEmpty) _buildStickyFooter(predictedCGPA, currentSGPA),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final cgpaNotifier = ref.read(cgpaProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.neonPink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.neonPink,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Academic Records Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add subjects for your current semester, past SGPA milestones, or sync directly from your schedule to start predicting.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await cgpaNotifier.syncFromTimetable();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synced subjects from timetable ✅')),
                  );
                }
              },
              icon: const Icon(Icons.sync, color: Colors.white),
              label: const Text('Sync from Timetable', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddSubjectDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Course'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonPink,
                    side: const BorderSide(color: AppColors.neonPink),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddSemesterDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Semester'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonCyan,
                    side: const BorderSide(color: AppColors.neonCyan),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddSemesterDialog() {
    final scale = ref.read(cgpaProvider.notifier).gradingScale;
    double sgpa = scale.defaultSemesterSgpa;
    int credits = 20;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cgpaNotifier = ref.read(cgpaProvider.notifier);
          final nextSemIndex = cgpaNotifier.pastSemesters.length + 1;
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Add Semester $nextSemIndex', style: const TextStyle(color: AppColors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SGPA: ${sgpa.toStringAsFixed(1)}', style: const TextStyle(color: AppColors.textSecondary)),
                Slider(value: sgpa.clamp(0.0, scale.maxPoints), min: 0, max: scale.maxPoints, divisions: scale.type == GradingScaleType.percentage ? 100 : (scale.maxPoints * 10).round(), activeColor: AppColors.primary,
                  onChanged: (val) => setDialogState(() => sgpa = val)),
                const SizedBox(height: 12),
                Text('Total Credits: $credits', style: const TextStyle(color: AppColors.textSecondary)),
                Slider(value: credits.toDouble(), min: 1, max: 30, divisions: 29, activeColor: AppColors.primary,
                  onChanged: (val) => setDialogState(() => credits = val.round())),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                onPressed: () {
                  cgpaNotifier.addSemester(SemesterData(name: 'Semester $nextSemIndex', sgpa: sgpa, totalCredits: credits));
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: AppColors.primary),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('CGPA Calculator',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              Text(ref.read(cgpaProvider.notifier).degreeType,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                      letterSpacing: 1.2)),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  await ref.read(cgpaProvider.notifier).syncFromTimetable();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Synced with Timetable! Courses added.')),
                    );
                  }
                },
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.sync, color: AppColors.neonCyan, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditPastSemestersDialog(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainCgpaGauge(double currentCGPA, double predictedCGPA) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 180, height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(value: 1.0, strokeWidth: 12, color: const Color(0xFF0F172A)),
                  CircularProgressIndicator(value: currentCGPA / 10.0, strokeWidth: 12, color: AppColors.primary, strokeCap: StrokeCap.round),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('CURRENT CGPA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 1.5)),
                      Text(currentCGPA.toStringAsFixed(2), style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(predictedCGPA >= currentCGPA ? Icons.trending_up : Icons.trending_down,
                              color: predictedCGPA >= currentCGPA ? AppColors.success : AppColors.error, size: 16),
                          const SizedBox(width: 4),
                          Text('${(predictedCGPA - currentCGPA) >= 0 ? '+' : ''}${(predictedCGPA - currentCGPA).toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: predictedCGPA >= currentCGPA ? AppColors.success : AppColors.error)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Target Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                Text('${currentCGPA.toStringAsFixed(2)} / ${ref.read(cgpaProvider.notifier).targetCgpa.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 10,
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(5)),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (currentCGPA / ref.read(cgpaProvider.notifier).targetCgpa).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary, borderRadius: BorderRadius.circular(5),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 10)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSemesterSGPA(double sgpa) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.neonCyan.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_graph, color: AppColors.neonCyan, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Semester SGPA (GPA)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(sgpa.toStringAsFixed(2), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.neonCyan)),
              ],
            ),
            const Spacer(),
            Text('${ref.read(cgpaProvider.notifier).currentSubjects.length} subjects', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterTrendsChart() {
    List<double> trends = ref.read(cgpaProvider.notifier).getSemesterTrend();
    double maxVal = trends.isEmpty ? 10.0 : trends.reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SGPA Trends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                GestureDetector(
                  onTap: () => _showEditPastSemestersDialog(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Edit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(trends.length, (i) {
                  double opacity = (i + 1) / trends.length;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(trends[i].toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: (trends[i] / maxVal).clamp(0.1, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: opacity),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('S${i + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSGPASection() {
    final scale = ref.read(cgpaProvider.notifier).gradingScale;
    bool achievable = ref.read(cgpaProvider.notifier).targetCgpa <= scale.maxPoints;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.neonPink.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.track_changes, color: AppColors.neonPink, size: 20),
                    SizedBox(width: 8),
                    Text('Target CGPA',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neonPink)),
                  ],
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: TextEditingController(
                        text: ref.read(cgpaProvider.notifier).targetCgpa.toStringAsFixed(1)),
                    style: const TextStyle(
                        color: AppColors.neonPink,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: AppColors.neonPink.withValues(alpha: 0.3))),
                    ),
                    onSubmitted: (val) {
                      double? v = double.tryParse(val);
                      if (v != null && v > 0 && v <= scale.maxPoints) {
                        ref.read(cgpaProvider.notifier).updateTargetCgpa(v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (achievable)
              const Text('To hit your CGPA goal, target these grades this sem:',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...ref.read(cgpaProvider.notifier).predictNeeds().map((r) {
              bool needsImprovement =
                  (r['neededGP'] as double) > (r['currentGP'] as double);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(r['subject'], style: const TextStyle(fontSize: 12, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: needsImprovement ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        scale.type == GradingScaleType.percentage
                            ? 'Min: ${r['neededGrade']}'
                            : 'Min: ${r['neededGrade']} (${(r['neededGP'] as double).toStringAsFixed(1)})',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: needsImprovement ? AppColors.error : AppColors.success),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Now: ${r['currentGrade']}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatIfAnalysis() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('What-If Analysis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              GestureDetector(
                onTap: _showAddSubjectDialog,
                child: Row(
                  children: const [
                    Icon(Icons.add_circle, color: AppColors.primary, size: 16),
                    SizedBox(width: 4),
                    Text('Add Course', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...ref.read(cgpaProvider.notifier).currentSubjects.asMap().entries.map((entry) {
            int idx = entry.key;
            SubjectGrade sub = entry.value;
            return _buildCoursePredictionCard(sub, idx);
          }),
        ],
      ),
    );
  }

  Widget _buildGradeSelector({
    required double currentGradePoint,
    required GradingScale scale,
    required ValueChanged<double> onChanged,
  }) {
    if (scale.type == GradingScaleType.letter10pt && scale.letterMap.isNotEmpty) {
      final sortedEntries = scale.letterMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      double bestMatchValue = sortedEntries.first.value;
      double minDiff = double.infinity;
      for (final entry in sortedEntries) {
        final diff = (entry.value - currentGradePoint).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestMatchValue = entry.value;
        }
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<double>(
            value: bestMatchValue,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            isDense: true,
            items: sortedEntries.map((e) => DropdownMenuItem(
              value: e.value,
              child: Text('${e.key} (${e.value.toStringAsFixed(0)})'),
            )).toList(),
            onChanged: (val) {
              if (val != null) onChanged(val);
            },
          ),
        ),
      );
    } else if (scale.type == GradingScaleType.gpa4pt) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GPA: ${currentGradePoint.toStringAsFixed(1)} / 4.0', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Slider(
            value: currentGradePoint.clamp(0.0, 4.0),
            min: 0.0,
            max: 4.0,
            divisions: 40,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Score: ${currentGradePoint.round()}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Slider(
            value: currentGradePoint.clamp(0.0, 100.0),
            min: 0.0,
            max: 100.0,
            divisions: 100,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      );
    }
  }

  void _showAddSubjectDialog() {
    final scale = ref.read(cgpaProvider.notifier).gradingScale;
    String name = '';
    int credits = 3;
    double gradePoint = scale.defaultSubjectGradePoint;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Add Course', style: TextStyle(color: AppColors.textPrimary)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Course Name', labelStyle: TextStyle(color: AppColors.textSecondary)),
                    onChanged: (val) => name = val,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Credits: ', style: TextStyle(color: AppColors.textSecondary)),
                      DropdownButton<int>(
                        value: credits, dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.textPrimary),
                        items: [1, 2, 3, 4, 5].map((c) => DropdownMenuItem(value: c, child: Text('$c'))).toList(),
                        onChanged: (val) => setDialogState(() => credits = val!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grade: ', style: TextStyle(color: AppColors.textSecondary)),
                      Expanded(
                        child: _buildGradeSelector(
                          currentGradePoint: gradePoint,
                          scale: scale,
                          onChanged: (val) => setDialogState(() => gradePoint = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                onPressed: () {
                  if (name.isNotEmpty) {
                    ref.read(cgpaProvider.notifier).addSubject(SubjectGrade(name: name, credits: credits, gradePoint: gradePoint));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditPastSemestersDialog() {
    final scale = ref.read(cgpaProvider.notifier).gradingScale;
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Edit Past Semesters', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(ref.read(cgpaProvider.notifier).pastSemesters.length, (i) {
                var sem = ref.read(cgpaProvider.notifier).pastSemesters[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(sem.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: TextEditingController(text: sem.sgpa.toStringAsFixed(1)),
                          style: const TextStyle(color: AppColors.neonCyan, fontSize: 14),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            double? v = double.tryParse(val);
                            if (v != null && v > 0 && v <= scale.maxPoints) {
                              sem.sgpa = v;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () {
                ref.read(cgpaProvider.notifier).recalculate();
                Navigator.pop(context);
              },
              child: const Text('Save & Recalculate'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCoursePredictionCard(SubjectGrade sub, int index) {
    final scale = ref.read(cgpaProvider.notifier).gradingScale;
    final pct = scale.maxPoints > 0 ? (sub.gradePoint / scale.maxPoints) : 0.0;
    Color accentColor = pct >= 0.8 ? AppColors.success
        : pct >= 0.6 ? const Color(0xFFFBBF24) : AppColors.error;

    final gradeDisplay = sub.getGradeLetter(scale);
    final pointDisplay = scale.type == GradingScaleType.percentage
        ? '${sub.gradePoint.round()}%'
        : '${sub.gradePoint.toStringAsFixed(1)} pt';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(sub.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('${sub.credits} Credits', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  scale.type == GradingScaleType.percentage ? pointDisplay : '$gradeDisplay ($pointDisplay)',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGradeSelector(
            currentGradePoint: sub.gradePoint,
            scale: scale,
            onChanged: (val) {
              final updated = ref.read(cgpaProvider.notifier).currentSubjects[index];
              updated.gradePoint = val;
              ref.read(cgpaProvider.notifier).updateSubject(index, updated);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGradeAdvisor() {
    String neededGrade = ref.read(cgpaProvider.notifier).getNeededGradeForCGPA();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(children: const [
              Icon(Icons.lightbulb, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Grade Advisor', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ]),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                children: [
                  const TextSpan(text: 'To reach target CGPA of '),
                  TextSpan(text: ref.read(cgpaProvider.notifier).targetCgpa.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const TextSpan(text: ': '),
                  TextSpan(text: neededGrade, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyFooter(double predictedCGPA, double currentSGPA) {
    return Positioned(
      bottom: 24, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(
                children: [
                  Column(children: [
                    Text('PREDICTED CGPA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
                    Text(predictedCGPA.toStringAsFixed(2), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ]),
                  const SizedBox(width: 16),
                  Column(children: [
                    Text('CURRENT GPA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.8))),
                    Text(currentSGPA.toStringAsFixed(2), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ]),
                ],
              ),
            ]),
            GestureDetector(
              onTap: () => ref.read(cgpaProvider.notifier).recalculate(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Row(children: const [
                  Icon(Icons.bolt, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text('Recalculate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
