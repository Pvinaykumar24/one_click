import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../services/events_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AcademicCalendarWidget extends ConsumerWidget {
  const AcademicCalendarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsyncValue = ref.watch(eventsProvider);
    final events = eventsAsyncValue.valueOrNull ?? [];
    final isLoading = eventsAsyncValue.isLoading;

    final now = DateTime.now();
    List<AcademicEvent> upcoming = events
        .where((e) => e.date.isAfter(now.subtract(const Duration(days: 1))))
        .toList();

    // Sort: Exams get highest priority near their date
    upcoming.sort((a, b) {
      if (a.date.difference(b.date).inDays.abs() <= 14) {
        if (a.type == 'exam' && b.type != 'exam') return -1;
        if (a.type != 'exam' && b.type == 'exam') return 1;
      }
      return a.date.compareTo(b.date);
    });

    final top3 = upcoming.take(3).toList();
    if (top3.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.neonCyan));
    }
    if (top3.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B), width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.calendar_month, color: AppColors.neonCyan, size: 22,
                      shadows: [Shadow(color: AppColors.neonCyan, blurRadius: 10)]),
                  SizedBox(width: 8),
                  Text('Academic Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${upcoming.length} upcoming',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neonCyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...top3.map((event) => _buildEventRow(event, now)),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => context.push('/academic-calendar'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Full Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRow(AcademicEvent event, DateTime now) {
    int daysLeft = event.date.difference(now).inDays;
    bool isExam = event.type == 'exam';
    Color color = event.color;
    String daysLabel = daysLeft <= 0 ? (event.date.day == now.day ? 'Today' : 'Past') : daysLeft == 1 ? 'Tomorrow' : '$daysLeft days';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isExam ? 0.15 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(event.icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(event.date),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isExam) const Icon(Icons.warning_amber, size: 10, color: AppColors.error),
                if (isExam) const SizedBox(width: 4),
                Text(daysLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
