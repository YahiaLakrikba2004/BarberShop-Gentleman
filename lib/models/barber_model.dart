import 'package:equatable/equatable.dart';

enum BarberAvailability {
  available,
  sick,
  vacation,
  dayOff,
}

class BarberModel extends Equatable {
  final String id;
  final String name;
  final String imageUrl; // Placeholder or real URL
  final List<String> specialties; // e.g., ['Hair', 'Beard']
  // Simple working hours: Start and End hour (24h format)
  final int startHour;
  final int endHour;
  final BarberAvailability availabilityStatus;
  final List<DateTime> unavailableDates; // Specific dates when barber is unavailable
  final List<int> daysOff; // 1=Mon ... 7=Sun

  const BarberModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.specialties,
    required this.startHour,
    required this.endHour,
    this.availabilityStatus = BarberAvailability.available,
    this.unavailableDates = const [],
    this.daysOff = const [],
  });

  factory BarberModel.fromMap(Map<String, dynamic> map, String id) {
    return BarberModel(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      specialties: List<String>.from(map['specialties'] ?? []),
      startHour: map['startHour'] ?? 9,
      endHour: map['endHour'] ?? 18,
      availabilityStatus: BarberAvailability.values.firstWhere(
        (e) => e.name == map['availabilityStatus'],
        orElse: () => BarberAvailability.available,
      ),
      unavailableDates: (map['unavailableDates'] as List<dynamic>?)
          ?.map((ts) => DateTime.fromMillisecondsSinceEpoch(ts as int))
          .toList() ?? [],
      daysOff: (map['daysOff'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'specialties': specialties,
      'startHour': startHour,
      'endHour': endHour,
      'availabilityStatus': availabilityStatus.name,
      'unavailableDates': unavailableDates.map((d) => d.millisecondsSinceEpoch).toList(),
      'daysOff': daysOff,
    };
  }

  BarberModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? specialties,
    int? startHour,
    int? endHour,
    BarberAvailability? availabilityStatus,
    List<DateTime>? unavailableDates,
    List<int>? daysOff,
  }) {
    return BarberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      specialties: specialties ?? this.specialties,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      unavailableDates: unavailableDates ?? this.unavailableDates,
      daysOff: daysOff ?? this.daysOff,
    );
  }

  @override
  List<Object?> get props => [id, name, imageUrl, specialties, startHour, endHour, availabilityStatus, unavailableDates, daysOff];
}
