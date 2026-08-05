import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../services/cgpa_service.dart';

class CgpaPreviewWidget extends ConsumerWidget {
  const CgpaPreviewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cgpaState = ref.watch(cgpaProvider);
    final cgpaNotifier = ref.read(cgpaProvider.notifier);

    return cgpaState.maybeWhen(
      data: (stateData) {
        final currentCGPA = cgpaNotifier.calculateCurrentCGPA();
        final predictedCGPA = cgpaNotifier.predictCGPA();
        final targetCGPA = stateData.targetCgpa;
        final isEmpty = stateData.pastSemesters.isEmpty && stateData.currentSubjects.isEmpty;

        return GestureDetector(
          onTap: () => context.push('/cgpa'),
          child: Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(
                          Icons.school,
                          color: AppColors.neonPink,
                          size: 24,
                          shadows: [Shadow(color: AppColors.neonPink, blurRadius: 10)],
                        ),
                        SizedBox(width: 8),
                        Text(
                          'CGPA Predictor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isEmpty)
                  Column(
                    children: [
                      const Icon(Icons.analytics_outlined, color: AppColors.textSecondary, size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'No subjects or semesters added yet',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => context.push('/cgpa'),
                        icon: const Icon(Icons.add, size: 16, color: AppColors.neonPink),
                        label: const Text('Add Grades', style: TextStyle(color: AppColors.neonPink, fontSize: 13, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: AppColors.neonPink.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildValueCard('Current', currentCGPA.toStringAsFixed(2), AppColors.neonPink),
                      Container(width: 1, height: 40, color: const Color(0xFF334155)),
                      _buildValueCard('Target', targetCGPA.toStringAsFixed(1), AppColors.neonCyan),
                      Container(width: 1, height: 40, color: const Color(0xFF334155)),
                      _buildValueCard('Predicted', predictedCGPA.toStringAsFixed(2), AppColors.neonYellow),
                    ],
                  )
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildValueCard(String label, String value, Color accentColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: accentColor,
            shadows: [Shadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 8)],
          ),
        ),
      ],
    );
  }
}
