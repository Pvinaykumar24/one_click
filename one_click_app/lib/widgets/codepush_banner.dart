import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/shorebird_service.dart';

class CodePushBanner extends ConsumerWidget {
  const CodePushBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shorebirdState = ref.watch(shorebirdProvider);

    if (!shorebirdState.isAvailable) {
      return const SizedBox.shrink();
    }

    if (shorebirdState.status == ShorebirdUpdateStatus.downloading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.neoYellow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Row(
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '⚡ Downloading instant CodePush patch in background...',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }

    if (shorebirdState.status == ShorebirdUpdateStatus.readyToRestart) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.neoPink,
          borderRadius: BorderRadius.circular(16),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.neoYellow,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: const Icon(Icons.bolt, color: Colors.black, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Instant Patch Ready!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'A new over-the-air update has been downloaded in background without installing any APK.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                onPressed: () {
                  // Prompt user to restart app
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please close and reopen the app to apply the CodePush update! 🚀'),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, color: AppColors.neoYellow, size: 18),
                label: const Text('Restart to Apply Update ⚡', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
