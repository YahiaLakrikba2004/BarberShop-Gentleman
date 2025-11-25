import 'package:equatable/equatable.dart';

class BarberModel extends Equatable {
  final String id;
  final String name;
  final String imageUrl; // Placeholder or real URL
  final List<String> specialties; // e.g., ['Hair', 'Beard']
  // Simple working hours: Start and End hour (24h format)
  final int startHour; 
  final int endHour;

  const BarberModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.specialties,
    required this.startHour,
    required this.endHour,
  });

  factory BarberModel.fromMap(Map<String, dynamic> map, String id) {
    return BarberModel(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      specialties: List<String>.from(map['specialties'] ?? []),
      startHour: map['startHour'] ?? 9,
      endHour: map['endHour'] ?? 18,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'specialties': specialties,
      'startHour': startHour,
      'endHour': endHour,
    };
  }

  @override
  List<Object?> get props => [id, name, imageUrl, specialties, startHour, endHour];
}
