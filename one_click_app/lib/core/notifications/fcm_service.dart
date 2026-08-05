import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../firebase_options.dart';
import 'local_notifications_service.dart' hide NotificationSettings;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint('🌙 [FCM] Handling background message: ${message.messageId}');

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final title = message.notification?.title ?? message.data['title'] as String? ?? 'Announcement';
    final body = message.notification?.body ?? message.data['body'] as String? ?? '';
    final type = message.data['type'] as String? ?? 'general';

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      debugPrint('🌙 [FCM] Background push saved to Firestore feed.');
    } catch (e) {
      debugPrint('❌ [FCM] Failed to save background notification: $e');
    }
  }

  // If data-only payload arriving in background, trigger a local banner
  if (message.notification == null && !kIsWeb) {
    final title = message.data['title'] as String? ?? 'New Alert';
    final body = message.data['body'] as String? ?? '';
    await LocalNotificationsService.showInstantNotification(
      id: message.hashCode.abs() % 100000,
      title: title,
      body: body,
    );
  }
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('🔐 [FCM] User granted permission: ${settings.authorizationStatus}');

      final String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }

      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('☀️ [FCM] Foreground push received: ${message.messageId}');
        final title = message.notification?.title ?? message.data['title'] as String? ?? 'New Announcement';
        final body = message.notification?.body ?? message.data['body'] as String? ?? '';
        final type = message.data['type'] as String? ?? 'general';

        await LocalNotificationsService.showInstantNotification(
          id: message.hashCode.abs() % 100000,
          title: title,
          body: body,
        );

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('notifications')
                .add({
              'title': title,
              'body': body,
              'type': type,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });
            debugPrint('☀️ [FCM] Foreground message logged to Firestore notifications.');
          } catch (e) {
            debugPrint('❌ [FCM] Failed to log foreground notification: $e');
          }
        }
      });

      _initialized = true;
      debugPrint('🚀 [FCM] FcmService initialized successfully.');
    } catch (e) {
      debugPrint('⚠️ [FCM] FcmService initialization error: $e');
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('💾 [FCM] Token synced to Firestore for user: ${user.uid}');
      } catch (e) {
        debugPrint('❌ [FCM] Failed to save token to Firestore: $e');
      }
    }
  }
}
