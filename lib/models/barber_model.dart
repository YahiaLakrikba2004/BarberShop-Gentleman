import 'package:equatable/equatable.dart';

enum BarberAvailability {
  available,
  sick,
  vacation,
  dayOff,
  absence, // General absence (Permesso/Assenza)
}

class BarberModel extends Equatable {
  final String id;
  final String name;
  final String imageUrl; // Placeholder or real URL
  final List<String> specialties; // e.g., ['Hair', 'Beard']
  // Working hours: Start and End hour (24h format)
  final int startHour;
  final int endHour;
  // Double shift support: optional break in the middle of the day
  final bool hasDoubleShift;
  final int breakStartHour; // When the break starts (e.g., 12)
  final int breakEndHour;   // When the break ends / afternoon shift starts (e.g., 14)
  /// Giorni in cui la pausa è attiva (1=Lun…7=Dom).
  /// Lista vuota = pausa attiva su tutti i giorni lavorativi (retrocompatibilità).
  final List<int> doubleShiftDays;
  final BarberAvailability availabilityStatus;
  final List<DateTime> unavailableDates; // Specific dates when barber is unavailable
  final List<int> daysOff; // 1=Mon ... 7=Sun
  final bool isBookable;
  /// Orari specifici per giorno: key = weekday (1=Lun…7=Dom), value = [startHour, endHour].
  /// Se un giorno non è presente, si usano startHour/endHour globali.
  final Map<int, List<int>> daySchedule;

  const BarberModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.specialties,
    required this.startHour,
    required this.endHour,
    this.hasDoubleShift = false,
    this.breakStartHour = 12,
    this.breakEndHour = 14,
    this.doubleShiftDays = const [],
    this.availabilityStatus = BarberAvailability.available,
    this.unavailableDates = const [],
    this.daysOff = const [],
    this.isBookable = true,
    this.daySchedule = const {},
  });

  /// Ritorna startHour effettivo per un dato weekday.
  int startHourFor(int weekday) => daySchedule[weekday]?[0] ?? startHour;
  /// Ritorna endHour effettivo per un dato weekday.
  int endHourFor(int weekday) => daySchedule[weekday]?[1] ?? endHour;
  /// True se la pausa pranzo è attiva per il giorno dato.
  bool hasBreakOn(int weekday) =>
      hasDoubleShift &&
      (doubleShiftDays.isEmpty || doubleShiftDays.contains(weekday));

  factory BarberModel.fromMap(Map<String, dynamic> map, String id) {
    Map<int, List<int>> daySchedule = {};
    final rawDay = map['daySchedule'] as Map<String, dynamic>?;
    if (rawDay != null) {
      rawDay.forEach((key, value) {
        final day = int.tryParse(key);
        if (day != null && value is List) {
          daySchedule[day] = value.map((e) => (e as num).toInt()).toList();
        }
      });
    }

    return BarberModel(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      specialties: List<String>.from(map['specialties'] ?? []),
      startHour: map['startHour'] ?? 9,
      endHour: map['endHour'] ?? 18,
      hasDoubleShift: map['hasDoubleShift'] ?? false,
      breakStartHour: map['breakStartHour'] ?? 12,
      breakEndHour: map['breakEndHour'] ?? 14,
      doubleShiftDays: (map['doubleShiftDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      availabilityStatus: BarberAvailability.values.firstWhere(
        (e) => e.name == map['availabilityStatus'],
        orElse: () => BarberAvailability.available,
      ),
      unavailableDates: (map['unavailableDates'] as List<dynamic>?)
          ?.map((ts) => DateTime.fromMillisecondsSinceEpoch(ts as int))
          .toList() ?? [],
      daysOff: (map['daysOff'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      isBookable: map['isBookable'] ?? true,
      daySchedule: daySchedule,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'specialties': specialties,
      'startHour': startHour,
      'endHour': endHour,
      'hasDoubleShift': hasDoubleShift,
      'breakStartHour': breakStartHour,
      'breakEndHour': breakEndHour,
      'doubleShiftDays': doubleShiftDays,
      'availabilityStatus': availabilityStatus.name,
      'unavailableDates': unavailableDates.map((d) => d.millisecondsSinceEpoch).toList(),
      'daysOff': daysOff,
      'isBookable': isBookable,
      'daySchedule': daySchedule.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  BarberModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? specialties,
    int? startHour,
    int? endHour,
    bool? hasDoubleShift,
    int? breakStartHour,
    int? breakEndHour,
    List<int>? doubleShiftDays,
    BarberAvailability? availabilityStatus,
    List<DateTime>? unavailableDates,
    List<int>? daysOff,
    bool? isBookable,
    Map<int, List<int>>? daySchedule,
  }) {
    return BarberModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      specialties: specialties ?? this.specialties,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      hasDoubleShift: hasDoubleShift ?? this.hasDoubleShift,
      breakStartHour: breakStartHour ?? this.breakStartHour,
      breakEndHour: breakEndHour ?? this.breakEndHour,
      doubleShiftDays: doubleShiftDays ?? this.doubleShiftDays,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      unavailableDates: unavailableDates ?? this.unavailableDates,
      daysOff: daysOff ?? this.daysOff,
      isBookable: isBookable ?? this.isBookable,
      daySchedule: daySchedule ?? this.daySchedule,
    );
  }

  @override
  List<Object?> get props => [id, name, imageUrl, specialties, startHour, endHour, hasDoubleShift, breakStartHour, breakEndHour, doubleShiftDays, availabilityStatus, unavailableDates, daysOff, isBookable, daySchedule];
}
