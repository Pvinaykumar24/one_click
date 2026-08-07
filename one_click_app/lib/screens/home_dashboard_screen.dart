import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/live_class_card.dart';
import '../widgets/mess_menu_preview.dart';
import '../widgets/attendance_health_widget.dart';
import '../widgets/cgpa_preview_widget.dart';
import '../widgets/upcoming_classes_list.dart';
import '../widgets/academic_calendar_widget.dart';
import '../core/theme/app_colors.dart';
import '../services/timetable_service.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime now = DateTime.now();
    String dayName = _getDayName(now.weekday);
    String monthName = _getMonthName(now.month);
    final timetableState = ref.watch(timetableProvider);
    final timetableNotifier = ref.read(timetableProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const DashboardHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header greeting with Date
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dayName, $monthName ${now.day}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          timetableState.maybeWhen(
                            data: (slots) {
                              int todayClassCount = timetableNotifier.getClassesForDay(now.weekday).length;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black, width: 1.5),
                                ),
                                child: Text(
                                  todayClassCount > 0 
                                      ? '⚡ $todayClassCount classes scheduled today'
                                      : '🎉 No classes today!',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            },
                            orElse: () => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    
                    // Live class card
                    const LiveClassCard(),
                    
                    // Upcoming classes list
                    const UpcomingClassesList(),
                    
                    // Mess Menu Preview
                    const MessMenuPreview(),
                    
                    // Attendance Widget
                    const AttendanceHealthWidget(),
                    
                    // CGPA Preview
                    const CgpaPreviewWidget(),
                    
                    // Academic Calendar Preview
                    const AcademicCalendarWidget(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'Jan';
      case 2: return 'Feb';
      case 3: return 'Mar';
      case 4: return 'Apr';
      case 5: return 'May';
      case 6: return 'Jun';
      case 7: return 'Jul';
      case 8: return 'Aug';
      case 9: return 'Sep';
      case 10: return 'Oct';
      case 11: return 'Nov';
      case 12: return 'Dec';
      default: return '';
    }
  }
}
