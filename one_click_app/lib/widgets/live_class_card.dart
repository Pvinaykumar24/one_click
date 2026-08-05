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
  bool _hasMarkedAttendance = false;

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
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B), width: 3),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.3),
            const Color(0xFF0F172A),
            AppColors.background,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            offset: Offset(2, 2),
            blurRadius: 0,
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
                  color: AppColors.error.withValues(alpha: 0.1),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
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
          Text(subjectName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(type, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: _hasMarkedAttendance ? null : () {
                  ref.read(attendanceProvider.notifier).markAttended(subjectName, now, slot);
                  setState(() => _hasMarkedAttendance = true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$subjectName attendance marked as Present ✅')),
                  );
                },
                icon: Icon(_hasMarkedAttendance ? Icons.check_circle : Icons.how_to_reg, size: 18),
                label: Text(_hasMarkedAttendance ? 'Attended ✓' : 'Attending'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasMarkedAttendance ? AppColors.success : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
