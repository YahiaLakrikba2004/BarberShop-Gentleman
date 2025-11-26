import 'package:equatable/equatable.dart';

enum UserRole { client, barber, admin }

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final String? imageUrl;
  final String? fcmToken;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.imageUrl,
    this.fcmToken,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? phoneNumber,
    String? imageUrl,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.client,
      ),
      phoneNumber: map['phoneNumber'],
      imageUrl: map['imageUrl'],
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      'phoneNumber': phoneNumber,
      'imageUrl': imageUrl,
      'fcmToken': fcmToken,
    };
  }

  @override
  List<Object?> get props => [id, email, name, role, phoneNumber, imageUrl, fcmToken];
}
