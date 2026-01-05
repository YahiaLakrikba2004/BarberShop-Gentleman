import 'dart:async';
import 'dart:ui'; 
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  final _onNotificationOpenStr = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationOpen => _onNotificationOpenStr.stream;

  Future<void> initialize() async {
    try {
      // Initialize time zones
      tz.initializeTimeZones();
      if (kDebugMode) print('NotificationService: Time zones initialized');

      // 1. Request permissions (Firebase)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (kDebugMode) print('User granted permission: ${settings.authorizationStatus}');

      // 2. Initialize Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode) print("Notification tapped: ${response.payload}");
          if (response.payload != null) {
            _onNotificationOpenStr.add(response.payload);
          }
        },
      );
      if (kDebugMode) print('NotificationService: Local notifications initialized');

      // 3. Create Android Notification Channel
      try {
        final androidImplementation = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
                
        if (androidImplementation != null) {
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            'high_importance_channel',
            'High Importance Notifications',
            description: 'This channel is used for important notifications.',
            importance: Importance.max,
          );

          await androidImplementation.createNotificationChannel(channel);
          if (kDebugMode) print('NotificationService: Android channel created');

          // Explicitly request notification permission for Android 13+
          final granted = await androidImplementation.requestNotificationsPermission();
          if (kDebugMode) print('NotificationService: Android Notification Permission granted: $granted');
        }
      } catch (e) {
         if (kDebugMode) print("Error creating Android channel: $e");
      }

      // 4. Get and Save Token
      try {
        String? fcmToken;
        if (kIsWeb) {
           // ...
        } else {
           fcmToken = await _firebaseMessaging.getToken();
        }
        if (kDebugMode) print('FCM TOKEN: $fcmToken');
        if (fcmToken != null) {
          await _saveTokenToFirestore(fcmToken);
        }
        
        _firebaseMessaging.onTokenRefresh.listen((token) {
           _saveTokenToFirestore(token);
        });
      } catch (e) {
        if (kDebugMode) print("Error handling FCM Token (ignoring for local notifications): $e");
      }

      // 5. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) print('Got a message whilst in the foreground!');
        
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        // Show standard system notification in foreground
        if (notification != null && android != null) {
          _showForegroundNotification(notification, android);
        }
      });
      
      // 6. Handle Background/Terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          if (message.data.containsKey('path')) {
             _onNotificationOpenStr.add(message.data['path']);
          }
      });
      
      try {
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null && initialMessage.data.containsKey('path')) {
            _onNotificationOpenStr.add(initialMessage.data['path']);
        }
      } catch (e) {
         if (kDebugMode) print("Error getting initial message: $e");
      }
      
    } catch (e) {
      if (kDebugMode) print("CRITICAL ERROR initializing NotificationService: $e");
    }
  }



  Future<NotificationDetails> _getPremiumNotificationDetails({
    String? title,
    String? body,
    String? imagePath, // Optional: Path to custom image (asset)
  }) async {
    final largeIcon = await _getAssetBitmap('assets/images/logo.png');
    
    // Android Style
    StyleInformation? styleInformation;
    if (imagePath != null) {
        final bigPicture = await _getAssetBitmap(imagePath);
        if (bigPicture != null) {
            styleInformation = BigPictureStyleInformation(
                bigPicture,
                largeIcon: largeIcon,
                contentTitle: title != null ? '<b>$title</b>' : null,
                htmlFormatContentTitle: true,
                summaryText: body,
                htmlFormatSummaryText: true,
                hideExpandedLargeIcon: true,
            );
        }
    }
    
    // Fallback to BigText if no image or image failed
    styleInformation ??= BigTextStyleInformation(
          body ?? '',
          htmlFormatBigText: true,
          contentTitle: title != null ? '<b>$title</b>' : null,
          htmlFormatContentTitle: true,
    );

    // iOS Attachments
    List<DarwinNotificationAttachment>? iosAttachments;
    if (imagePath != null) {
        final filePath = await _saveAssetToFile(imagePath);
        if (filePath != null) {
            iosAttachments = [DarwinNotificationAttachment(filePath)];
        }
    }

    return NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFD4AF37),
        largeIcon: largeIcon,
        styleInformation: styleInformation,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
          attachments: iosAttachments,
      ),
    );
  }

  Future<String?> _saveAssetToFile(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      
      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final file = File('${tempDir.path}/$fileName');
      
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      if (kDebugMode) print("Error saving asset to file: $e");
      return null;
    }
  }

  Future<void> _showForegroundNotification(
      RemoteNotification notification, AndroidNotification android) async {
    
    final details = await _getPremiumNotificationDetails(
      title: notification.title,
      body: notification.body,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  // Schedule a local notification
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      if (kDebugMode) print("Attempting to schedule notification: $title at $scheduledDate");
      
      if(!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
         final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
         if(androidImplementation != null) {
            bool? granted = await androidImplementation.requestExactAlarmsPermission();
            if (kDebugMode) print("Exact Alarm Permission Granted: $granted");
         }
      }

      final details = await _getPremiumNotificationDetails(
        title: title,
        body: body,
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details, // Use premium details
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      if (kDebugMode) print("SUCCESS: Notification scheduled: $title");
    } catch (e) {
      if (kDebugMode) print("ERROR Scheduling Notification: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
    if (kDebugMode) print("Notification cancelled: $id");
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        if (kDebugMode) print('FCM Token saved to Firestore for user: ${user.uid}');
      } catch (e) {
        if (kDebugMode) print('Error saving FCM Token: $e');
      }
    }
  }

  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    if (kDebugMode) print("Handling a background message: ${message.messageId}");
  }

  Future<Map<String, dynamic>> debugNotificationPermissions() async {
    final status = <String, dynamic>{};
    
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
       final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
       if (androidImplementation != null) {
         status['areNotificationsEnabled'] = await androidImplementation.areNotificationsEnabled();
       }
    }
    
    final settings = await _firebaseMessaging.getNotificationSettings();
    status['firebaseAuthorizationStatus'] = settings.authorizationStatus.toString();
    
    return status;
  }

  // Keep for legacy/debug system notification testing
  Future<void> showImmediateNotification() async {
    final details = await _getPremiumNotificationDetails(
      title: 'The Gentlemen Club',
      body: 'È il momento di rinnovare il tuo stile.',
      imagePath: 'assets/images/gallery/haircut5.png',
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'The Gentlemen Club',
      'È il momento di rinnovare il tuo stile.',
      details,
      payload: '/booking',
    );
  }

  Future<ByteArrayAndroidBitmap?> _getAssetBitmap(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final Uint8List bytes = byteData.buffer.asUint8List();
      return ByteArrayAndroidBitmap(bytes);
    } catch (e) {
      if (kDebugMode) print("Error loading asset bitmap: $e");
      return null;
    }
  }
}
