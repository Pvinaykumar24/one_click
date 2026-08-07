import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/app_update_service.dart';

class LiveUpdateBanner extends ConsumerWidget {
  const LiveUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUpdateState = ref.watch(appUpdateProvider);

    return asyncUpdateState.when(
      data: (updateState) {
        debugPrint('🎨 [LIVE UPDATE BANNER] Rebuilding: announcement="${updateState.manifest?.liveAnnouncement}", updateAvailable=${updateState.hasUpdateAvailable}');
        if (updateState.manifest == null) return const SizedBox.shrink();

        final manifest = updateState.manifest!;
        final hasAnnouncement = manifest.liveAnnouncement.trim().isNotEmpty;
        final hasUpdate = updateState.hasUpdateAvailable;

        if (!hasAnnouncement && !hasUpdate) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            // 1. Live Real-Time Announcement Banner
            if (hasAnnouncement)
              Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.neoPink,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(3, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: const Icon(Icons.campaign, color: Colors.black, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LIVE ANNOUNCEMENT ⚡',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        manifest.liveAnnouncement,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // 2. Real-Time Version OTA Update Card
        if (hasUpdate)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.neoYellow,
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
                          child: const Icon(Icons.system_update_alt, color: Colors.black, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Update Available: v${manifest.versionName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    if (manifest.isMandatory)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.neoPink,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: const Text('REQUIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
                      ),
                  ],
                ),
                if (manifest.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    manifest.releaseNotes,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
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
                      final url = manifest.apkDownloadUrl.isNotEmpty
                          ? manifest.apkDownloadUrl
                          : 'https://github.com/Pvinaykumar24/one_click/releases';
                      ref.read(appUpdateProvider.notifier).launchUpdateUrl(url);
                    },
                    icon: const Icon(Icons.download_for_offline, color: AppColors.neoYellow, size: 18),
                    label: const Text('Update Now ⚡', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
    loading: () => const SizedBox.shrink(),
    error: (e, st) => const SizedBox.shrink(),
  );
}
}
