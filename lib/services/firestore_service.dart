import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Appointments
  Future<void> createAppointment(AppointmentModel appointment) async {
    await _firestore
        .collection('appointments')
        .doc(appointment.id)
        .set(appointment.toMap());

    try {
      // Schedule reminder 1 hour before
      final reminderTime = appointment.date.subtract(const Duration(hours: 1));
      if (reminderTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: appointment.date.hashCode,
          title: 'Appuntamento In Arrivo',
          body: 'Hai un appuntamento tra 1 ora!',
          scheduledDate: reminderTime,
        );
      }
    } catch (e) {
      print("Error scheduling notification: $e");
    }
  }

  Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status.name,
    });
  }

  Future<void> deleteAppointment(String appointmentId) async {
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
      if (status != AppointmentStatus.cancelled.name) {
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
      return const ShopSettingsModel();
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

final barberListProvider = StreamProvider<List<BarberModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getBarbers();
});

final serviceListProvider = StreamProvider<List<ServiceModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getServices();
});

final barberAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, ({String barberId, DateTime date})>((ref, params) {
  return ref.watch(firestoreServiceProvider).getAppointmentsForBarber(params.barberId, params.date);
});

final allBarberAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, String>((ref, barberId) {
  return ref.watch(firestoreServiceProvider).getAllAppointmentsForBarber(barberId);
});

final userAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, String>((ref, userId) {
  return ref.watch(firestoreServiceProvider).getAppointmentsForUser(userId);
});

final allAppointmentsProvider = StreamProvider<List<AppointmentModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllAppointments();
});

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getAllUsers();
});

final shopSettingsProvider = StreamProvider<ShopSettingsModel>((ref) {
  return ref.watch(firestoreServiceProvider).getShopSettings();
});

final guestClientsProvider = StreamProvider<List<Map<String, String>>>((ref) {
  return ref.watch(firestoreServiceProvider).streamGuestClients();
});
