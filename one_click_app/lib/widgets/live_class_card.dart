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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neoLime,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Icon(Icons.free_breakfast, color: Colors.black, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No Class Right Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                    const SizedBox(height: 4),
                    Text(
                      'Next: $nextInfo ($nextDayLabel)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
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
              icon: const Icon(Icons.calendar_today, size: 16, color: Colors.black),
              label: Text('View $nextDayLabel Schedule', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.neoCyan,
                side: const BorderSide(color: Colors.black, width: 2),
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

    final currentStatus = ref.read(attendanceProvider.notifier).getSessionStatus(subjectName, now, slot);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.neoCyan,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
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
                  color: AppColors.neoPink,
                  border: Border.all(color: Colors.black, width: 2),
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
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Text('LIVE NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text(
                  'Room $room • $start - $end',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(subjectName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black)),
          const SizedBox(height: 4),
          Text(type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                  icon: Icon(currentStatus == 'present' ? Icons.check_circle : Icons.how_to_reg, size: 16, color: Colors.black),
                  label: Text(currentStatus == 'present' ? 'Attending ✓' : 'Mark Present', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentStatus == 'present' ? AppColors.neoLime : AppColors.neoYellow,
                    elevation: 0,
                    side: const BorderSide(color: Colors.black, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  icon: Icon(currentStatus == 'absent' ? Icons.cancel : Icons.event_busy, size: 16, color: Colors.white),
                  label: Text(currentStatus == 'absent' ? 'Absent ❌' : 'Mark Absent', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: currentStatus == 'absent' ? Colors.black : AppColors.neoPink,
                    side: const BorderSide(color: Colors.black, width: 2),
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
