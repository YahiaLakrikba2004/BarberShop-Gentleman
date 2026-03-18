import 'package:cloud_firestore/cloud_firestore.dart';

/// Orario di apertura/chiusura del negozio per un singolo giorno.
class ShopDaySchedule {
  final int openHour;
  final int closeHour;
  final bool isClosed;

  const ShopDaySchedule({
    required this.openHour,
    required this.closeHour,
    this.isClosed = false,
  });

  factory ShopDaySchedule.fromMap(Map<String, dynamic> map) {
    return ShopDaySchedule(
      openHour: (map['open'] as num?)?.toInt() ?? 9,
      closeHour: (map['close'] as num?)?.toInt() ?? 19,
      isClosed: map['closed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'open': openHour,
        'close': closeHour,
        'closed': isClosed,
      };

  ShopDaySchedule copyWith({int? openHour, int? closeHour, bool? isClosed}) =>
      ShopDaySchedule(
        openHour: openHour ?? this.openHour,
        closeHour: closeHour ?? this.closeHour,
        isClosed: isClosed ?? this.isClosed,
      );
}

/// Orari reali del negozio:
/// Lun–Gio  10:00–20:00 | Ven 10:00–20:00 | Sab 09:00–20:00 | Dom 10:00–18:00
Map<int, ShopDaySchedule> _defaultWeeklySchedule() => {
      1: const ShopDaySchedule(openHour: 10, closeHour: 20), // Lun
      2: const ShopDaySchedule(openHour: 10, closeHour: 20), // Mar
      3: const ShopDaySchedule(openHour: 10, closeHour: 20), // Mer
      4: const ShopDaySchedule(openHour: 10, closeHour: 20), // Gio
      5: const ShopDaySchedule(openHour: 10, closeHour: 20), // Ven
      6: const ShopDaySchedule(openHour: 9,  closeHour: 20), // Sab
      7: const ShopDaySchedule(openHour: 10, closeHour: 18), // Dom
    };

class ShopSettingsModel {
  final String announcement;
  final bool isAnnouncementActive;
  final List<DateTime> closures;
  final bool isShopClosedManually;
  final List<String> galleryImages;
  /// Orari settimanali: chiave = weekday (1=Lun … 7=Dom)
  final Map<int, ShopDaySchedule> weeklySchedule;

  ShopSettingsModel({
    this.announcement = '',
    this.isAnnouncementActive = false,
    this.closures = const [],
    this.isShopClosedManually = false,
    this.galleryImages = const [],
    Map<int, ShopDaySchedule>? weeklySchedule,
  }) : weeklySchedule = weeklySchedule ?? _defaultWeeklySchedule();

  factory ShopSettingsModel.fromMap(Map<String, dynamic> map) {
    Map<int, ShopDaySchedule> schedule = _defaultWeeklySchedule();
    final raw = map['weeklySchedule'] as Map<String, dynamic>?;
    if (raw != null) {
      raw.forEach((key, value) {
        final day = int.tryParse(key);
        if (day != null && value is Map<String, dynamic>) {
          schedule[day] = ShopDaySchedule.fromMap(value);
        }
      });
    }

    return ShopSettingsModel(
      announcement: map['announcement'] ?? '',
      isAnnouncementActive: map['isAnnouncementActive'] ?? false,
      closures: (map['closures'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      isShopClosedManually: map['isShopClosedManually'] ?? false,
      galleryImages: (map['galleryImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      weeklySchedule: schedule,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'announcement': announcement,
      'isAnnouncementActive': isAnnouncementActive,
      'closures': closures.map((e) => Timestamp.fromDate(e)).toList(),
      'isShopClosedManually': isShopClosedManually,
      'galleryImages': galleryImages,
      'weeklySchedule': weeklySchedule.map(
        (day, s) => MapEntry(day.toString(), s.toMap()),
      ),
    };
  }

  ShopSettingsModel copyWith({
    String? announcement,
    bool? isAnnouncementActive,
    List<DateTime>? closures,
    bool? isShopClosedManually,
    List<String>? galleryImages,
    Map<int, ShopDaySchedule>? weeklySchedule,
  }) {
    return ShopSettingsModel(
      announcement: announcement ?? this.announcement,
      isAnnouncementActive: isAnnouncementActive ?? this.isAnnouncementActive,
      closures: closures ?? this.closures,
      isShopClosedManually: isShopClosedManually ?? this.isShopClosedManually,
      galleryImages: galleryImages ?? this.galleryImages,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
    );
  }
}
