import 'package:cloud_firestore/cloud_firestore.dart';

class ShopSettingsModel {
  final String announcement;
  final bool isAnnouncementActive;
  final List<DateTime> closures;
  final bool isShopClosedManually;

  const ShopSettingsModel({
    this.announcement = '',
    this.isAnnouncementActive = false,
    this.closures = const [],
    this.isShopClosedManually = false,
  });

  factory ShopSettingsModel.fromMap(Map<String, dynamic> map) {
    return ShopSettingsModel(
      announcement: map['announcement'] ?? '',
      isAnnouncementActive: map['isAnnouncementActive'] ?? false,
      closures: (map['closures'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      isShopClosedManually: map['isShopClosedManually'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'announcement': announcement,
      'isAnnouncementActive': isAnnouncementActive,
      'closures': closures.map((e) => Timestamp.fromDate(e)).toList(),
      'isShopClosedManually': isShopClosedManually,
    };
  }

  ShopSettingsModel copyWith({
    String? announcement,
    bool? isAnnouncementActive,
    List<DateTime>? closures,
    bool? isShopClosedManually,
  }) {
    return ShopSettingsModel(
      announcement: announcement ?? this.announcement,
      isAnnouncementActive: isAnnouncementActive ?? this.isAnnouncementActive,
      closures: closures ?? this.closures,
      isShopClosedManually: isShopClosedManually ?? this.isShopClosedManually,
    );
  }
}
