import 'package:cloud_firestore/cloud_firestore.dart';

/// Orario di apertura/chiusura del negozio per un singolo giorno.
class ShopDaySchedule {
  final int openHour;
  final int openMinute;
  final int closeHour;
  final int closeMinute;
  final bool isClosed;
  final bool hasBreak;
  final int breakStartHour;
  final int breakStartMinute;
  final int breakEndHour;
  final int breakEndMinute;

  const ShopDaySchedule({
    required this.openHour,
    this.openMinute = 0,
    required this.closeHour,
    this.closeMinute = 0,
    this.isClosed = false,
    this.hasBreak = false,
    this.breakStartHour = 13,
    this.breakStartMinute = 0,
    this.breakEndHour = 15,
    this.breakEndMinute = 0,
  });

  /// Minuti totali dalla mezzanotte per apertura/chiusura/pausa
  int get openTotalMinutes  => openHour * 60 + openMinute;
  int get closeTotalMinutes => closeHour * 60 + closeMinute;
  int get breakStartTotal   => breakStartHour * 60 + breakStartMinute;
  int get breakEndTotal     => breakEndHour * 60 + breakEndMinute;

  factory ShopDaySchedule.fromMap(Map<String, dynamic> map) {
    return ShopDaySchedule(
      openHour:         (map['openHour']         as num?)?.toInt() ?? (map['open']  as num?)?.toInt() ?? 9,
      openMinute:       (map['openMinute']        as num?)?.toInt() ?? 0,
      closeHour:        (map['closeHour']         as num?)?.toInt() ?? (map['close'] as num?)?.toInt() ?? 19,
      closeMinute:      (map['closeMinute']       as num?)?.toInt() ?? 0,
      isClosed:          map['closed']            as bool? ?? false,
      hasBreak:          map['hasBreak']          as bool? ?? false,
      breakStartHour:   (map['breakStartHour']    as num?)?.toInt() ?? (map['breakStart'] as num?)?.toInt() ?? 13,
      breakStartMinute: (map['breakStartMinute']  as num?)?.toInt() ?? 0,
      breakEndHour:     (map['breakEndHour']      as num?)?.toInt() ?? (map['breakEnd']   as num?)?.toInt() ?? 15,
      breakEndMinute:   (map['breakEndMinute']    as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'openHour':         openHour,
        'openMinute':       openMinute,
        'closeHour':        closeHour,
        'closeMinute':      closeMinute,
        'closed':           isClosed,
        'hasBreak':         hasBreak,
        'breakStartHour':   breakStartHour,
        'breakStartMinute': breakStartMinute,
        'breakEndHour':     breakEndHour,
        'breakEndMinute':   breakEndMinute,
      };

  ShopDaySchedule copyWith({
    int? openHour, int? openMinute,
    int? closeHour, int? closeMinute,
    bool? isClosed,
    bool? hasBreak,
    int? breakStartHour, int? breakStartMinute,
    int? breakEndHour, int? breakEndMinute,
  }) => ShopDaySchedule(
    openHour:         openHour         ?? this.openHour,
    openMinute:       openMinute       ?? this.openMinute,
    closeHour:        closeHour        ?? this.closeHour,
    closeMinute:      closeMinute      ?? this.closeMinute,
    isClosed:         isClosed         ?? this.isClosed,
    hasBreak:         hasBreak         ?? this.hasBreak,
    breakStartHour:   breakStartHour   ?? this.breakStartHour,
    breakStartMinute: breakStartMinute ?? this.breakStartMinute,
    breakEndHour:     breakEndHour     ?? this.breakEndHour,
    breakEndMinute:   breakEndMinute   ?? this.breakEndMinute,
  );
}

/// Orari reali del negozio:
/// Lun–Gio  10:00–20:00 pausa 12:30–14:30
/// Ven      10:00–20:30 pausa 12:30–14:00
/// Sab      09:00–20:00
/// Dom      10:00–18:00
Map<int, ShopDaySchedule> _defaultWeeklySchedule() => {
      1: const ShopDaySchedule(openHour: 10, closeHour: 20, hasBreak: true, breakStartHour: 12, breakStartMinute: 30, breakEndHour: 14, breakEndMinute: 30), // Lun
      2: const ShopDaySchedule(openHour: 10, closeHour: 20, hasBreak: true, breakStartHour: 12, breakStartMinute: 30, breakEndHour: 14, breakEndMinute: 30), // Mar
      3: const ShopDaySchedule(openHour: 10, closeHour: 20, hasBreak: true, breakStartHour: 12, breakStartMinute: 30, breakEndHour: 14, breakEndMinute: 30), // Mer
      4: const ShopDaySchedule(openHour: 10, closeHour: 20, hasBreak: true, breakStartHour: 12, breakStartMinute: 30, breakEndHour: 14, breakEndMinute: 30), // Gio
      5: const ShopDaySchedule(openHour: 10, closeHour: 20, closeMinute: 30, hasBreak: true, breakStartHour: 12, breakStartMinute: 30, breakEndHour: 14), // Ven
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
