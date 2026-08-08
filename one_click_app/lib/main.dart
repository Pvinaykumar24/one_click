import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/notifications/local_notifications_service.dart';
import 'core/notifications/fcm_service.dart';
import 'core/background/background_sync_service.dart';
import 'services/timetable_service.dart';
import 'services/recurring_transactions_service.dart';

void main() async {
  debugPrint("🚀 [MAIN] APP STARTING");
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  debugPrint("🚀 [MAIN] SPLASH PRESERVED");

  try {
    debugPrint("🚀 [MAIN] INITIALIZING FIREBASE...");
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("🚀 [MAIN] FIREBASE INITIALIZED NEW");
    } else {
      debugPrint("🚀 [MAIN] FIREBASE ALREADY INITIALIZED");
    }
  } catch (e) {
    debugPrint("🚀 [MAIN] FIREBASE INIT ERROR: $e");
  }

  // Enable Firestore offline persistence for mobile. 
  // Web IndexedDB persistence is known to occasionally deadlock Firebase Auth initialization, so we bypass it on Web.
  if (!kIsWeb) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint("🚀 [MAIN] FIRESTORE PERSISTENCE ENABLED");
  }

  // Initialise Hive and open the two lightweight cache boxes.
  await Hive.initFlutter();
  await Hive.openBox<String>('timetable_cache');
  await Hive.openBox<String>('mess_cache');
  await Hive.openBox<dynamic>('settings_cache');
  debugPrint("🚀 [MAIN] HIVE CACHE READY");

  try {
    await LocalNotificationsService.init();
    debugPrint("🚀 [MAIN] LOCAL NOTIFICATIONS READY");
  } catch (e) {
    debugPrint("🚀 [MAIN] LOCAL NOTIFICATIONS ERROR: $e");
  }

  try {
    await FcmService.init();
    debugPrint("🚀 [MAIN] FCM READY");
  } catch (e) {
    debugPrint("🚀 [MAIN] FCM ERROR: $e");
  }

  try {
    await BackgroundSyncService.init();
    debugPrint("🚀 [MAIN] BACKGROUND SYNC READY");
  } catch (e) {
    debugPrint("🚀 [MAIN] BACKGROUND SYNC ERROR: $e");
  }

  try {
    await RecurringTransactionsService.processDueTransactions();
    debugPrint("🚀 [MAIN] RECURRING TRANSACTIONS PROCESSED");
  } catch (e) {
    debugPrint("🚀 [MAIN] RECURRING TRANSACTIONS ERROR: $e");
  }

  debugPrint("🚀 [MAIN] RUNNING APP...");
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
  
  debugPrint("🚀 [MAIN] REMOVING SPLASH...");
  try {
    FlutterNativeSplash.remove();
    debugPrint("🚀 [MAIN] SPLASH REMOVED");
  } catch (e) {
    debugPrint("🚀 [MAIN] SPLASH REMOVE ERROR: $e");
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    // Automatically synchronize scheduled recurring local notifications when timetable or reminder settings change.
    ref.listen(timetableProvider, (previous, next) {
      next.whenData((slots) {
        final settings = ref.read(notificationSettingsProvider);
        LocalNotificationsService.syncTimetableNotifications(
          slots,
          enabled: settings.enabled,
          minutesBefore: settings.minutesBefore,
        );
      });
    });

    ref.listen(notificationSettingsProvider, (previous, next) {
      final slots = ref.read(timetableProvider).valueOrNull ?? [];
      LocalNotificationsService.syncTimetableNotifications(
        slots,
        enabled: next.enabled,
        minutesBefore: next.minutesBefore,
      );
    });

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Student Academic Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
    );
  }
}
