import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentStatus { pending, confirmed, completed, cancelled }

class AppointmentModel extends Equatable {
  final String id;
  final String customerId;
  final String customerName;
  final String barberId;
  final String barberName;
  final String serviceId;
  final String serviceName;
  final DateTime date; // The start time of the appointment
  final int durationMinutes;
  final double price;
  final AppointmentStatus status;

  const AppointmentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.barberId,
    required this.barberName,
    required this.serviceId,
    required this.serviceName,
    required this.date,
    required this.durationMinutes,
    required this.price,
    required this.status,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      barberId: map['barberId'] ?? '',
      barberName: map['barberName'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      durationMinutes: map['durationMinutes'] ?? 30,
      price: (map['price'] ?? 0).toDouble(),
      status: AppointmentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AppointmentStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'barberId': barberId,
      'barberName': barberName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'date': Timestamp.fromDate(date),
      'durationMinutes': durationMinutes,
      'price': price,
      'status': status.name,
    };
  }

  DateTime get endTime => date.add(Duration(minutes: durationMinutes));

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        barberId,
        barberName,
        serviceId,
        serviceName,
        date,
        durationMinutes,
        price,
        status,
      ];
}
