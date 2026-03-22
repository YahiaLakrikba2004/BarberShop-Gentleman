import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../firebase_options.dart';
import '../models/appointment_model.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationOpenProvider = StreamProvider<String?>((ref) {
  return ref.watch(notificationServiceProvider).onNotificationOpen;
});

class NotificationService {
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final _onNotificationOpenStr = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationOpen => _onNotificationOpenStr.stream;

  Future<void> initialize() async {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Rome'));

      // 1. Request FCM permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (kDebugMode) {
        debugPrint(
            'FCM permission: ${settings.authorizationStatus}');
      }

      // iOS: show notifications in foreground
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Init local notifications
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null) {
            _onNotificationOpenStr.add(response.payload);
          }
        },
      );

      // 3. Android channel + permissions
      try {
        final android = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (android != null) {
          await android.createNotificationChannel(
            const AndroidNotificationChannel(
              'high_importance_channel',
              'High Importance Notifications',
              description: 'Used for important notifications.',
              importance: Importance.max,
            ),
          );
          await android.requestNotificationsPermission();
          await android.requestExactAlarmsPermission();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Android channel error: $e');
      }

      // 4. Save FCM token
      try {
        if (!kIsWeb) {
          final token = await _firebaseMessaging.getToken();
          if (kDebugMode) debugPrint('FCM TOKEN: $token');

          if (Platform.isIOS) {
            final apns = await _firebaseMessaging.getAPNSToken();
            if (kDebugMode) debugPrint('APNS TOKEN: $apns');
          }

          if (token != null) await _saveTokenToFirestore(token);
          _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('FCM token error: $e');
      }

      // 5. Foreground message handler
      // iOS: setForegroundNotificationPresentationOptions already handles display natively.
      // Android: we must show a local notification manually.
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification != null && !Platform.isIOS) {
          _showForegroundNotification(notification);
        }
      });

      // 6. Background tap → navigation
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (message.data.containsKey('route')) {
          _onNotificationOpenStr.add(message.data['route']);
        }
      });

      try {
        final initial = await _firebaseMessaging.getInitialMessage();
        if (initial != null && initial.data.containsKey('route')) {
          _onNotificationOpenStr.add(initial.data['route']);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Initial message error: $e');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('CRITICAL: NotificationService init error: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android'),
      }, SetOptions(merge: true));
      if (kDebugMode) debugPrint('FCM token saved for ${user.uid}');
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> _showForegroundNotification(
      RemoteNotification notification) async {
    if (kIsWeb) return;
    final body = notification.body ?? '';
    final details = await _buildNotificationDetails(body: body);
    // Use positive unique ID (hashCode can be negative on Android)
    final id = notification.hashCode.abs() % 100000;
    await _localNotifications.show(
      id,
      notification.title,
      body,
      details,
    );
  }

  Future<NotificationDetails> _buildNotificationDetails({
    String body = '',
    String? imagePath,
  }) async {
    final largeIcon = await _getAssetBitmap('assets/images/logo.png');

    StyleInformation? style;
    if (imagePath != null) {
      final bigPic = await _getAssetBitmap(imagePath);
      if (bigPic != null) {
        style = BigPictureStyleInformation(
          bigPic,
          largeIcon: largeIcon,
          hideExpandedLargeIcon: true,
        );
      }
    }
    style ??= BigTextStyleInformation(
      body,
      htmlFormatBigText: false,
    );

    List<DarwinNotificationAttachment>? iosAttachments;
    if (imagePath != null) {
      final path = await _saveAssetToFile(imagePath);
      if (path != null) iosAttachments = [DarwinNotificationAttachment(path)];
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'Used for important notifications.',
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFD4AF37),
        largeIcon: largeIcon,
        styleInformation: style,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: iosAttachments,
      ),
    );
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
    String? imagePath,
  }) async {
    if (kIsWeb) return;
    final details = await _buildNotificationDetails(body: body, imagePath: imagePath);
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) return;
    try {
      final details = await _buildNotificationDetails();
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Schedule notification error: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _localNotifications.cancel(id);
  }

  /// Deliver notifications queued in Firestore (pendingNotifications subcollection)
  Future<void> deliverPendingNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('pendingNotifications')
          .orderBy('createdAt')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final title = data['title'] as String? ?? 'The Gentlemen';
        final body = data['body'] as String? ?? '';
        final path = data['path'] as String?;
        await showImmediateNotification(title: title, body: body, payload: path);
        await doc.reference.delete();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error delivering pending notifications: $e');
    }
  }

  /// No-op: reminders are now handled by Cloud Functions
  Future<void> rescheduleAllAppointments(
      List<AppointmentModel> appointments) async {}

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase init in background: $e');
    }

    if (kDebugMode) debugPrint('Background message: ${message.messageId}');

    if (message.notification == null && message.data.isNotEmpty) {
      final title = message.data['title'] ?? 'The Gentlemen';
      final body = message.data['body'] ?? '';
      final route = message.data['route'];

      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await plugin.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFFD4AF37),
          ),
        ),
        payload: route,
      );
    }
  }

  Future<ByteArrayAndroidBitmap?> _getAssetBitmap(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      return ByteArrayAndroidBitmap(byteData.buffer.asUint8List());
    } catch (e) {
      return null;
    }
  }

  Future<String?> _saveAssetToFile(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${assetPath.split('/').last}');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file.path;
    } catch (e) {
      return null;
    }
  }
}
