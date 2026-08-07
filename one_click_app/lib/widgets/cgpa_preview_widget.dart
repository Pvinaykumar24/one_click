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
              color: AppColors.neoPurple,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: const Icon(Icons.school, color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'CGPA Predictor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isEmpty)
                  Column(
                    children: [
                      const Text(
                        'No subjects or semesters added yet',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/cgpa'),
                        icon: const Icon(Icons.add, size: 16, color: Colors.black),
                        label: const Text('Add Grades', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neoYellow,
                          side: const BorderSide(color: Colors.black, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildValueCard('Current', currentCGPA.toStringAsFixed(2), AppColors.neoYellow),
                      Container(width: 2, height: 36, color: Colors.black),
                      _buildValueCard('Target', targetCGPA.toStringAsFixed(1), AppColors.neoCyan),
                      Container(width: 2, height: 36, color: Colors.black),
                      _buildValueCard('Predicted', predictedCGPA.toStringAsFixed(2), AppColors.neoLime),
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

  Widget _buildValueCard(String label, String value, Color chipColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
