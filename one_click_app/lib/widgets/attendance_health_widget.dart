import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../services/attendance_service.dart';

class AttendanceHealthWidget extends ConsumerWidget {
  const AttendanceHealthWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceProvider);
    final attendanceNotifier = ref.read(attendanceProvider.notifier);

    return attendanceState.maybeWhen(
      data: (records) {
        return GestureDetector(
          onTap: () => context.push('/attendance'),
          child: Container(
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
                        Icon(Icons.analytics, color: AppColors.neonCyan, size: 22,
                            shadows: [Shadow(color: AppColors.neonCyan, blurRadius: 10)]),
                        SizedBox(width: 8),
                        Text('Attendance Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${attendanceNotifier.getOverallPercentage().toStringAsFixed(1)}% overall',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Per-course attendance bars
                ...attendanceNotifier.subjects.take(5).map((sub) {
                  var info = attendanceNotifier.getSubjectInfo(sub);
                  double pct = info['currentPercentage'];
                  int safeBunks = info['safeBunksLeft'];
                  double requiredPct = attendanceNotifier.requiredPercentage;
                  bool isWarning = pct < requiredPct;
                  Color barColor = pct >= requiredPct ? AppColors.success 
                      : pct >= (requiredPct - 10.0) ? const Color(0xFFFBBF24) 
                      : AppColors.error;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(sub, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (pct / 100).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [BoxShadow(color: barColor.withValues(alpha: 0.3), offset: Offset(2, 2), blurRadius: 0)],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text('${pct.toStringAsFixed(0)}%', 
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: barColor)),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 50,
                          child: Text(
                            isWarning ? '⚠ Low' : '✓ $safeBunks left',
                            style: TextStyle(fontSize: 9, color: isWarning ? AppColors.error : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                const Center(
                  child: Text('Tap to view full details for each course →', 
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
