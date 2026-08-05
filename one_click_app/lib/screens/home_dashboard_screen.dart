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
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$dayName, $monthName ${now.day}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          timetableState.maybeWhen(
                            data: (slots) {
                              int todayClassCount = timetableNotifier.getClassesForDay(now.weekday).length;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    todayClassCount > 0 
                                        ? '$todayClassCount classes today'
                                        : 'No classes today 🎉',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
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

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}
