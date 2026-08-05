import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'base_step.dart';

class ReadyStep extends StatelessWidget {
  final VoidCallback onComplete;

  const ReadyStep({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return BaseStep(
      title: 'Ready to Launch',
      subtitle: 'Your dashboard is personalized and ready for action.',
      nextLabel: 'Go to Dashboard',
      onNext: onComplete,
      child: const Icon(
        Icons.rocket_launch,
        size: 100,
        color: AppColors.neonPink,
      ),
    );
  }
}
