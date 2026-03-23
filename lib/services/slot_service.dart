import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/barber_model.dart';
import '../models/appointment_model.dart';
import '../models/shop_settings_model.dart';

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
    required ShopSettingsModel shopSettings,
  }) {
    final List<DateTime> slots = [];

    // 0. Check Global Shop Status
    if (shopSettings.isShopClosedManually) {
      return [];
    }

    // 0.1 Check Global Holiday Closures
    final dateOnly = DateTime(date.year, date.month, date.day);
    for (var closureDate in shopSettings.closures) {
      final closureOnly = DateTime(closureDate.year, closureDate.month, closureDate.day);
      if (dateOnly.isAtSameMomentAs(closureOnly)) {
        return [];
      }
    }

    // 1. Check Availability Status
    if (barber.availabilityStatus != BarberAvailability.available) {
      return [];
    }

    // 2. Check Days Off
    if (barber.daysOff.contains(date.weekday)) {
      return [];
    }

    // 3. Check Unavailable Dates
    // Normalize date to remove time part for comparison
    // dateOnly is already declared above
    for (var unavailableDate in barber.unavailableDates) {
      final unavailableDateOnly = DateTime(unavailableDate.year, unavailableDate.month, unavailableDate.day);
      if (dateOnly.isAtSameMomentAs(unavailableDateOnly)) {
        return [];
      }
    }
    
    
    // 4. Check Shop Weekly Schedule for this weekday
    final shopDay = shopSettings.weeklySchedule[date.weekday];
    if (shopDay != null && shopDay.isClosed) {
      return [];
    }

    // Start and End times in total minutes from midnight
    final int barberStartMin = barber.startHourFor(date.weekday) * 60;
    final int barberEndMin   = barber.endHourFor(date.weekday) * 60;

    final int effectiveStartMin = (shopDay != null)
        ? barberStartMin.clamp(shopDay.openTotalMinutes, shopDay.closeTotalMinutes)
        : barberStartMin;
    final int effectiveEndMin = (shopDay != null)
        ? barberEndMin.clamp(shopDay.openTotalMinutes, shopDay.closeTotalMinutes)
        : barberEndMin;

    final DateTime startOfDay = DateTime(date.year, date.month, date.day, effectiveStartMin ~/ 60, effectiveStartMin % 60);
    final DateTime endOfDay   = DateTime(date.year, date.month, date.day, effectiveEndMin   ~/ 60, effectiveEndMin   % 60);

    // Pausa del doppio turno — priorità: barbiere > negozio
    DateTime? breakStart;
    DateTime? breakEnd;
    if (barber.hasBreakOn(date.weekday)) {
      final br = barber.breakForDay(date.weekday);
      breakStart = DateTime(date.year, date.month, date.day, br[0], br[1]);
      breakEnd   = DateTime(date.year, date.month, date.day, br[2], br[3]);
    } else {
      if (shopDay != null && shopDay.hasBreak) {
        breakStart = DateTime(date.year, date.month, date.day, shopDay.breakStartHour, shopDay.breakStartMinute);
        breakEnd   = DateTime(date.year, date.month, date.day, shopDay.breakEndHour,   shopDay.breakEndMinute);
      }
    }

    // Interval step (every 30 mins)
    const int intervalMinutes = 30;

    DateTime currentSlot = startOfDay;

    while (currentSlot.add(Duration(minutes: serviceDurationMinutes)).isBefore(endOfDay) ||
           currentSlot.add(Duration(minutes: serviceDurationMinutes)).isAtSameMomentAs(endOfDay)) {

      final DateTime slotEnd = currentSlot.add(Duration(minutes: serviceDurationMinutes));

      // Skip slot if it overlaps with the break period
      if (breakStart != null && breakEnd != null) {
        final overlapsBreak = currentSlot.isBefore(breakEnd) && slotEnd.isAfter(breakStart);
        if (overlapsBreak) {
          currentSlot = currentSlot.add(const Duration(minutes: intervalMinutes));
          continue;
        }
      }

      bool isOccupied = false;

      for (var appointment in existingAppointments) {
        // Ignore cancelled/no-show appointments
        if (appointment.status == AppointmentStatus.cancelled ||
            appointment.status == AppointmentStatus.noShow) {
          continue;
        }

        // Check overlap: appointment starts before slot ends AND ends after slot starts
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
