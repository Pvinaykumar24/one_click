import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class AppUpdateManifest {
  final String versionName;
  final int buildNumber;
  final bool isMandatory;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String liveAnnouncement;
  final Map<String, dynamic> featureFlags;
  final DateTime lastUpdated;

  AppUpdateManifest({
    required this.versionName,
    required this.buildNumber,
    this.isMandatory = false,
    this.releaseNotes = '',
    this.apkDownloadUrl = '',
    this.liveAnnouncement = '',
    this.featureFlags = const {},
    required this.lastUpdated,
  });

  factory AppUpdateManifest.fromMap(Map<String, dynamic> map) {
    return AppUpdateManifest(
      versionName: map['versionName'] as String? ?? '1.0.0',
      buildNumber: map['buildNumber'] as int? ?? 1,
      isMandatory: map['isMandatory'] as bool? ?? false,
      releaseNotes: map['releaseNotes'] as String? ?? '',
      apkDownloadUrl: map['apkDownloadUrl'] as String? ?? '',
      liveAnnouncement: map['liveAnnouncement'] as String? ?? '',
      featureFlags: (map['featureFlags'] as Map<String, dynamic>?) ?? {},
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'versionName': versionName,
      'buildNumber': buildNumber,
      'isMandatory': isMandatory,
      'releaseNotes': releaseNotes,
      'apkDownloadUrl': apkDownloadUrl,
      'liveAnnouncement': liveAnnouncement,
      'featureFlags': featureFlags,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

class AppUpdateState {
  final AppUpdateManifest? manifest;
  final bool hasUpdateAvailable;
  final String currentVersion;
  final int currentBuildNumber;

  AppUpdateState({
    this.manifest,
    this.hasUpdateAvailable = false,
    this.currentVersion = '1.1.0',
    this.currentBuildNumber = 100,
  });
}

class AppUpdateNotifier extends StreamNotifier<AppUpdateState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String installedVersion = '1.1.0';
  static const int installedBuild = 100;

  @override
  Stream<AppUpdateState> build() {
    final authState = ref.watch(authProvider);

    return authState.when(
      data: (user) {
        return _db
            .collection('app_config')
            .doc('latest')
            .snapshots()
            .map((doc) {
          if (!doc.exists || doc.data() == null) {
            return AppUpdateState(
              currentVersion: installedVersion,
              currentBuildNumber: installedBuild,
            );
          }

          final manifest = AppUpdateManifest.fromMap(doc.data()!);
          bool hasUpdate = manifest.buildNumber > installedBuild;

          return AppUpdateState(
            manifest: manifest,
            hasUpdateAvailable: hasUpdate,
            currentVersion: installedVersion,
            currentBuildNumber: installedBuild,
          );
        });
      },
      loading: () => const Stream.empty(),
      error: (e, st) {
        debugPrint('Error streaming app_config: $e');
        return Stream.value(AppUpdateState());
      },
    );
  }

  /// Admin method: Broadcasts an instant OTA live update and announcement doc in Firestore (Free Tier)
  Future<bool> publishLiveUpdate({
    required String versionName,
    required int buildNumber,
    required String releaseNotes,
    required String apkUrl,
    required String announcement,
    required bool isMandatory,
  }) async {
    try {
      final manifest = AppUpdateManifest(
        versionName: versionName,
        buildNumber: buildNumber,
        releaseNotes: releaseNotes,
        apkDownloadUrl: apkUrl,
        liveAnnouncement: announcement,
        isMandatory: isMandatory,
        lastUpdated: DateTime.now(),
      );

      debugPrint('🚀 [OTA LIVE UPDATE] Writing to app_config/latest...');
      await _db
          .collection('app_config')
          .doc('latest')
          .set(manifest.toMap(), SetOptions(merge: true));

      debugPrint('🚀 [OTA LIVE UPDATE] Successfully published to Firestore!');
      return true;
    } catch (e, stack) {
      debugPrint('❌ [OTA LIVE UPDATE ERROR]: $e');
      debugPrint(stack.toString());
      return false;
    }
  }

  /// Triggers 1-click update download in browser / package installer
  Future<void> launchUpdateUrl(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.parse(url.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

final appUpdateProvider =
    StreamNotifierProvider<AppUpdateNotifier, AppUpdateState>(() {
  return AppUpdateNotifier();
});
