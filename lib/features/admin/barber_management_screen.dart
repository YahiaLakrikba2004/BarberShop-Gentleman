import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/barber_model.dart';
import '../../services/firestore_service.dart';

class BarberManagementScreen extends ConsumerWidget {
  const BarberManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barbersAsync = ref.watch(barberListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GESTIONE BARBIERI',
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: barbersAsync.when(
        data: (barbers) {
          if (barbers.isEmpty) {
            return const Center(child: Text('Nessun barbiere trovato.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: barbers.length,
            itemBuilder: (context, index) {
              final barber = barbers[index];
              return _BarberManagementCard(barber: barber);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
      ),
    );
  }
}

class _BarberManagementCard extends ConsumerWidget {
  final BarberModel barber;

  const _BarberManagementCard({required this.barber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5), 
                          width: 2
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.05),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: _getBarberImage(barber.imageUrl),
                        backgroundColor: const Color(0xFF1A1A1A),
                        child: barber.imageUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white24, size: 36)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            barber.name.toUpperCase(),
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                              const SizedBox(width: 6),
                              Text(
                                '${barber.startHour}:00 — ${barber.endHour}:00',
                                style: GoogleFonts.montserrat(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), 
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STATO E PIANIFICAZIONE',
                        style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                    Column(
                      children: [
                        // Row 1: Available & Sick
                        Row(
                          children: [
                            Expanded(
                              child: _StatusButton(
                                label: 'Disponibile',
                                isSelected: barber.availabilityStatus == BarberAvailability.available,
                                color: Colors.green.shade600,
                                onTap: () => _updateStatus(ref, barber, BarberAvailability.available),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatusButton(
                                label: 'Malattia',
                                isSelected: barber.availabilityStatus == BarberAvailability.sick,
                                color: Colors.red.shade600,
                                onTap: () => _updateStatus(ref, barber, BarberAvailability.sick),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 2: Vacation & Absence
                        Row(
                          children: [
                            Expanded(
                              child: _StatusButton(
                                label: 'In Ferie',
                                isSelected: barber.availabilityStatus == BarberAvailability.vacation,
                                color: Colors.blue.shade600,
                                onTap: () => _updateStatus(ref, barber, BarberAvailability.vacation),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatusButton(
                                label: 'Assenza',
                                isSelected: barber.availabilityStatus == BarberAvailability.absence,
                                color: Colors.grey.shade600,
                                onTap: () => _updateStatus(ref, barber, BarberAvailability.absence),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Row 3: Future Planning
                        Row(
                          children: [
                            Expanded(
                              child: _StatusButton(
                                label: 'Pianifica Ferie Future',
                                isSelected: false,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                icon: Icons.calendar_month,
                                onTap: () => _showBarberVacationDialog(context, ref, barber),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ), // Close Container at 139
            ],
          ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white.withOpacity(0.05) 
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                      ),
                      child: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onSurface, size: 20),
                    ),
                    onPressed: () => _showEditBarberDialog(context, ref, barber),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, BarberModel barber, BarberAvailability status) async {
    final updatedBarber = barber.copyWith(availabilityStatus: status);
    await ref.read(firestoreServiceProvider).updateBarber(updatedBarber);
  }

  void _showBarberVacationDialog(BuildContext context, WidgetRef ref, BarberModel barber) {
    showDialog(
      context: context,
      builder: (context) => _BarberVacationDialog(barber: barber),
    );
  }
}

class _BarberVacationDialog extends StatefulWidget {
  final BarberModel barber;
  const _BarberVacationDialog({required this.barber});

  @override
  State<_BarberVacationDialog> createState() => _BarberVacationDialogState();
}

class _BarberVacationDialogState extends State<_BarberVacationDialog> {
  late List<DateTime> _unavailableDates;

  @override
  void initState() {
    super.initState();
    _unavailableDates = List.from(widget.barber.unavailableDates);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        title: Column(
          children: [
            Text(
              'FERIE & ASSENZE',
              style: GoogleFonts.cinzel(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
            Text(
              widget.barber.name.toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.black.withOpacity(0.3) 
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.now().subtract(const Duration(days: 30)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: DateTime.now(),
                    calendarFormat: CalendarFormat.month,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: GoogleFonts.cinzel(
                        color: Theme.of(context).colorScheme.onSurface, 
                        fontWeight: FontWeight.bold
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary),
                      rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface),
                      weekendTextStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary, 
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    selectedDayPredicate: (day) => _unavailableDates.any((d) => isSameDay(d, day)),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        if (_unavailableDates.any((d) => isSameDay(d, selectedDay))) {
                          _unavailableDates.removeWhere((d) => isSameDay(d, selectedDay));
                        } else {
                          _unavailableDates.add(selectedDay);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_unavailableDates.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ASSENZE PIANIFICATE',
                      style: GoogleFonts.montserrat(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _unavailableDates.map((date) => Chip(
                      label: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10)),
                      onDeleted: () => setState(() => _unavailableDates.removeWhere((d) => isSameDay(d, date))),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      deleteIconColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ANNULLA', style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), 
              fontWeight: FontWeight.bold
            )),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final updatedBarber = widget.barber.copyWith(unavailableDates: _unavailableDates);
              await ref.read(firestoreServiceProvider).updateBarber(updatedBarber);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('SALVA', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;

  const _StatusButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: isSelected ? Colors.white : color, size: 18),
              const SizedBox(height: 4),
            ] else if (isSelected) ...[
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(height: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showEditBarberDialog(BuildContext context, WidgetRef ref, BarberModel barber) async {
  final nameController = TextEditingController(text: barber.name);
  final startHourController = TextEditingController(text: barber.startHour.toString());
  final endHourController = TextEditingController(text: barber.endHour.toString());
  String? newImageBase64;
  final ImagePicker picker = ImagePicker();

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('Modifica Barbiere', style: GoogleFonts.cinzel(
          color: Theme.of(context).colorScheme.onSurface, 
          fontWeight: FontWeight.bold
        )),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 25,
                  );
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setState(() {
                      newImageBase64 = base64Encode(bytes);
                    });
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                    image: newImageBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(newImageBase64!)),
                            fit: BoxFit.cover,
                          )
                        : (barber.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: _getBarberImage(barber.imageUrl)!,
                                fit: BoxFit.cover,
                              )
                            : null),
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  child: newImageBase64 == null && barber.imageUrl.isEmpty
                      ? const Icon(Icons.camera_alt, color: Colors.white, size: 40)
                      : (newImageBase64 != null ? null : const Icon(Icons.camera_alt, color: Colors.white54, size: 30)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Tocca per cambiare foto', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Nome',
                  labelStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startHourController,
                      style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Inizio Turno',
                        labelStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endHourController,
                      style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Fine Turno',
                        labelStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2))),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla', style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (newImageBase64 != null) {
                  // Check size (approximate)
                  final sizeInBytes = (newImageBase64!.length * 3) / 4;
                  if (sizeInBytes > 1000000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('L\'immagine è ancora troppo grande. Riprova con un\'altra foto.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                final updatedBarber = barber.copyWith(
                  name: nameController.text,
                  imageUrl: newImageBase64 ?? barber.imageUrl,
                  startHour: int.tryParse(startHourController.text) ?? barber.startHour,
                  endHour: int.tryParse(endHourController.text) ?? barber.endHour,
                );
                
                await ref.read(firestoreServiceProvider).updateBarber(updatedBarber);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Barbiere aggiornato con successo!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante l\'aggiornamento: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('SALVA', style: GoogleFonts.cinzel(
              color: Theme.of(context).colorScheme.primary, 
              fontWeight: FontWeight.bold
            )),
          ),
        ],
      ),
    ),
  );
}

ImageProvider? _getBarberImage(String imageUrl) {
  if (imageUrl.isEmpty) return null;
  if (imageUrl.startsWith('assets/')) {
    return AssetImage(imageUrl);
  } else if (imageUrl.startsWith('http')) {
    return NetworkImage(imageUrl);
  } else {
    try {
      return MemoryImage(base64Decode(imageUrl));
    } catch (e) {
      return null;
    }
  }
}


