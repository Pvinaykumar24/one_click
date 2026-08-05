import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/onboarding_service.dart';
import '../../../services/timetable_service.dart';
import '../../../services/cgpa_service.dart';
import 'widgets/welcome_step.dart';
import 'widgets/semester_step.dart';
import 'widgets/past_performance_step.dart';
import 'widgets/timetable_step.dart';
import 'widgets/ready_step.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final _pageController = PageController();

  // Step 1: Semester Info
  String _semester = '1';
  String _college = '';
  String _department = 'CSE';
  String _degreeType = 'B.Tech';
  final Map<int, double> _pastSgpas = {};

  // Step 2: Timetable Setup
  List<Map<String, dynamic>> _onboardingSlots = [];

  void _nextStep() {
    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding({
      'college': _college,
      'semester': int.parse(_semester),
      'department': _department,
      'degree': _degreeType,
    });

    // Save historical SGPAs
    List<SemesterData> sems = [];
    _pastSgpas.forEach((sem, sgpa) {
      sems.add(
        SemesterData(name: 'Semester $sem', sgpa: sgpa, totalCredits: 20),
      ); // Assuming default 20 credits per past sem
    });
    if (sems.isNotEmpty) {
      final cgpaNotifier = ref.read(cgpaProvider.notifier);
      cgpaNotifier.pastSemesters = sems;
      cgpaNotifier.degreeType = _degreeType;
      await cgpaNotifier.recalculate();
    }

    await ref.read(timetableProvider.notifier).addSlots(_onboardingSlots);
    await ref.read(cgpaProvider.notifier).syncFromTimetable();
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  WelcomeStep(onNext: _nextStep),
                  SemesterStep(
                    initialCollege: _college,
                    initialDegreeType: _degreeType,
                    initialSemester: _semester,
                    initialDepartment: _department,
                    onCollegeChanged: (val) => _college = val,
                    onDegreeTypeChanged: (val) => _degreeType = val,
                    onSemesterChanged: (val) => _semester = val,
                    onDepartmentChanged: (val) => _department = val,
                    onNext: () {
                      int currentSem = int.parse(_semester);
                      if (currentSem == 1) {
                        // Skip past performance step (Step 2)
                        _pageController.animateToPage(
                          3,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        setState(() => _currentStep = 3);
                      } else {
                        _nextStep();
                      }
                    },
                  ),
                  PastPerformanceStep(
                    currentSemester: int.parse(_semester),
                    pastSgpas: _pastSgpas,
                    onSgpaChanged: (sem, sgpa) => _pastSgpas[sem] = sgpa,
                    onNext: _nextStep,
                  ),
                  TimetableStep(
                    slots: _onboardingSlots,
                    onSlotsChanged: (slots) => setState(() => _onboardingSlots = slots),
                    onNext: _nextStep,
                  ),
                  ReadyStep(onComplete: _completeOnboarding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: List.generate(5, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index <= _currentStep
                    ? AppColors.primary
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
