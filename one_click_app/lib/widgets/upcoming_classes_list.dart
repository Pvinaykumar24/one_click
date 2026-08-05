import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../services/timetable_service.dart';
import '../models/timetable_slot.dart';

class UpcomingClassesList extends ConsumerWidget {
  const UpcomingClassesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableState = ref.watch(timetableProvider);
    final timetableNotifier = ref.read(timetableProvider.notifier);

    return timetableState.maybeWhen(
      data: (slots) {
        var upcomingData = timetableNotifier.getUpcomingClassesAndDay(DateTime.now());
        String titleDay = upcomingData['dayName'];
        List<TimetableSlot> classes = upcomingData['classes'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming $titleDay',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/schedule'),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: classes.isEmpty
                  ? const Center(
                      child: Text(
                        'No upcoming classes.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        var cls = classes[index];
                        return _buildUpcomingCourseCard(
                          time: '${cls.start} - ${cls.end}',
                          title: cls.subject,
                          location: cls.room,
                          icon: cls.type == 'Lab' ? Icons.computer : Icons.book,
                          iconColor: cls.type == 'Lab' ? AppColors.neonCyan : const Color(0xFFF97316),
                        );
                      },
                    ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildUpcomingCourseCard({
    required String time,
    required String title,
    required String location,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 250,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.5), // slate-900/50
        border: Border.all(color: const Color(0xFF1E293B), width: 3), // slate-800
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
