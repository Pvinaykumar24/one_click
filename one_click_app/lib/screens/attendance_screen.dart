import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../services/attendance_service.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  void _showAddSubjectModal() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F131C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          top: 20, left: 20, right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Subject / Course', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Artificial Intelligence',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF161C28),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A344B))),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    ref.read(attendanceProvider.notifier).addCustomSubject(controller.text.trim());
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Course to Tracker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThresholdSelector() {
    final current = ref.read(attendanceThresholdProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F131C),
        title: const Text('Set Attendance Requirement', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [75.0, 80.0, 85.0, 90.0].map((val) {
            final isSelected = current == val;
            return ListTile(
              title: Text('${val.toStringAsFixed(0)}% Required', style: TextStyle(color: isSelected ? AppColors.primary : Colors.white)),
              trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
              onTap: () {
                ref.read(attendanceProvider.notifier).setThreshold(val);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceProvider);
    final attendanceNotifier = ref.read(attendanceProvider.notifier);
    final subjects = attendanceNotifier.subjects;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: attendanceState.when(
          data: (records) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildOverallGauge(),
                        const SizedBox(height: 24),
                        _buildSubjectListHeader(),
                        const SizedBox(height: 16),
                        if (subjects.isEmpty)
                          _buildEmptyState()
                        else
                          ...subjects.map((subject) => _buildSubjectCard(context, subject)),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSubjectModal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Course', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final requiredPct = ref.watch(attendanceThresholdProvider);
    final reqText = '${requiredPct.toStringAsFixed(0)}% req.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.9),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E2638))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text('Classes, Bunks & Thresholds', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: _showThresholdSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Text(reqText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.tune, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallGauge() {
    double overallPct = ref.read(attendanceProvider.notifier).getOverallPercentage();
    double requiredPct = ref.watch(attendanceThresholdProvider);
    double difference = overallPct - requiredPct;
    String safeMsg = difference >= 0
        ? 'Safe Zone: ${difference.toStringAsFixed(1)}% above required'
        : 'Warning Zone: ${(-difference).toStringAsFixed(1)}% below required limit';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        border: Border.all(color: const Color(0xFF1E2638)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140, height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const CircularProgressIndicator(value: 1.0, strokeWidth: 8, color: Color(0xFF161C28)),
                CircularProgressIndicator(
                  value: overallPct / 100,
                  strokeWidth: 8,
                  color: difference >= 0 ? AppColors.primary : AppColors.error,
                  strokeCap: StrokeCap.round,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${overallPct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const Text('OVERALL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 2.0)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (difference >= 0 ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(safeMsg, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: difference >= 0 ? AppColors.success : AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Enrolled Courses Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        TextButton.icon(
          onPressed: () => context.push('/schedule'),
          icon: const Icon(Icons.sync, size: 14, color: AppColors.primary),
          label: const Text('Manage Schedule', style: TextStyle(fontSize: 12, color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2638)),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          const Text('No Courses Synced Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('Add classes in Timetable Manager or tap "+ Add Course" to start tracking attendance!', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push('/schedule'),
            icon: const Icon(Icons.calendar_month),
            label: const Text('Go to Timetable Manager'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, String subject) {
    var info = ref.read(attendanceProvider.notifier).getSubjectInfo(subject);
    double pct = info['currentPercentage'];
    int held = info['held'];
    int attended = info['attended'];
    int absent = info['absent'];
    int safeBunks = info['safeBunksLeft'];
    double requiredPct = info['requiredPercentage'];
    bool isWarning = pct < requiredPct;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isWarning ? AppColors.error.withValues(alpha: 0.5) : const Color(0xFF1E2638)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isWarning ? AppColors.error : AppColors.primary).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pct.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isWarning ? AppColors.error : AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$attended Attended / $held Held • $absent Absences',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // Safe Bunks / Recovery Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isWarning ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(isWarning ? Icons.warning_amber : Icons.check_circle_outline, size: 14, color: isWarning ? AppColors.error : AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isWarning ? 'Must attend next ${info['recoveryClasses']} classes to reach ${requiredPct.toStringAsFixed(0)}%' : '$safeBunks safe bunks remaining',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isWarning ? AppColors.error : AppColors.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Action Log Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: BorderSide(color: AppColors.success.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () async {
                    await ref.read(attendanceProvider.notifier).logAttendance(subject, 'present');
                    setState(() {});
                  },
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('+ Present', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () async {
                    await ref.read(attendanceProvider.notifier).logAttendance(subject, 'absent');
                    setState(() {});
                  },
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('+ Absent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: Color(0xFF2A344B)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () async {
                    await ref.read(attendanceProvider.notifier).logAttendance(subject, 'cancelled');
                    setState(() {});
                  },
                  icon: const Icon(Icons.block, size: 14),
                  label: const Text('Cancelled', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
