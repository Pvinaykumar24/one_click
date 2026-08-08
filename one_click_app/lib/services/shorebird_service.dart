import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

enum ShorebirdUpdateStatus {
  idle,
  checking,
  noUpdate,
  updateAvailable,
  downloading,
  readyToRestart,
  error,
}

class ShorebirdState {
  final bool isAvailable;
  final ShorebirdUpdateStatus status;
  final String? patchVersion;
  final String? errorMessage;

  ShorebirdState({
    required this.isAvailable,
    this.status = ShorebirdUpdateStatus.idle,
    this.patchVersion,
    this.errorMessage,
  });

  ShorebirdState copyWith({
    bool? isAvailable,
    ShorebirdUpdateStatus? status,
    String? patchVersion,
    String? errorMessage,
  }) {
    return ShorebirdState(
      isAvailable: isAvailable ?? this.isAvailable,
      status: status ?? this.status,
      patchVersion: patchVersion ?? this.patchVersion,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ShorebirdNotifier extends StateNotifier<ShorebirdState> {
  final ShorebirdUpdater _updater = ShorebirdUpdater();

  ShorebirdNotifier()
      : super(ShorebirdState(isAvailable: ShorebirdUpdater().isAvailable)) {
    init();
  }

  Future<void> init() async {
    if (!state.isAvailable) {
      debugPrint('ℹ️ [SHOREBIRD] Shorebird CodePush engine not active in debug/unpatched build.');
      return;
    }

    try {
      final currentPatch = await _updater.readCurrentPatch();
      state = state.copyWith(
        patchVersion: currentPatch != null ? 'Patch #${currentPatch.number}' : 'Base Build',
      );
      await checkForUpdate();
    } catch (e) {
      debugPrint('⚠️ [SHOREBIRD INIT ERROR]: $e');
    }
  }

  Future<void> checkForUpdate() async {
    if (!state.isAvailable) return;

    try {
      state = state.copyWith(status: ShorebirdUpdateStatus.checking);
      debugPrint('📡 [SHOREBIRD] Checking for Over-The-Air patches...');

      final updateStatus = await _updater.checkForUpdate();
      if (updateStatus == UpdateStatus.outdated) {
        debugPrint('⚡ [SHOREBIRD] New CodePush patch available! Downloading in background...');
        state = state.copyWith(status: ShorebirdUpdateStatus.updateAvailable);
        await downloadUpdate();
      } else if (updateStatus == UpdateStatus.restartRequired) {
        state = state.copyWith(status: ShorebirdUpdateStatus.readyToRestart);
      } else {
        debugPrint('✅ [SHOREBIRD] App is fully up to date with latest patch.');
        state = state.copyWith(status: ShorebirdUpdateStatus.noUpdate);
      }
    } catch (e) {
      debugPrint('❌ [SHOREBIRD CHECK ERROR]: $e');
      state = state.copyWith(
        status: ShorebirdUpdateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> downloadUpdate() async {
    if (!state.isAvailable) return;

    try {
      state = state.copyWith(status: ShorebirdUpdateStatus.downloading);
      await _updater.update();
      debugPrint('🚀 [SHOREBIRD] CodePush patch downloaded! Ready to restart.');
      state = state.copyWith(status: ShorebirdUpdateStatus.readyToRestart);
    } catch (e) {
      debugPrint('❌ [SHOREBIRD DOWNLOAD ERROR]: $e');
      state = state.copyWith(
        status: ShorebirdUpdateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
}

final shorebirdProvider = StateNotifierProvider<ShorebirdNotifier, ShorebirdState>((ref) {
  return ShorebirdNotifier();
});
