import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../services/attendance_service.dart';
import '../services/timetable_service.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final Map<String, bool> _expandedSubjects = {};

  void _showAddEmergencyClassModal(String? preselectedSubject) {
    final timetableSlots = ref.read(timetableProvider.notifier).slots;
    final enrolledCourses = timetableSlots.map((s) => s.subject).toSet().toList()..sort();
    final customSubjects = ref.read(customAttendanceSubjectsProvider);
    final allSubjects = {...enrolledCourses, ...customSubjects}.toList()..sort();

    String selectedSubject = preselectedSubject ?? (allSubjects.isNotEmpty ? allSubjects.first : 'General');
    final startController = TextEditingController(text: '10:00');
    final endController = TextEditingController(text: '11:00');
    DateTime selectedDate = DateTime.now();
    String selectedStatus = 'present';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F131C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
                      SizedBox(width: 8),
                      Text('Log Emergency / Extra Class', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              if (allSubjects.isNotEmpty) ...[
                const Text('Select Course', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubject,
                  dropdownColor: const Color(0xFF161C28),
                  style: const TextStyle(color: Colors.white),
                  items: allSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedSubject = val);
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Start Time (e.g. 10:00)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'End Time (e.g. 11:00)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    label: Text('Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'present', label: Text('Present')),
                      ButtonSegment(value: 'absent', label: Text('Absent')),
                    ],
                    selected: {selectedStatus},
                    onSelectionChanged: (val) {
                      setModalState(() => selectedStatus = val.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    final slotStr = '${startController.text.trim()}-${endController.text.trim()}';
                    await ref.read(attendanceProvider.notifier).logEmergencyClass(selectedSubject, selectedDate, slotStr, selectedStatus);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Emergency class logged for $selectedSubject ✅')),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Save Emergency Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
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
        onPressed: () => _showAddEmergencyClassModal(null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_alert, color: Colors.white),
        label: const Text('+ Emergency Class', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                  Text('Audited Scheduled Sessions & Emergency Classes', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
        ? 'Safe Zone: ${difference.toStringAsFixed(1)}% above required threshold'
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
          label: const Text('Manage Timetable', style: TextStyle(fontSize: 12, color: AppColors.primary)),
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
          const Text('Add classes in Timetable Manager or tap "+ Emergency Class" to log an extra lecture!', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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

    final isExpanded = _expandedSubjects[subject] ?? false;
    final sessions = ref.read(attendanceProvider.notifier).getScheduledSessionsForSubject(subject);

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

          // Session History Expander Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Class Session History (${sessions.length} sessions)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              InkWell(
                onTap: () {
                  setState(() => _expandedSubjects[subject] = !isExpanded);
                },
                child: Row(
                  children: [
                    Text(
                      isExpanded ? 'Hide History' : 'View & Audit Sessions',
                      style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),

          // Expanded Session History Timeline
          if (isExpanded) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF1E2638)),
            ...sessions.map((sess) {
              final isEmergency = sess.isEmergency;
              final dateStr = '${sess.date.day}/${sess.date.month}';
              final status = sess.status;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161C28),
                    borderRadius: BorderRadius.circular(10),
                    border: isEmergency ? Border.all(color: AppColors.warning.withValues(alpha: 0.4)) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${sess.dayName} ($dateStr)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              if (isEmergency) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('EXTRA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.warning)),
                                ),
                              ],
                            ],
                          ),
                          Text(sess.slot, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),

                      // Session Action Buttons (Present, Absent, Cancelled)
                      Row(
                        children: [
                          InkWell(
                            onTap: () async {
                              await ref.read(attendanceProvider.notifier).markAttended(subject, sess.date, sess.slot);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'present' ? AppColors.success : Colors.transparent,
                                border: Border.all(color: status == 'present' ? AppColors.success : Colors.white24),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Present',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'present' ? Colors.white : Colors.white70),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () async {
                              await ref.read(attendanceProvider.notifier).markAbsent(subject, sess.date, sess.slot);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'absent' ? AppColors.error : Colors.transparent,
                                border: Border.all(color: status == 'absent' ? AppColors.error : Colors.white24),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Absent',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'absent' ? Colors.white : Colors.white70),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () async {
                              await ref.read(attendanceProvider.notifier).markCancelled(subject, sess.date, sess.slot);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status == 'cancelled' ? Colors.white24 : Colors.transparent,
                                border: Border.all(color: Colors.white24),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Cancelled',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: status == 'cancelled' ? Colors.white : Colors.white38),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
