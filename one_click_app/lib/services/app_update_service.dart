import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
    int parsedBuildNumber = 1;
    final b = map['buildNumber'];
    if (b != null) {
      if (b is int) {
        parsedBuildNumber = b;
      } else if (b is num) {
        parsedBuildNumber = b.toInt();
      } else if (b is String) {
        parsedBuildNumber = int.tryParse(b) ?? 1;
      }
    }

    DateTime parsedDate = DateTime.now();
    final d = map['lastUpdated'];
    if (d != null) {
      if (d is Timestamp) {
        parsedDate = d.toDate();
      } else if (d is String) {
        parsedDate = DateTime.tryParse(d) ?? DateTime.now();
      }
    }

    return AppUpdateManifest(
      versionName: map['versionName']?.toString() ?? '1.0.0',
      buildNumber: parsedBuildNumber,
      isMandatory: map['isMandatory'] == true,
      releaseNotes: map['releaseNotes']?.toString() ?? '',
      apkDownloadUrl: map['apkDownloadUrl']?.toString() ?? '',
      liveAnnouncement: map['liveAnnouncement']?.toString() ?? '',
      featureFlags: map['featureFlags'] is Map ? Map<String, dynamic>.from(map['featureFlags']) : {},
      lastUpdated: parsedDate,
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
    debugPrint('📡 [APP UPDATE SERVICE] Connecting to Firestore app_config/latest stream...');
    return _db
        .collection('app_config')
        .doc('latest')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        debugPrint('⚠️ [APP UPDATE SERVICE] app_config/latest doc does not exist or is empty.');
        return AppUpdateState(
          currentVersion: installedVersion,
          currentBuildNumber: installedBuild,
        );
      }

      final data = doc.data()!;
      debugPrint('📡 [APP UPDATE SERVICE] Received doc snapshot: $data');

      final manifest = AppUpdateManifest.fromMap(data);
      bool hasUpdate = manifest.buildNumber > installedBuild;

      debugPrint('⚡ [APP UPDATE SERVICE] Manifest loaded! liveAnnouncement: "${manifest.liveAnnouncement}", hasUpdate: $hasUpdate');

      return AppUpdateState(
        manifest: manifest,
        hasUpdateAvailable: hasUpdate,
        currentVersion: installedVersion,
        currentBuildNumber: installedBuild,
      );
    }).handleError((e, st) {
      debugPrint('❌ [APP UPDATE SERVICE STREAM ERROR]: $e');
      debugPrint(st.toString());
      return AppUpdateState(
        currentVersion: installedVersion,
        currentBuildNumber: installedBuild,
      );
    });
  }

  /// Admin method: Broadcasts an instant OTA live update and announcement doc in Firestore (Free Tier)
  Future<String?> publishLiveUpdate({
    required String versionName,
    required int buildNumber,
    required String releaseNotes,
    required String apkUrl,
    required String announcement,
    required bool isMandatory,
  }) async {
    try {
      final manifestMap = {
        'versionName': versionName,
        'buildNumber': buildNumber,
        'isMandatory': isMandatory,
        'releaseNotes': releaseNotes,
        'apkDownloadUrl': apkUrl,
        'liveAnnouncement': announcement,
        'featureFlags': {},
        'lastUpdated': Timestamp.now(),
      };

      debugPrint('🚀 [OTA LIVE UPDATE] Writing to Firestore app_config/latest: $manifestMap');
      await _db
          .collection('app_config')
          .doc('latest')
          .set(manifestMap);

      debugPrint('🚀 [OTA LIVE UPDATE] Successfully published to Firestore!');
      return null; // Null means SUCCESS
    } on FirebaseException catch (fe) {
      final err = 'Firebase [${fe.code}]: ${fe.message}';
      debugPrint('❌ [OTA LIVE UPDATE FIREBASE ERROR]: $err');
      return err;
    } catch (e, stack) {
      final err = 'Error: $e';
      debugPrint('❌ [OTA LIVE UPDATE WRITE ERROR]: $err\n$stack');
      return err;
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
