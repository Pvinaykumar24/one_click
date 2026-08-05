import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'base_step.dart';

class PastPerformanceStep extends StatelessWidget {
  final int currentSemester;
  final Map<int, double> pastSgpas;
  final Function(int, double) onSgpaChanged;
  final VoidCallback onNext;

  const PastPerformanceStep({
    super.key,
    required this.currentSemester,
    required this.pastSgpas,
    required this.onSgpaChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return BaseStep(
      title: 'Previous SGPAs',
      subtitle:
          'Enter your SGPA for each past semester to get a precise CGPA prediction.',
      onNext: onNext,
      child: SizedBox(
        height: 250,
        child: ListView.builder(
          itemCount: currentSemester - 1,
          itemBuilder: (context, index) {
            int sem = index + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(
                    'Semester $sem',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 70,
                    child: TextFormField(
                      initialValue: pastSgpas[sem]?.toString() ?? '',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.neonCyan,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (v) {
                        double? val = double.tryParse(v);
                        if (val != null) {
                          onSgpaChanged(sem, val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
