import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

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
      print('NotificationService: Time zones initialized');

      // 1. Request permissions (Firebase)
      // ... (existing helper code, we'll keep the logic but maybe wrap parts)
    
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('User granted permission: ${settings.authorizationStatus}');

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
          print("Notification tapped: ${response.payload}");
          if (response.payload != null) {
            _onNotificationOpenStr.add(response.payload);
          }
        },
      );
      print('NotificationService: Local notifications initialized');

      // 3. Create Android Notification Channel
      // Only for Android
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
          print('NotificationService: Android channel created');

          // Explicitly request notification permission for Android 13+
          final granted = await androidImplementation.requestNotificationsPermission();
          print('NotificationService: Android Notification Permission granted: $granted');
        }
      } catch (e) {
         print("Error creating Android channel: $e");
      }

      // 4. Get and Save Token
      // Wrapped in its own try-catch to not block everything else
      try {
        String? fcmToken;
        if (kIsWeb) {
           // ...
        } else {
           fcmToken = await _firebaseMessaging.getToken();
        }
        print('FCM TOKEN: $fcmToken');
        if (fcmToken != null) {
          await _saveTokenToFirestore(fcmToken);
        }
        
        _firebaseMessaging.onTokenRefresh.listen((token) {
           _saveTokenToFirestore(token);
        });
      } catch (e) {
        print("Error handling FCM Token (ignoring for local notifications): $e");
      }

      // 5. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // ...
        print('Got a message whilst in the foreground!');
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;
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
         print("Error getting initial message: $e");
      }
      
    } catch (e) {
      print("CRITICAL ERROR initializing NotificationService: $e");
    }
  }

  Future<void> _showForegroundNotification(
      RemoteNotification notification, AndroidNotification android) async {
    // ... no changes needed
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
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
      print("Attempting to schedule notification: $title at $scheduledDate");
      
      if(!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
         final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
         if(androidImplementation != null) {
            bool? granted = await androidImplementation.requestExactAlarmsPermission();
            print("Exact Alarm Permission Granted: $granted");
         }
      }

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("SUCCESS: Notification scheduled: $title");
    } catch (e) {
      print("ERROR Scheduling Notification: $e");
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        print('FCM Token saved to Firestore for user: ${user.uid}');
      } catch (e) {
        print('Error saving FCM Token: $e');
      }
    }
  }

  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
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

  Future<void> showImmediateNotification() async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Test Immediato',
      'Se leggi questo, le notifiche funzionano! 🚀',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
