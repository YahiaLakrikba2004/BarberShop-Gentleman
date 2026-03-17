import 'dart:convert';
import 'dart:typed_data';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/barber_model.dart';
import '../../models/service_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/slot_service.dart';

// ─── TextField helper ─────────────────────────────────────────────────────────

class BookingTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final void Function(String) onChanged;
  final TextInputType inputType;
  final TextEditingController? controller;

  const BookingTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.onChanged,
    this.inputType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface),
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            size: 20),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF111111)
            : Colors.grey[100],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
      onChanged: onChanged,
    );
  }
}

// ─── UserAvatar ───────────────────────────────────────────────────────────────

class UserAvatar extends StatefulWidget {
  final UserModel user;
  final bool isSelected;

  const UserAvatar({super.key, required this.user, required this.isSelected});

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  Uint8List? _decodedBytes;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.imageUrl != widget.user.imageUrl) _decodeImage();
  }

  void _decodeImage() {
    final url = widget.user.imageUrl ?? '';
    if (url.length > 100 && !url.startsWith('http') && !url.startsWith('assets/')) {
      try {
        _decodedBytes = base64Decode(url);
      } catch (_) {
        _decodedBytes = null;
      }
    } else {
      _decodedBytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.user.imageUrl ?? '';
    if (url.isNotEmpty) {
      if (url.startsWith('assets/')) {
        return ClipOval(
            child: Image.asset(url,
                width: 50, height: 50, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitials()));
      } else if (_decodedBytes != null) {
        return ClipOval(
            child: Image.memory(_decodedBytes!,
                width: 50, height: 50, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitials()));
      } else if (url.startsWith('http')) {
        return ClipOval(
            child: Image.network(url,
                width: 50, height: 50, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildInitials()));
      }
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      width: 50, height: 50, alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
      child: Text(
        widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
        style: GoogleFonts.cinzel(
            color: widget.isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold, fontSize: 20),
      ),
    );
  }
}

// ─── PremiumServiceCard ───────────────────────────────────────────────────────

class PremiumServiceCard extends StatefulWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const PremiumServiceCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<PremiumServiceCard> createState() => _PremiumServiceCardState();
}

class _PremiumServiceCardState extends State<PremiumServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.98)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF111111) : Colors.white,
            border: Border.all(
              color: widget.isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).dividerColor.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                if (widget.isSelected)
                  Positioned.fill(
                    child: Container(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05))),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                        ),
                        child: Center(
                          child: Icon(Icons.content_cut,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                              size: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(widget.service.name.toUpperCase(),
                                style: GoogleFonts.cinzel(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${widget.service.durationMinutes} min',
                                style: GoogleFonts.montserrat(
                                    color: Theme.of(context)
                                        .colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('€${widget.service.price.toInt()}',
                          style: GoogleFonts.cinzel(
                              fontSize: 20, fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ),
                if (widget.isSelected)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle),
                      child: Icon(Icons.check, size: 12,
                          color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Barber status helpers ────────────────────────────────────────────────────

Color barberStatusColor(BarberAvailability status) {
  switch (status) {
    case BarberAvailability.sick: return const Color(0xFFDC143C);
    case BarberAvailability.vacation: return Colors.blue.shade600;
    case BarberAvailability.absence: return Colors.grey.shade700;
    default: return const Color(0xFFDC143C);
  }
}

String barberStatusLabel(BarberAvailability status) {
  switch (status) {
    case BarberAvailability.sick: return 'MALATTIA';
    case BarberAvailability.vacation: return 'IN FERIE';
    case BarberAvailability.absence: return 'ASSENTE';
    default: return 'NON DISPONIBILE';
  }
}

IconData barberStatusIcon(BarberAvailability status) {
  switch (status) {
    case BarberAvailability.sick: return Icons.local_hospital;
    case BarberAvailability.vacation: return Icons.beach_access;
    case BarberAvailability.absence: return Icons.person_off;
    default: return Icons.block;
  }
}

// ─── SlotsGrid ────────────────────────────────────────────────────────────────

class SlotsGrid extends ConsumerWidget {
  final BarberModel barber;
  final ServiceModel service;
  final DateTime date;
  final DateTime? selectedSlot;
  final void Function(DateTime) onSlotSelected;

  const SlotsGrid({
    super.key,
    required this.barber,
    required this.service,
    required this.date,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync =
        ref.watch(barberAppointmentsProvider((barberId: barber.id, date: date)));
    final settingsAsync = ref.watch(shopSettingsProvider);

    if (date.weekday == DateTime.sunday) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month, size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              const SizedBox(height: 16),
              Text('DOMENICA',
                  style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(
                'La domenica le prenotazioni online sono sospese.\nChiama o scrivi per fissare un appuntamento.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 13, height: 1.6,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
              ),
            ],
          ),
        ),
      );
    }

    return settingsAsync.when(
      data: (settings) => appointmentsAsync.when(
        data: (appointments) {
          final slots = ref.read(slotServiceProvider).getAvailableSlots(
            barber: barber,
            date: date,
            serviceDurationMinutes: service.durationMinutes,
            existingAppointments: appointments,
            shopSettings: settings,
          );

          if (slots.isEmpty) {
            return _buildEmptySlots(context, settings);
          }

          return Wrap(
            spacing: 12, runSpacing: 12,
            children: slots.map((slot) {
              final isSelected = selectedSlot == slot;
              return InkWell(
                onTap: () => onSlotSelected(slot),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF111111) : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).dividerColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(DateFormat('HH:mm').format(slot),
                      style: GoogleFonts.montserrat(
                          fontSize: 14, fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface)),
                ),
              );
            }).toList(),
          );
        },
        error: (e, _) =>
            Center(child: Text('Errore appuntamenti: $e', style: const TextStyle(color: Colors.red))),
        loading: () =>
            Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      ),
      loading: () =>
          Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      error: (e, _) =>
          Center(child: Text('Errore impostazioni: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildEmptySlots(BuildContext context, dynamic settings) {
    String title = 'NESSUNO SLOT';
    String message = "Prova a selezionare un'altra data";
    IconData icon = Icons.event_busy;

    if (settings.isShopClosedManually) {
      title = 'CHIUSO'; message = 'Il salone è temporaneamente chiuso.';
      icon = Icons.door_front_door_outlined;
    } else if (settings.closures.any(
        (c) => c.year == date.year && c.month == date.month && c.day == date.day)) {
      title = 'GIORNO FESTIVO'; message = 'Il salone è chiuso per festività in questa data.';
      icon = Icons.celebration;
    } else if (barber.availabilityStatus == BarberAvailability.sick) {
      title = 'MALATTIA'; message = '${barber.name} non è disponibile.';
      icon = Icons.local_hospital;
    } else if (barber.availabilityStatus == BarberAvailability.vacation ||
        barber.unavailableDates.any(
            (d) => d.year == date.year && d.month == date.month && d.day == date.day)) {
      title = 'IN FERIE'; message = '${barber.name} è in ferie in questa data.';
      icon = Icons.beach_access;
    } else if (barber.daysOff.contains(date.weekday)) {
      title = 'GIORNO DI RIPOSO';
      message = '${barber.name} non lavora di ${DateFormat('EEEE', 'it').format(date)}.';
      icon = Icons.weekend;
    } else if (barber.availabilityStatus == BarberAvailability.dayOff) {
      title = 'NON DISPONIBILE'; message = '${barber.name} non è disponibile in questa data.';
      icon = Icons.event_busy;
    }

    return Center(
      child: FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF111111) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(title,
                  style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message,
                  style: GoogleFonts.montserrat(fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
