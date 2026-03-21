import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/barber_model.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';
import 'notification_service.dart';
import '../models/shop_settings_model.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return FirestoreService(FirebaseFirestore.instance, notificationService);
});

class FirestoreService {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;

  FirestoreService(this._firestore, this._notificationService);

  // Users
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> createBarberProfile(UserModel user, {bool isBookable = true}) async { // Add parameter
    final barber = BarberModel(
      id: user.id,
      name: user.name,
      imageUrl: user.imageUrl ?? '',
      specialties: const ['Taglio', 'Barba'], 
      startHour: 9,
      endHour: 20,
      isBookable: isBookable, // Pass it
    );
    await _firestore.collection('barbers').doc(user.id).set(barber.toMap());
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _firestore.collection('users').doc(userId).update({
      'role': newRole.name,
    });

    // Handle Barber Profile Logic
    if (newRole == UserRole.barber) {
      // Create/Ensure Barber profile exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = UserModel.fromMap(userDoc.data()!, userDoc.id);
        await createBarberProfile(userData);
      }
    } else if (newRole == UserRole.client) {
      // Demoted to Client: REMOVE Barber profile
      await _firestore.collection('barbers').doc(userId).delete();
    }
    // If Admin: DO NOTHING. 
    // This allows an Admin to HAVE a barber profile (if created via auth) 
    // or NOT have one (default). We don't auto-delete it.
  }

  Future<void> updateUserFields(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());

    // Also update the linked barber profile if it exists (since IDs are shared)
    final barberDoc = await _firestore.collection('barbers').doc(user.id).get();
    if (barberDoc.exists) {
      await _firestore.collection('barbers').doc(user.id).update({
        'name': user.name,
        'imageUrl': user.imageUrl,
      });
    }
  }

  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
    // Also delete from barbers collection if it exists (safe to call even if not exists)
    await _firestore.collection('barbers').doc(userId).delete();
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  Future<UserModel?> getUser(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (snapshot.exists) {
      return UserModel.fromMap(snapshot.data()!, snapshot.id);
    }
    return null;
  }

  Future<UserModel?> getUserByPhone(String phoneNumber, {String? excludeUserId}) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(5) // Fetch a few in case of duplicates
        .get();
        
    for (var doc in snapshot.docs) {
       if (excludeUserId != null && doc.id == excludeUserId) continue;
       return UserModel.fromMap(doc.data(), doc.id);
    }
    return null;
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Update barber availability and daysOff
  Future<void> updateBarberAvailability(String barberId, Map<String, dynamic> data) async {
    await _firestore.collection('barbers').doc(barberId).update(data);
  }

  Future<void> updateBarber(BarberModel barber) async {
    await _firestore.collection('barbers').doc(barber.id).update(barber.toMap());
    
    // Also update the linked user profile if it exists (since IDs are shared)
    final userDoc = await _firestore.collection('users').doc(barber.id).get();
    if (userDoc.exists) {
      await _firestore.collection('users').doc(barber.id).update({
        'name': barber.name,
        'imageUrl': barber.imageUrl,
      });
    }
  }

  Stream<List<BarberModel>> getBarbers() {
    return _firestore.collection('barbers').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BarberModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Services
  Stream<List<ServiceModel>> getServices() {
    return _firestore.collection('services').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> createService(ServiceModel service) async {
    await _firestore.collection('services').doc(service.id).set(service.toMap());
  }

  Future<void> updateService(ServiceModel service) async {
    await _firestore
        .collection('services')
        .doc(service.id)
        .update(service.toMap());
  }

  Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).delete();
  }

  // ── OneSignal helpers ──────────────────────────────────────────────────────

  Future<String?> _getOneSignalId(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['oneSignalId'] as String?;
  }

  Future<List<String>> _getAdminOneSignalIds() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    return snapshot.docs
        .map((d) => d.data()['oneSignalId'] as String?)
        .whereType<String>()
        .toList();
  }

  // ── Appointments ────────────────────────────────────────────────────────────

  Future<void> createAppointment(AppointmentModel appointment) async {
    await _firestore
        .collection('appointments')
        .doc(appointment.id)
        .set(appointment.toMap());

    try {
      final now = DateTime.now();
      final dateLabel = DateFormat('dd/MM alle HH:mm').format(appointment.date);
      final customerOneSignalId = await _getOneSignalId(appointment.customerId);

      // 1h reminder → OneSignal schedulata
      final reminder1h = appointment.date.subtract(const Duration(hours: 1));
      if (reminder1h.isAfter(now) && customerOneSignalId != null) {
        await _notificationService.scheduleOneSignalNotification(
          oneSignalId: customerOneSignalId,
          title: 'Appuntamento tra 1 ora',
          body: 'Tra poco hai ${appointment.serviceName} con ${appointment.barberName}!',
          scheduledDate: reminder1h,
          externalId: '${appointment.id}_1h',
        );
      }

      // 24h reminder → OneSignal schedulata
      final reminder24h = appointment.date.subtract(const Duration(hours: 24));
      if (reminder24h.isAfter(now) && customerOneSignalId != null) {
        await _notificationService.scheduleOneSignalNotification(
          oneSignalId: customerOneSignalId,
          title: 'Appuntamento domani',
          body: 'Domani $dateLabel hai ${appointment.serviceName} con ${appointment.barberName}.',
          scheduledDate: reminder24h,
          externalId: '${appointment.id}_24h',
        );
      }

      // Notifica immediata all'admin → nuova prenotazione
      final adminIds = await _getAdminOneSignalIds();
      for (final adminId in adminIds) {
        await _notificationService.scheduleOneSignalNotification(
          oneSignalId: adminId,
          title: 'Nuova prenotazione',
          body: '${appointment.customerName} ha prenotato ${appointment.serviceName} il $dateLabel.',
        );
      }

      // Re-engagement: 21 giorni dopo (locale va bene, è a lungo termine)
      final reengageId = appointment.customerId.hashCode.abs() % 1000000 + 2000000;
      await _notificationService.cancelNotification(reengageId);
      final reengageTime = appointment.date.add(const Duration(days: 21));
      if (reengageTime.isAfter(now)) {
        await _notificationService.scheduleNotification(
          id: reengageId,
          title: 'È ora di tornare! 💈',
          body: 'Sono passate 3 settimane. Prenota il prossimo appuntamento da The Gentlemen.',
          scheduledDate: reengageTime,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
    }
  }

  Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status.name,
    });

    try {
      final doc = await _firestore.collection('appointments').doc(appointmentId).get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final customerId = data['customerId'] as String?;
      final serviceName = data['serviceName'] as String? ?? 'appuntamento';
      final date = (data['date'] as Timestamp).toDate();
      final dateLabel = DateFormat('dd/MM alle HH:mm').format(date);

      if (customerId == null) return;
      final oneSignalId = await _getOneSignalId(customerId);
      if (oneSignalId == null) return;

      if (status == AppointmentStatus.confirmed) {
        await _notificationService.scheduleOneSignalNotification(
          oneSignalId: oneSignalId,
          title: 'Prenotazione confermata',
          body: 'Il tuo $serviceName del $dateLabel è confermato!',
        );
      } else if (status == AppointmentStatus.cancelled) {
        await _notificationService.cancelOneSignalNotification('${appointmentId}_1h');
        await _notificationService.cancelOneSignalNotification('${appointmentId}_24h');
        await _notificationService.scheduleOneSignalNotification(
          oneSignalId: oneSignalId,
          title: 'Appuntamento cancellato',
          body: 'Il tuo $serviceName del $dateLabel è stato cancellato.',
        );
      }
    } catch (e) {
      debugPrint('Error sending status notification: $e');
    }
  }

  Future<void> queueNotificationForUser(
    String userId,
    String title,
    String body, {
    String? path,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('pendingNotifications')
        .add({
      'title': title,
      'body': body,
      'path': path,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> queueAnnouncementToAllClients(String announcementText) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'client')
        .get();

    final oneSignalIds = <String>[];
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final oneSignalId = data['oneSignalId'] as String?;

      if (oneSignalId != null) {
        oneSignalIds.add(oneSignalId);
      } else {
        // Fallback pendingNotifications per chi non ha ancora OneSignal ID
        final notifRef = _firestore
            .collection('users')
            .doc(doc.id)
            .collection('pendingNotifications')
            .doc();
        batch.set(notifRef, {
          'title': 'The Gentlemen',
          'body': announcementText,
          'path': '/',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Push OneSignal a tutti in una sola chiamata
    if (oneSignalIds.isNotEmpty) {
      await _notificationService.sendOneSignalToMany(
        oneSignalIds: oneSignalIds,
        title: 'The Gentlemen',
        body: announcementText,
      );
    }

    if (snapshot.docs.isNotEmpty) await batch.commit();
  }

  Future<void> deleteAppointment(String appointmentId) async {
    try {
      final doc = await _firestore.collection('appointments').doc(appointmentId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final customerId = data['customerId'] as String?;
        final serviceName = data['serviceName'] as String? ?? 'appuntamento';
        final date = (data['date'] as Timestamp).toDate();
        final dateLabel = DateFormat('dd/MM alle HH:mm').format(date);

        // Cancella reminder schedulati
        await _notificationService.cancelOneSignalNotification('${appointmentId}_1h');
        await _notificationService.cancelOneSignalNotification('${appointmentId}_24h');

        // Notifica il cliente
        if (customerId != null) {
          final oneSignalId = await _getOneSignalId(customerId);
          if (oneSignalId != null) {
            await _notificationService.scheduleOneSignalNotification(
              oneSignalId: oneSignalId,
              title: 'Appuntamento cancellato',
              body: 'Il tuo $serviceName del $dateLabel è stato cancellato.',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error notifying on delete: $e');
    }
    await _firestore.collection('appointments').doc(appointmentId).delete();
  }

  Stream<List<AppointmentModel>> getAppointmentsForUser(String userId) {
    return _firestore
        .collection('appointments')
        .where('customerId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<int> countAppointmentsForUserInWeek(String userId, DateTime date) async {
    final int daysToSubtract = date.weekday - 1; // 1 (Monday) -> 0, 7 (Sunday) -> 6
    final DateTime startOfWeek = DateTime(date.year, date.month, date.day).subtract(Duration(days: daysToSubtract));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    final snapshot = await _firestore
        .collection('appointments')
        .where('customerId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('date', isLessThan: Timestamp.fromDate(endOfWeek))
        .get();

    int count = 0;
    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] as String?;
      if (status != AppointmentStatus.cancelled.name &&
          status != AppointmentStatus.noShow.name) {
        count++;
      }
    }
    return count;
  }

  Stream<List<AppointmentModel>> getAllAppointmentsForBarber(String barberId) {
    return _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<AppointmentModel>> getAllAppointmentsForCustomer(String customerId) {
    return _firestore
        .collection('appointments')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  Stream<List<AppointmentModel>> getAppointmentsForBarber(
      String barberId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  Stream<List<AppointmentModel>> getAllAppointments() {
     return _firestore
        .collection('appointments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Shop Settings
  Stream<ShopSettingsModel> getShopSettings() {
    return _firestore
        .collection('settings')
        .doc('shop')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return ShopSettingsModel.fromMap(snapshot.data()!);
      }
      return ShopSettingsModel();
    });
  }

  Future<void> updateShopSettings(ShopSettingsModel settings) async {
    await _firestore
        .collection('settings')
        .doc('shop')
        .set(settings.toMap(), SetOptions(merge: true));
  }
  // Guest Clients
  Future<void> saveGuestClient(String name, String phone) async {
    final existing = await _firestore
        .collection('guestClients')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    if (existing.docs.isEmpty) {
      await _firestore.collection('guestClients').add({
        'name': name,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await existing.docs.first.reference.update({'name': name});
    }
  }

  Future<void> deleteGuestClient(String id) async {
    await _firestore.collection('guestClients').doc(id).delete();
  }

  Stream<List<Map<String, String>>> streamGuestClients() {
    return _firestore
        .collection('guestClients')
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs
            .map((d) => {
                  'id': d.id,
                  'name': d.data()['name'] as String? ?? '',
                  'phone': d.data()['phone'] as String? ?? '',
                })
            .toList());
  }

  Future<void> migrateUser(String oldUserId, String newUserId) async {
    // 1. Get Old User Data
    final oldUserDoc = await _firestore.collection('users').doc(oldUserId).get();
    if (!oldUserDoc.exists) return; // Nothing to migrate

    final oldData = oldUserDoc.data()!;
    // Preserve new Auth ID but take everything else
    oldData['id'] = newUserId;
    oldData['email'] = oldData['email'] ?? ''; // Ensure email field exists

    // 2. Get New User Data (Current Login)
    final newUserDoc = await _firestore.collection('users').doc(newUserId).get();
    Map<String, dynamic> newData = {};
    if (newUserDoc.exists && newUserDoc.data() != null) {
      newData = newUserDoc.data()!;
    }

    // 3. Merge Data: Old Data + New Data overrides
    // We want to KEEP the new name/email if the user just entered them.
    // So we start with oldData, but if newData has values, we use them.
    
    // Actually, we want to bring history (from old) to the new profile.
    // So base = oldData.
    // Overrides = newData (Name, Email, Phone, Role if set).
    
    Map<String, dynamic> mergedData = Map<String, dynamic>.from(oldData);
    
    // Specific fields we want to PRESERVE from the NEW registration:
    if (newData.containsKey('name') && newData['name'].toString().isNotEmpty) {
      mergedData['name'] = newData['name'];
    }
    if (newData.containsKey('email') && newData['email'].toString().isNotEmpty && !newData['email'].toString().contains('gentleman.app')) {
       // Only keep new email if it's NOT the fake one, OR if we want to allow overwriting with real email.
       // Actually, the fake email is generated from phone. 
       // If the user input a real email in the new flow, we keep it.
       mergedData['email'] = newData['email'];
    }
    // Always keep the new ID
    mergedData['id'] = newUserId;
    
    // 4. Update New User with Merged Data
    await _firestore.collection('users').doc(newUserId).set(mergedData, SetOptions(merge: true));

    // 3. Migrate Appointments
    final appointmentsSnapshot = await _firestore
        .collection('appointments')
        .where('customerId', isEqualTo: oldUserId)
        .get();

    final batch = _firestore.batch();
    for (var doc in appointmentsSnapshot.docs) {
      batch.update(doc.reference, {'customerId': newUserId});
    }
    await batch.commit();

    // 4. Delete Old User
    await _firestore.collection('users').doc(oldUserId).delete();
  }
}

// Nota: i provider che richiedono auth usano ref.watch su FirebaseAuth.instance.authStateChanges()
// tramite uno StreamProvider intermedio per sincronizzarsi con lo stato auth di Riverpod.

final _firebaseAuthProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.idTokenChanges();
});

final barberListProvider = StreamProvider<List<BarberModel>>((ref) {
  final user = ref.watch(_firebaseAuthProvider).value;
  if (user == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).getBarbers();
});

final serviceListProvider = StreamProvider<List<ServiceModel>>((ref) {
  return ref.read(firestoreServiceProvider).getServices();
});

final barberAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, ({String barberId, DateTime date})>((ref, params) {
  final user = ref.watch(_firebaseAuthProvider).value;
  if (user == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).getAppointmentsForBarber(params.barberId, params.date);
});

final allBarberAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, String>((ref, barberId) {
  final user = ref.watch(_firebaseAuthProvider).value;
  if (user == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).getAllAppointmentsForBarber(barberId);
});

final userAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, String>((ref, userId) {
  final user = ref.watch(_firebaseAuthProvider).value;
  if (user == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).getAppointmentsForUser(userId);
});

final allAppointmentsProvider = StreamProvider<List<AppointmentModel>>((ref) {
  final user = ref.watch(_firebaseAuthProvider).value;
  if (user == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).getAllAppointments();
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllUsers();
});

final shopSettingsProvider = StreamProvider<ShopSettingsModel>((ref) {
  return ref.watch(firestoreServiceProvider).getShopSettings();
});

final guestClientsProvider = StreamProvider<List<Map<String, String>>>((ref) {
  final user = ref.watch(_firebaseAuthProvider).value;
  if (user == null) return const Stream.empty();
  return ref.read(firestoreServiceProvider).streamGuestClients();
});
