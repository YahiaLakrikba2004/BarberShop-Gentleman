import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/barber_model.dart';
import '../models/service_model.dart';
import '../models/appointment_model.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  // Users
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _firestore.collection('users').doc(userId).update({
      'role': newRole.name,
    });
  }

  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Barbers
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

  // Appointments
  Future<void> createAppointment(AppointmentModel appointment) async {
    await _firestore
        .collection('appointments')
        .doc(appointment.id)
        .set(appointment.toMap());
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
  
  Stream<List<AppointmentModel>> getAppointmentsForBarber(
      String barberId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('appointments')
        .where('barberId', isEqualTo: barberId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppointmentModel.fromMap(doc.data(), doc.id))
          .where((appointment) {
            return appointment.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
                   appointment.date.isBefore(endOfDay);
          })
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
