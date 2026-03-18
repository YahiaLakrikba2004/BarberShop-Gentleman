import 'dart:async';
import 'package:flutter/foundation.dart';
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
import 'package:intl/intl.dart';
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
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  final _onNotificationOpenStr = StreamController<String?>.broadcast();
  Stream<String?> get onNotificationOpen => _onNotificationOpenStr.stream;

  Future<void> initialize() async {
    try {
      // Initialize time zones
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Rome'));
      if (kDebugMode) debugPrint('NotificationService: Time zones initialized (Europe/Rome)');

      // 1. Request permissions (Firebase)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (kDebugMode) debugPrint('User granted permission: ${settings.authorizationStatus}');

      // iOS: Enable foreground notifications (banner + sound + badge)
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Initialize Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode) debugPrint("Notification tapped: ${response.payload}");
          if (response.payload != null) {
            _onNotificationOpenStr.add(response.payload);
          }
        },
      );
      if (kDebugMode) debugPrint('NotificationService: Local notifications initialized');

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
          if (kDebugMode) debugPrint('NotificationService: Android channel created');

          // Explicitly request notification permission for Android 13+
          final granted = await androidImplementation.requestNotificationsPermission();
          if (kDebugMode) debugPrint('NotificationService: Android Notification Permission granted: $granted');

          // Request exact alarm permission once at init (Android 12+)
          final exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
          if (kDebugMode) debugPrint('NotificationService: Exact Alarm Permission granted: $exactAlarmGranted');
        }
      } catch (e) {
         if (kDebugMode) debugPrint("Error creating Android channel: $e");
      }

      // 4. Get and Save Token
      try {
        String? fcmToken;
        if (kIsWeb) {
           // ...
        } else {
           fcmToken = await _firebaseMessaging.getToken();
           
           // iOS Special: Check APNS token status
           if (Platform.isIOS) {
             final apnsToken = await _firebaseMessaging.getAPNSToken();
             if (kDebugMode) debugPrint('APNS TOKEN: $apnsToken');
             if (apnsToken == null && kDebugMode) {
               debugPrint('WARNING: APNS Token is null. Push notifications will NOT work on real device until APNS is configured.');
             }
           }
        }
        if (kDebugMode) debugPrint('FCM TOKEN: $fcmToken');
        if (fcmToken != null) {
          await _saveTokenToFirestore(fcmToken);
        }
        
        _firebaseMessaging.onTokenRefresh.listen((token) {
           _saveTokenToFirestore(token);
        });
      } catch (e) {
        if (kDebugMode) debugPrint("Error handling FCM Token: $e");
      }

      // 5. Handle Foreground Messages (Android + iOS)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) debugPrint('Got a message whilst in the foreground: ${message.messageId}');

        RemoteNotification? notification = message.notification;
        
        // Show local notification in foreground on both Android and iOS
        // If it's a notification message, we show it. 
        // If it's data-only, it depends on specific business logic.
        if (notification != null) {
          _showForegroundNotification(notification);
        } else if (message.data.isNotEmpty && kDebugMode) {
          debugPrint("Received data-only message in foreground: ${message.data}");
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
         if (kDebugMode) debugPrint("Error getting initial message: $e");
      }
      
    } catch (e) {
      if (kDebugMode) debugPrint("CRITICAL ERROR initializing NotificationService: $e");
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
      if (kDebugMode) debugPrint("Error saving asset to file: $e");
      return null;
    }
  }

  Future<void> _showForegroundNotification(RemoteNotification notification) async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    try {
      if (kDebugMode) debugPrint("Attempting to schedule notification: $title at $scheduledDate");

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
      if (kDebugMode) debugPrint("SUCCESS: Notification scheduled: $title");
    } catch (e) {
      if (kDebugMode) debugPrint("ERROR Scheduling Notification: $e");
    }
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _localNotifications.cancel(id);
    if (kDebugMode) debugPrint("Notification cancelled: $id");
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Use set with merge to avoid "document not found" errors during update
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': Platform.isIOS ? 'ios' : 'android',
        }, SetOptions(merge: true));
        
        if (kDebugMode) debugPrint('FCM Token saved to Firestore for user: ${user.uid}');
      } catch (e) {
        if (kDebugMode) debugPrint('Error saving FCM Token: $e');
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Firebase init error in background: $e");
    }

    if (kDebugMode) debugPrint("Handling a background message: ${message.messageId}");

    // If it's a data-only message (no notification payload), Android/iOS won't show it automatically.
    // We show a local notification manually.
    if (message.notification == null && message.data.isNotEmpty) {
      final title = message.data['title'] ?? 'Gentleman Barber Shop';
      final body = message.data['body'] ?? 'Nuovo aggiornamento';
      final path = message.data['path'];

      final FlutterLocalNotificationsPlugin localNotif = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      await localNotif.initialize(initializationSettings);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFD4AF37),
      );
      const NotificationDetails details = NotificationDetails(android: androidDetails);

      await localNotif.show(
        message.hashCode,
        title,
        body,
        details,
        payload: path,
      );
    }
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

  // Show an immediate notification
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
    String? imagePath,
  }) async {
    if (kIsWeb) return;
    final details = await _getPremiumNotificationDetails(
      title: title,
      body: body,
      imagePath: imagePath,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
    if (kDebugMode) debugPrint("Immediate notification shown: $title");
  }

  /// Legge le notifiche pendenti da Firestore, le mostra e le cancella.
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

  Future<void> rescheduleAllAppointments(List<AppointmentModel> appointments) async {
    if (kIsWeb) return;
    if (kDebugMode) debugPrint("Rescheduling all ${appointments.length} appointments...");
    
    // Optional: Cancel all existing to ensure clean slate? 
    // For now we just overwrite since we use consistent IDs.
    await _localNotifications.cancelAll(); 

    int scheduledCount = 0;
    final now = DateTime.now();

    for (final apt in appointments) {
      if (apt.date.isAfter(now)) {
        // Schedule 1 hour before
        // This logic mimics the BookingScreen scheduling logic
        // Ideally this logic should be centralized, but duplicating for safety here.
        final scheduledDate = apt.date.subtract(const Duration(hours: 1));
        if (scheduledDate.isAfter(now)) {
             await scheduleNotification(
               id: apt.id.hashCode,
               title: 'Gentleman Barber Shop',
               body: 'Non dimenticare il tuo appuntamento alle ${DateFormat('HH:mm').format(apt.date)}!',
               scheduledDate: scheduledDate,
             );
             scheduledCount++;
        }
      }
    }
    if (kDebugMode) debugPrint("Rescheduled $scheduledCount notifications.");
  }

  Future<ByteArrayAndroidBitmap?> _getAssetBitmap(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final Uint8List bytes = byteData.buffer.asUint8List();
      return ByteArrayAndroidBitmap(bytes);
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading asset bitmap: $e");
      return null;
    }
  }
}
