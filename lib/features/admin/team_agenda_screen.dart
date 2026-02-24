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
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFD4AF37), // Gold
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'AGENDA TEAM',
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            fontSize: 18,
            color: Theme.of(context).colorScheme.primary, // Gold title
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.today, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
               setState(() {
                 _selectedDate = DateTime.now();
               });
            },
          ),
        ],
        leading: Navigator.canPop(context) ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ) : null,
      ),
      body: Column(
        children: [
          // Date Select Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _changeDate(-1),
                  icon: const Icon(Icons.chevron_left, color: Colors.white54),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(30),
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month, size: 18, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE d MMMM', 'it').format(_selectedDate).toUpperCase(),
                           style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: Theme.of(context).colorScheme.primary, // Gold date
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _changeDate(1),
                  icon: const Icon(Icons.chevron_right, color: Colors.white54),
                ),
              ],
            ),
          ),

          // Main Agenda View
          Expanded(
            child: barbersAsync.when(
              data: (barbersList) {
                // Filter out the Shop Account (Ghost Barber) from the visual agenda
                final barbers = barbersList.where((b) {
                   // Filter strictly by bookability first
                   // Failsafe: Also hide if name matches Shop explicit names (in case DB flag is wrong)
                   final isShopByName = b.name.toUpperCase() == 'NEGOZIO' || b.name.toUpperCase().contains('GENTLEMAN SHOP');
                   return b.isBookable && !isShopByName;
                }).toList();

                if (barbers.isEmpty) {
                  return Center(
                    child: Text(
                      "NESSUN BARBIERE DISPONIBILE",
                      style: GoogleFonts.cinzel(color: Colors.white54),
                    ),
                  );
                }
                
                return allAppointmentsAsync.when(
                  data: (appointments) {
                    // Filter appointments for the selected date
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
                                  // This margin MUST match the height of the BarberDailyColumn Header
                                  // Header has padding 16 (x2 vertical) + CircleAvatar radius 30 (x2 size) + text + styling
                                  // Approx: 32 + 60 + 12 + 14 + 14 ~ 130-140. 
                                  // Let's refine this alignment.
                                  margin: const EdgeInsets.only(top: 155), 
                                  child: Column(
                                    children: List.generate(11 + 1, (index) { // 9 to 20 is 11 hours
                                      final hour = 9 + index;
                                      return Container(
                                        height: 60.0, // Match hourHeight in BarberDailyColumn
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$hour:00',
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white38,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
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
                                      onAppointmentTap: (apt) => _showAppointmentDetails(context, apt),
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
                  error: (e, s) => Center(child: Text("Errore agenda: $e")),
                );
              },

              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("Caricamento barbieri...", style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              error: (e, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Errore caricamento barbieri: $e",
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
               _buildDetailRow(Icons.access_time, 'Orario', '${DateFormat('HH:mm').format(apt.date)} - ${DateFormat('HH:mm').format(apt.endTime)}'),
               _buildDetailRow(Icons.euro, 'Prezzo', '€${apt.price.toStringAsFixed(0)}'),
               const SizedBox(height: 24),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: () => Navigator.pop(context),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).colorScheme.primary,
                     foregroundColor: Colors.black,
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
