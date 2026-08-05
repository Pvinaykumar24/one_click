import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A small chip shown when data is being served from the local Hive cache
/// rather than live from Firestore. Disappears once fresh data arrives.
///
/// Usage:
/// ```dart
/// if (meta.fromCache)
///   CacheIndicator(lastUpdated: meta.lastUpdated),
/// ```
class CacheIndicator extends StatelessWidget {
  final DateTime? lastUpdated;

  const CacheIndicator({super.key, this.lastUpdated});

  String _relativeTime() {
    if (lastUpdated == null) return 'cached';
    final diff = DateTime.now().difference(lastUpdated!);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.history,
            size: 12,
            color: AppColors.warning,
          ),
          const SizedBox(width: 5),
          Text(
            'cached · last updated ${_relativeTime()}',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.warning,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
