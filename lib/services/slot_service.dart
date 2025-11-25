import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/barber_model.dart';
import '../models/appointment_model.dart';

final slotServiceProvider = Provider<SlotService>((ref) {
  return SlotService();
});

class SlotService {
  // Generate available slots for a barber on a specific date, given existing appointments and service duration
  List<DateTime> getAvailableSlots({
    required BarberModel barber,
    required DateTime date,
    required int serviceDurationMinutes,
    required List<AppointmentModel> existingAppointments,
  }) {
    final List<DateTime> slots = [];
    
    // Start and End times for the barber
    final DateTime startOfDay = DateTime(date.year, date.month, date.day, barber.startHour);
    final DateTime endOfDay = DateTime(date.year, date.month, date.day, barber.endHour);

    // Interval step (e.g., every 30 mins)
    // We can make this dynamic or fixed. Let's say 30 mins for now.
    const int intervalMinutes = 30;

    DateTime currentSlot = startOfDay;

    while (currentSlot.add(Duration(minutes: serviceDurationMinutes)).isBefore(endOfDay) || 
           currentSlot.add(Duration(minutes: serviceDurationMinutes)).isAtSameMomentAs(endOfDay)) {
      
      final DateTime slotEnd = currentSlot.add(Duration(minutes: serviceDurationMinutes));
      
      bool isOccupied = false;

      for (var appointment in existingAppointments) {
        // Check overlap
        // Appointment starts before slot ends AND Appointment ends after slot starts
        final appointmentEnd = appointment.date.add(Duration(minutes: appointment.durationMinutes));
        
        if (appointment.date.isBefore(slotEnd) && appointmentEnd.isAfter(currentSlot)) {
          isOccupied = true;
          break;
        }
      }

      if (!isOccupied) {
        // Also check if slot is in the past (if today)
        if (currentSlot.isAfter(DateTime.now())) {
           slots.add(currentSlot);
        }
      }

      currentSlot = currentSlot.add(const Duration(minutes: intervalMinutes));
    }

    return slots;
  }
}
