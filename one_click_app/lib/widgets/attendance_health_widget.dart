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
        final overallPct = attendanceNotifier.getOverallPercentage();

        return GestureDetector(
          onTap: () => context.push('/attendance'),
          child: Container(
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
                            color: AppColors.neoLime,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: const Icon(Icons.analytics, color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Attendance Health',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neoYellow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        '${overallPct.toStringAsFixed(1)}% overall',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...attendanceNotifier.subjects.take(5).map((sub) {
                  var info = attendanceNotifier.getSubjectInfo(sub);
                  double pct = info['currentPercentage'];
                  int safeBunks = info['safeBunksLeft'];
                  double requiredPct = attendanceNotifier.requiredPercentage;
                  bool isWarning = pct < requiredPct;
                  Color barColor = pct >= requiredPct ? AppColors.neoLime 
                      : pct >= (requiredPct - 10.0) ? AppColors.neoYellow 
                      : AppColors.neoPink;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 54,
                          child: Text(
                            sub,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: (pct / 100).clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '${pct.toStringAsFixed(0)}%', 
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isWarning ? AppColors.neoPink : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black, width: 1),
                          ),
                          child: Text(
                            isWarning ? '⚠ Low' : '✓ $safeBunks',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isWarning ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Tap to view full course details →',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
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
