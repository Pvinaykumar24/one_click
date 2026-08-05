import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:workmanager/workmanager.dart';
import '../../firebase_options.dart';
import '../../services/assignment_service.dart';
import '../notifications/local_notifications_service.dart';
import '../../services/recurring_transactions_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("⚡ [WORKMANAGER] Executing task: $task");
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("⚡ [WORKMANAGER] No user logged in, skipping background classroom sync.");
        return Future.value(true);
      }

      if (task == 'sync_classroom_task' || task == Workmanager.iOSBackgroundTask) {
        debugPrint("⚡ [WORKMANAGER] Running classroom sync for user: ${user.uid}");
        await LocalNotificationsService.init();
        final assignmentService = AssignmentNotifier();
        await assignmentService.syncWithClassroom(
          isBackground: true,
          triggerNotifications: true,
        );
        await RecurringTransactionsService.processDueTransactions(triggerNotifications: true);
        debugPrint("⚡ [WORKMANAGER] Classroom background sync and recurring transactions processed successfully.");
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("❌ [WORKMANAGER] Background sync error: $e");
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static const String _taskName = 'sync_classroom_task';
  static const String _taskUniqueName = 'one_click_classroom_sync';

  static Future<void> init() async {
    if (kIsWeb) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      debugPrint("⚡ [WORKMANAGER] Workmanager initialized.");

      // Schedule periodic background classroom check every 90 minutes.
      // Note on OS realities:
      // - Android enforces a hard minimum of 15 minutes for periodic tasks and may defer execution during Doze mode.
      // - iOS does NOT support deterministic periodic work intervals via BGTaskScheduler; iOS determines frequency algorithmically based on app usage and battery state.
      await Workmanager().registerPeriodicTask(
        _taskUniqueName,
        _taskName,
        frequency: const Duration(minutes: 90),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );
      debugPrint("⚡ [WORKMANAGER] Periodic background sync task registered (90 min interval).");
    } catch (e) {
      debugPrint("⚠️ [WORKMANAGER] Failed to initialize Workmanager: $e");
    }
  }

  static Future<void> cancelSync() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelByUniqueName(_taskUniqueName);
      debugPrint("⚡ [WORKMANAGER] Cancelled background sync task.");
    } catch (e) {
      debugPrint("⚠️ [WORKMANAGER] Error cancelling sync task: $e");
    }
  }
}
