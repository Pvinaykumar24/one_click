import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'base_step.dart';

class WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomeStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return BaseStep(
      title: 'Welcome to\nOne Click',
      subtitle:
          'Your all-in-one academic companion. Let\'s get you set up in less than a minute.',
      onNext: onNext,
      child: const Icon(
        Icons.school,
        size: 100,
        color: AppColors.neonCyan,
      ),
    );
  }
}
