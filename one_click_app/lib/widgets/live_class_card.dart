import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../services/timetable_service.dart';
import '../services/attendance_service.dart';
import '../models/timetable_slot.dart';

class LiveClassCard extends ConsumerStatefulWidget {
  const LiveClassCard({super.key});

  @override
  ConsumerState<LiveClassCard> createState() => _LiveClassCardState();
}

class _LiveClassCardState extends ConsumerState<LiveClassCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  TimetableSlot? _getCurrentLiveClass(DateTime now) {
    if (now.weekday > 5) return null; // Weekend
    final timetableNotifier = ref.read(timetableProvider.notifier);
    var todayClasses = timetableNotifier.getClassesForDay(now.weekday);
    String currentTimeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (var cls in todayClasses) {
      if (currentTimeStr.compareTo(cls.start) >= 0 && currentTimeStr.compareTo(cls.end) < 0) {
        return cls;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final timetableState = ref.watch(timetableProvider);

    return timetableState.maybeWhen(
      data: (slots) {
        final now = DateTime.now();
        final liveClass = _getCurrentLiveClass(now);

        if (liveClass == null) {
          return _buildNoClassBanner(context, now);
        }

        return _buildLiveClassCard(context, liveClass, now);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildNoClassBanner(BuildContext context, DateTime now) {
    final timetableNotifier = ref.read(timetableProvider.notifier);
    var upcoming = timetableNotifier.getUpcomingClassesAndDay(now);
    String nextDayLabel = upcoming['dayName'];
    List<TimetableSlot> nextClasses = upcoming['classes'];
    String nextInfo = nextClasses.isNotEmpty 
        ? '${nextClasses.first.subject} at ${nextClasses.first.start}'
        : 'No classes scheduled';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E2638), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.free_breakfast, color: AppColors.success, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No Class Right Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                      'Next: $nextInfo ($nextDayLabel)',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/schedule'),
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text('View $nextDayLabel Schedule'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveClassCard(BuildContext context, TimetableSlot liveClass, DateTime now) {
    String subjectName = liveClass.subject;
    String room = liveClass.room;
    String type = liveClass.type;
    String start = liveClass.start;
    String end = liveClass.end;
    String slot = '$start-$end';

    // Watch attendance records to get persistent live state
    final currentStatus = ref.read(attendanceProvider.notifier).getSessionStatus(subjectName, now, slot);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            const Color(0xFF0F131C),
            AppColors.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        FadeTransition(
                          opacity: _pulseAnimation,
                          child: Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.75), shape: BoxShape.circle),
                          ),
                        ),
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Text('LIVE NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error, letterSpacing: 1.2)),
                  ],
                ),
              ),
              Text(
                'Room $room • $start - $end',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(subjectName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(type, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Dual Action Attendance Buttons (Present & Absent)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(attendanceProvider.notifier).markAttended(subjectName, now, slot);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$subjectName marked as Present ✅')),
                      );
                    }
                  },
                  icon: Icon(currentStatus == 'present' ? Icons.check_circle : Icons.how_to_reg, size: 16),
                  label: Text(currentStatus == 'present' ? 'Attending ✓' : 'Mark Present'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentStatus == 'present' ? AppColors.success : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(attendanceProvider.notifier).markAbsent(subjectName, now, slot);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$subjectName marked as Absent ❌')),
                      );
                    }
                  },
                  icon: Icon(currentStatus == 'absent' ? Icons.cancel : Icons.event_busy, size: 16),
                  label: Text(currentStatus == 'absent' ? 'Absent ❌' : 'Mark Absent'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: currentStatus == 'absent' ? AppColors.error : Colors.white70,
                    side: BorderSide(color: currentStatus == 'absent' ? AppColors.error : AppColors.error.withValues(alpha: 0.4)),
                    backgroundColor: currentStatus == 'absent' ? AppColors.error.withValues(alpha: 0.15) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
}
