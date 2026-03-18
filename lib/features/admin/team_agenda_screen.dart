import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
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
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;
    final barbersAsync = ref.watch(barberListProvider);
    final allAppointmentsAsync = ref.watch(allAppointmentsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // Route guard: only barbers and admins can access this screen
    if (userAsync.hasValue && (user == null || user.role == UserRole.client)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

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
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16, vertical: 8),
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
                              color: Colors.white,
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

          // Main Agenda View
          Expanded(
            child: barbersAsync.when(
              data: (barbersList) {
                final barbers = barbersList.where((b) => b.isBookable).toList();

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

                    const startHour = 9;
                    const endHour = 20;
                    const totalHours = endHour - startHour;

                    return LayoutBuilder(builder: (context, constraints) {
                      // On desktop: fill available height; on mobile: keep 60px min
                      final availH = constraints.maxHeight;
                      final rawHourHeight = (availH - BarberDailyColumn.headerHeight - 16) / totalHours;
                      final hourHeight = rawHourHeight.clamp(55.0, 120.0);
                      final slotHeight = hourHeight / 2;
                      final timeColWidth = isDesktop ? 60.0 : 50.0;

                      Widget agendaContent = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time Column
                          SizedBox(
                            width: timeColWidth,
                            child: Column(
                              children: [
                                const SizedBox(height: BarberDailyColumn.headerHeight),
                                ...List.generate(totalHours * 2, (index) {
                                  final totalMinutes = startHour * 60 + index * 30;
                                  final hour = totalMinutes ~/ 60;
                                  final minute = totalMinutes % 60;
                                  final isHour = minute == 0;
                                  return SizedBox(
                                    height: slotHeight,
                                    child: Align(
                                      alignment: Alignment.topCenter,
                                      child: Text(
                                        isHour ? '$hour:00' : '',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white38,
                                          fontSize: isDesktop ? 11 : 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
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
                                hourHeight: hourHeight,
                                startHour: startHour,
                                endHour: endHour,
                              ),
                            );
                          }),
                        ],
                      );

                      // On desktop: no scroll if fits; on mobile: always scrollable
                      final totalTimelineH = BarberDailyColumn.headerHeight + totalHours * hourHeight;
                      if (!isDesktop || totalTimelineH > availH) {
                        agendaContent = SingleChildScrollView(child: agendaContent);
                      }

                      return agendaContent;
                    });
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

        ],
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, AppointmentModel apt) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget content(BuildContext modalContext) => Container(
      padding: const EdgeInsets.all(28),
      decoration: isDesktop
          ? BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            )
          : BoxDecoration(
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
              style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold),
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

            if (apt.status == AppointmentStatus.pending || apt.status == AppointmentStatus.confirmed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(modalContext);
                    await ref
                        .read(firestoreServiceProvider)
                        .updateAppointmentStatus(apt.id, AppointmentStatus.completed);
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('SERVIZIO COMPLETATO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2A1A),
                    foregroundColor: const Color(0xFF4CAF50),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            if (apt.status != AppointmentStatus.cancelled && apt.status != AppointmentStatus.completed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(modalContext);
                    await ref
                        .read(firestoreServiceProvider)
                        .updateAppointmentStatus(apt.id, AppointmentStatus.noShow);
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
                      side: BorderSide(color: const Color(0xFFDC143C).withValues(alpha: 0.4)),
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
    );

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (modalContext) => Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(width: 420, child: content(modalContext)),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: content,
      );
    }
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
