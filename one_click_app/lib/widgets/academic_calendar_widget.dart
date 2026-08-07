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

    upcoming.sort((a, b) {
      if (a.date.difference(b.date).inDays.abs() <= 14) {
        if (a.type == 'exam' && b.type != 'exam') return -1;
        if (a.type != 'exam' && b.type == 'exam') return 1;
      }
      return a.date.compareTo(b.date);
    });

    final top3 = upcoming.take(3).toList();
    if (top3.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    if (top3.isEmpty) return const SizedBox.shrink();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.neoCyan,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Icon(Icons.calendar_month, color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Academic Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neoPink,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Text(
                  '${upcoming.length} upcoming',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...top3.map((event) => _buildEventRow(event, now)),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/academic-calendar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: AppColors.neoYellow,
                side: const BorderSide(color: Colors.black, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Full Calendar →', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRow(AcademicEvent event, DateTime now) {
    int daysLeft = event.date.difference(now).inDays;
    bool isExam = event.type == 'exam';
    String daysLabel = daysLeft <= 0 ? (event.date.day == now.day ? 'Today' : 'Past') : daysLeft == 1 ? 'Tomorrow' : '$daysLeft days';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isExam ? AppColors.neoYellow : const Color(0xFFF8F6F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.date.day}/${event.date.month}/${event.date.year}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isExam ? AppColors.neoPink : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              daysLabel,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isExam ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
