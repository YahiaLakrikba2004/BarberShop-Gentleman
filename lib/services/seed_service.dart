import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/barber_model.dart';
import '../models/service_model.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

final seedServiceProvider = Provider<SeedService>((ref) {
  return SeedService(
    ref.read(firestoreServiceProvider),
    ref.read(authServiceProvider),
  );
});

class SeedService {
  final FirestoreService _firestoreService;
  final AuthService _authService;

  SeedService(this._firestoreService, this._authService);

  Future<void> seedData() async {
    // Create Staff Accounts (Auth + Firestore)
    final staff = [
      {
        'email': 'armin@gentleman.it',
        'password': 'password123',
        'name': 'Armin',
        'role': UserRole.barber,
        'specialties': ['Taglio Classico', 'Barba'],
        'startHour': 9,
        'endHour': 18,
        'daysOff': [3, 7],
        'imageUrl': 'assets/images/barber_marco.png',
      },
      {
        'email': 'andrei@gentleman.it',
        'password': 'password123',
        'name': 'Andrei',
        'role': UserRole.barber,
        'specialties': ['Sfumature', 'Hair Tattoo'],
        'startHour': 10,
        'endHour': 19,
        'daysOff': [1, 7],
        'imageUrl': 'assets/images/barber_giuseppe.png',
      },
      {
        'email': 'hamza@gentleman.it',
        'password': 'password123',
        'name': 'Hamza',
        'role': UserRole.barber,
        'specialties': ['Taglio Moderno', 'Trattamenti'],
        'startHour': 9,
        'endHour': 17,
        'daysOff': [1, 2],
        'imageUrl': 'assets/images/barber_antonio.png',
      },
      {
        'email': 'osama@gentleman.it',
        'password': 'password123',
        'name': 'Osama',
        'role': UserRole.admin,
      },
    ];

    for (var member in staff) {
      try {
        // 1. Create Auth User
        await _authService.signUpWithEmailAndPassword(
          email: member['email'] as String,
          password: member['password'] as String,
          name: member['name'] as String,
          role: member['role'] as UserRole,
        );
        
        // 2. If Barber, create BarberModel with same ID
        if (member['role'] == UserRole.barber) {
          // We need the UID. Since signUp doesn't return it directly in our current implementation,
          // we might need to fetch it or modify signUp. 
          // However, AuthService.signUpWithEmailAndPassword creates the Firestore User document.
          // Let's assume we can get the user by email or sign in.
          // Actually, for simplicity in this seed script, let's just sign in to get the UID
          // OR better: modify signUp to return the User, but I just modified it to return void.
          // Let's just use a workaround: The AuthService creates the user in Firestore.
          // We can't easily get the ID back without changing AuthService again.
          
          // Let's try to sign in to get the UID.
          await _authService.signInWithEmailAndPassword(
            member['email'] as String,
            member['password'] as String,
          );
          final currentUser = _authService.currentUser;
          
          if (currentUser != null) {
            final barber = BarberModel(
              id: currentUser.uid, // Link Auth UID to Barber ID
              name: member['name'] as String,
              imageUrl: member['imageUrl'] as String,
              specialties: member['specialties'] as List<String>,
              startHour: member['startHour'] as int,
              endHour: member['endHour'] as int,
              daysOff: member['daysOff'] as List<int>,
            );
            await _firestoreService.updateBarberAvailability(barber.id, barber.toMap());
          }
        }
      } catch (e) {
        print('Error creating account for ${member['email']}: $e');
        // If user already exists, we might want to update the BarberModel anyway.
        // But we don't have the password to sign in if it's not the default.
        // Assuming this is a fresh run or we accept skipping existing users.
      }
    }

    // Seed Services
    final services = [
      const ServiceModel(
        id: 'service_1',
        name: 'Taglio Capelli',
        durationMinutes: 30,
        price: 25.0,
        description: 'Taglio completo con lavaggio e styling.',
      ),
      const ServiceModel(
        id: 'service_2',
        name: 'Regolazione Barba',
        durationMinutes: 20,
        price: 15.0,
        description: 'Modellatura e rifinitura barba con panno caldo.',
      ),
      const ServiceModel(
        id: 'service_3',
        name: 'Taglio + Barba',
        durationMinutes: 50,
        price: 35.0,
        description: 'Pacchetto completo per un look perfetto.',
      ),
    ];

    for (var service in services) {
      await _firestoreService.createService(service);
    }
  }
}
