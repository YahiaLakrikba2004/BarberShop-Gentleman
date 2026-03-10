import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/appointment_model.dart';
import 'widgets/barber_daily_column.dart';

class TeamAgendaScreen extends ConsumerStatefulWidget {
  const TeamAgendaScreen({super.key});

  @override
  ConsumerState<TeamAgendaScreen> createState() => _TeamAgendaScreenState();
}

class _TeamAgendaScreenState extends ConsumerState<TeamAgendaScreen> {
  DateTime _selectedDate = DateTime.now();

  void _changeDate(int days) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final next = _selectedDate.add(Duration(days: days));
    if (next.isBefore(today)) return;
    setState(() {
      _selectedDate = next;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.white,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final barbersAsync = ref.watch(barberListProvider);
    final allAppointmentsAsync = ref.watch(allAppointmentsProvider);
    final isSunday = _selectedDate.weekday == DateTime.sunday;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'AGENDA TEAM',
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.calendar_today_rounded, 
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                });
              },
            ),
          ),
        ],
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Column(
        children: [
          // Date Select Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(Icons.chevron_left, color: Colors.white30),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_note_rounded, 
                            size: 18, 
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
                          ),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat('EEEE d MMMM', 'it').format(_selectedDate).toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              fontSize: 13,
                              color: isSunday ? Colors.white38 : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _changeDate(1),
                  icon: const Icon(Icons.chevron_right, color: Colors.white30),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Sunday message
          if (isSunday) ...[
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 56,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'DOMENICA',
                        style: GoogleFonts.cinzel(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Il negozio è aperto,\nma la domenica non si prenota online.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.35),
                          height: 1.6,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[

          // Main Agenda View
          Expanded(
            child: barbersAsync.when(
              data: (barbersList) {
                final barbers = barbersList.where((b) {
                  final isShopByName = b.name.toUpperCase() == 'NEGOZIO' ||
                      b.name.toUpperCase().contains('GENTLEMAN SHOP');
                  return b.isBookable && !isShopByName;
                }).toList();

                if (barbers.isEmpty) {
                  return Center(
                    child: Text(
                      'NESSUN BARBIERE DISPONIBILE',
                      style: GoogleFonts.cinzel(color: Colors.white54),
                    ),
                  );
                }

                return allAppointmentsAsync.when(
                  data: (appointments) {
                    final dayAppointments = appointments.where((apt) {
                      return apt.date.year == _selectedDate.year &&
                          apt.date.month == _selectedDate.month &&
                          apt.date.day == _selectedDate.day;
                    }).toList();

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Time Column
                                Container(
                                  width: 50,
                                  margin: const EdgeInsets.only(top: 155),
                                  child: Column(
                                    children: List.generate((11 + 1) * 2, (index) {
                                      final totalMinutes = 9 * 60 + index * 30;
                                      final hour = totalMinutes ~/ 60;
                                      final minute = totalMinutes % 60;
                                      final isHour = minute == 0;
                                      return Container(
                                        height: 30.0,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$hour:${minute.toString().padLeft(2, '0')}',
                                          style: GoogleFonts.montserrat(
                                            color: isHour ? Colors.white38 : Colors.white12,
                                            fontSize: isHour ? 10 : 8,
                                            fontWeight: isHour
                                                ? FontWeight.w500
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                                // Barber Columns
                                ...barbers.map((barber) {
                                  return Expanded(
                                    child: BarberDailyColumn(
                                      barber: barber,
                                      date: _selectedDate,
                                      appointments: dayAppointments,
                                      onAppointmentTap: (apt) =>
                                          _showAppointmentDetails(context, apt),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Errore agenda: $e')),
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Caricamento barbieri...', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Errore caricamento barbieri: $e',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

          ], // end else (not sunday)
        ],
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, AppointmentModel apt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DETTAGLI APPUNTAMENTO',
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.person, 'Cliente', apt.customerName),
              if (apt.customerPhoneNumber != null)
                _buildDetailRow(Icons.phone, 'Telefono', apt.customerPhoneNumber!),
              _buildDetailRow(Icons.content_cut, 'Servizio', apt.serviceName),
              _buildDetailRow(
                Icons.access_time,
                'Orario',
                '${DateFormat('HH:mm').format(apt.date)} - ${DateFormat('HH:mm').format(apt.endTime)}',
              ),
              _buildDetailRow(Icons.euro, 'Prezzo', '€${apt.price.toStringAsFixed(0)}'),
              const SizedBox(height: 24),

              // Cancel / No-show button
              if (apt.status != AppointmentStatus.cancelled)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(modalContext);
                      await ref
                          .read(firestoreServiceProvider)
                          .updateAppointmentStatus(apt.id, AppointmentStatus.cancelled);
                    },
                    icon: const Icon(Icons.person_off_outlined, size: 18),
                    label: const Text('CLIENTE NON PRESENTATO'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A0A0A),
                      foregroundColor: const Color(0xFFDC143C),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: const Color(0xFFDC143C).withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(modalContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: const Text('CHIUDI'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
