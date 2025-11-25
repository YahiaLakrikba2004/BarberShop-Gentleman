import 'package:equatable/equatable.dart';

class ServiceModel extends Equatable {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final String description;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.description,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      name: map['name'] ?? '',
      durationMinutes: map['durationMinutes'] ?? 30,
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'durationMinutes': durationMinutes,
      'price': price,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [id, name, durationMinutes, price, description];
}
