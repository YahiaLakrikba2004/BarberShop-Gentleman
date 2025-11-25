import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/barber_model.dart';
import '../models/service_model.dart';

final seedServiceProvider = Provider<SeedService>((ref) {
  return SeedService(FirebaseFirestore.instance);
});

class SeedService {
  final FirebaseFirestore _firestore;

  SeedService(this._firestore);

  Future<void> seedData() async {
    // Seed Barbers
    final barbers = [
      const BarberModel(
        id: 'barber_1',
        name: 'Marco Rossi',
        imageUrl: '',
        specialties: ['Taglio Classico', 'Barba'],
        startHour: 9,
        endHour: 18,
      ),
      const BarberModel(
        id: 'barber_2',
        name: 'Giuseppe Verdi',
        imageUrl: '',
        specialties: ['Sfumature', 'Hair Tattoo'],
        startHour: 10,
        endHour: 19,
      ),
      const BarberModel(
        id: 'barber_3',
        name: 'Antonio Bianchi',
        imageUrl: '',
        specialties: ['Taglio Moderno', 'Trattamenti'],
        startHour: 9,
        endHour: 17,
      ),
    ];

    for (var barber in barbers) {
      await _firestore.collection('barbers').doc(barber.id).set(barber.toMap());
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
      await _firestore.collection('services').doc(service.id).set(service.toMap());
    }
  }
}
