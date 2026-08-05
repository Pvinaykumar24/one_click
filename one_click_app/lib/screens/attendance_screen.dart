import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/attendance_service.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceProvider);
    final attendanceNotifier = ref.read(attendanceProvider.notifier);

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
                        ...attendanceNotifier.subjects.map((subject) => _buildSubjectCard(context, subject)),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    final requiredPct = ref.read(attendanceProvider.notifier).requiredPercentage;
    final reqText = '${requiredPct.toStringAsFixed(requiredPct.truncateToDouble() == requiredPct ? 0 : 1)}% req.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.textSecondary, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text('Academic Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(reqText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallGauge() {
    double overallPct = ref.read(attendanceProvider.notifier).getOverallPercentage();
    double requiredPct = ref.read(attendanceProvider.notifier).requiredPercentage;
    double difference = overallPct - requiredPct;
    String safeMsg = difference >= 0
        ? 'You are ${difference.toStringAsFixed(1)}% above the safe zone'
        : 'You are ${(-difference).toStringAsFixed(1)}% below required limit';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.5),
        border: Border.all(color: const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140, height: 140,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(value: 1.0, strokeWidth: 8, color: const Color(0xFF1E293B)),
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
          Text(safeMsg, style: TextStyle(fontSize: 12, color: difference >= 0 ? AppColors.success : AppColors.error)),
        ],
      ),
    );
  }

  Widget _buildSubjectListHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Per-Course Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildSubjectCard(BuildContext context, String subject) {
    var info = ref.read(attendanceProvider.notifier).getSubjectInfo(subject);
    double pct = info['currentPercentage'];
    int held = info['held'];
    int attended = info['attended'];
    int absent = info['absent'];
    int cancelled = info['cancelled'];
    int safeBunks = info['safeBunksLeft'];
    double requiredPct = ref.read(attendanceProvider.notifier).requiredPercentage;
    bool isWarning = pct < requiredPct;
    bool needsRecovery = info['needsRecovery'];
    int recoveryClasses = info['recoveryClasses'];

    Color statusColor = isWarning ? AppColors.error : AppColors.success;
    String statusMessage = needsRecovery
        ? 'Attend next $recoveryClasses classes'
        : 'Can miss $safeBunks more classes';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.6),
        border: Border.all(color: isWarning ? AppColors.error.withValues(alpha: 0.5) : const Color(0xFF1E293B)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isWarning ? [BoxShadow(color: AppColors.error.withValues(alpha: 0.1), blurRadius: 10)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject header with percentage circle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.book, color: statusColor),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subject, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text('$held classes held', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 3),
                ),
                alignment: Alignment.center,
                child: Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Attended', '$attended', color: AppColors.success),
              Container(width: 1, height: 24, color: const Color(0xFF334155)),
              _buildStatItem('Absent', '$absent', color: AppColors.error),
              Container(width: 1, height: 24, color: const Color(0xFF334155)),
              _buildStatItem('Cancelled', '$cancelled', color: AppColors.textSecondary),
              Container(width: 1, height: 24, color: const Color(0xFF334155)),
              _buildStatItem('Safe Left', '$safeBunks', color: AppColors.neonCyan),
            ],
          ),
          const SizedBox(height: 12),

          // Status message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isWarning ? Icons.warning_amber : Icons.check_circle, color: statusColor, size: 14),
                const SizedBox(width: 6),
                Text(statusMessage, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showUpdatePreviousDialog(context, subject),
                  icon: const Icon(Icons.edit_calendar, size: 14),
                  label: const Text('Update Previous', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelledDialog(context, subject),
                  icon: const Icon(Icons.cancel_outlined, size: 14),
                  label: const Text('Cancelled', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFBBF24),
                    side: BorderSide(color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdatePreviousDialog(BuildContext context, String subject) {
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 1));
    String selectedSlot = '09:00-09:50';
    bool wasPresent = false;

    final slots = ['09:00-09:50', '10:00-10:50', '11:00-11:50', '12:00-12:50', '14:00-17:00', '17:00-18:00'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Update $subject Attendance', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2025, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: const TextStyle(color: AppColors.textPrimary)),
                          const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Time Slot', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  DropdownButton<String>(
                    value: selectedSlot,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: slots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setDialogState(() => selectedSlot = val!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Status: ', style: TextStyle(color: AppColors.textSecondary)),
                      ChoiceChip(
                        label: const Text('Present'),
                        selected: wasPresent,
                        selectedColor: AppColors.success.withValues(alpha: 0.2),
                        onSelected: (val) => setDialogState(() => wasPresent = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Absent'),
                        selected: !wasPresent,
                        selectedColor: AppColors.error.withValues(alpha: 0.2),
                        onSelected: (val) => setDialogState(() => wasPresent = false),
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
                  ref.read(attendanceProvider.notifier).updatePreviousAttendance(subject, selectedDate, selectedSlot, wasPresent);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$subject attendance updated for ${selectedDate.day}/${selectedDate.month}')),
                  );
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCancelledDialog(BuildContext context, String subject) {
    DateTime selectedDate = DateTime.now();
    String selectedSlot = '09:00-09:50';
    final slots = ['09:00-09:50', '10:00-10:50', '11:00-11:50', '12:00-12:50', '14:00-17:00', '17:00-18:00'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text('Mark $subject Cancelled', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('This marks the class as cancelled (not counted as absent)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                const Text('Date', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2025, 1, 1),
                      lastDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: const TextStyle(color: AppColors.textPrimary)),
                        const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Slot', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                DropdownButton<String>(
                  value: selectedSlot, isExpanded: true, dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: slots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setDialogState(() => selectedSlot = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBBF24)),
                onPressed: () {
                  ref.read(attendanceProvider.notifier).markCancelled(subject, selectedDate, selectedSlot);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$subject class marked as cancelled')),
                  );
                },
                child: const Text('Mark Cancelled', style: TextStyle(color: Colors.black)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}
