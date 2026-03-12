import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Added Import
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import 'user_management_screen.dart';
import 'barber_management_screen.dart';
import 'service_management_screen.dart'; // Added Import
import '../calendar/calendar_screen.dart';
import '../../services/auth_service.dart';
import '../appointments/grouped_appointments_list.dart';
import 'shop_management_screen.dart';
import 'team_agenda_screen.dart';
import '../../services/notification_service.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    // Listen for new or cancelled appointments to show admin notifications
    ref.listen(allAppointmentsProvider, (previous, next) {
      if (previous?.hasValue == true && next.hasValue) {
        final prevAppointments = previous!.value!;
        final nextAppointments = next.value!;
        
        // 1. Check for new appointments
        if (nextAppointments.length > prevAppointments.length) {
          final newApts = nextAppointments.where((n) => !prevAppointments.any((p) => p.id == n.id)).toList();
          for (final apt in newApts) {
            ref.read(notificationServiceProvider).showImmediateNotification(
              title: 'Nuova Prenotazione',
              body: '${apt.customerName} ha prenotato ${apt.serviceName} per il ${DateFormat('dd/MM HH:mm').format(apt.date)}',
              payload: '/team-agenda',
            );
          }
        }
        
        // 2. Check for cancellations (status change to cancelled)
        for (final nextApt in nextAppointments) {
          final prevApt = prevAppointments.where((p) => p.id == nextApt.id).firstOrNull;
          if (prevApt != null && 
              prevApt.status != AppointmentStatus.cancelled && 
              nextApt.status == AppointmentStatus.cancelled) {
            
            ref.read(notificationServiceProvider).showImmediateNotification(
              title: 'Prenotazione Annullata',
              body: '${nextApt.customerName} ha annullato l\'appuntamento per ${nextApt.serviceName} del ${DateFormat('dd/MM HH:mm').format(nextApt.date)}',
              payload: '/team-agenda',
            );
          }
        }
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('ADMINISTRATION',
            style: GoogleFonts.cinzel(
                letterSpacing: 4,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          final stats = _calculateStats(appointments);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Benvenuto, ${user?.name ?? 'Admin'}'.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PANORAMICA',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Today's Summary
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: _TodayCard(stats: stats),
                ),

                const SizedBox(height: 40),

                // Quick Actions
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AZIONI RAPIDE',
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _QuickActionCard(
                              icon: Icons.view_column_outlined,
                              title: 'Agenda\nTeam',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const TeamAgendaScreen()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _QuickActionCard(
                              icon: Icons.people_outline,
                              title: 'Gestione\nUtenti',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const UserManagementScreen()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _QuickActionCard(
                              icon: Icons.content_cut,
                              title: 'Gestione\nBarbieri',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const BarberManagementScreen()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _QuickActionCard(
                              icon: Icons.spa_outlined,
                              title: 'Gestione\nServizi',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ServiceManagementScreen()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _QuickActionCard(
                              icon: Icons.settings_applications,
                              title: 'Gestione\nSalone',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ShopManagementScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Recent Appointments
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RECENTI',
                            style: GoogleFonts.cinzel(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CalendarScreen()),
                              );
                            },
                            child: Text('Vedi Tutti',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (appointments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161616) : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                              const SizedBox(height: 16),
                              Text(
                                'Nessun appuntamento trovato',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          height: 400, // Fixed height for the list
                          child: GroupedAppointmentsList(
                            appointments: appointments,
                            onAppointmentTap: (apt) {
                              // Show details or navigate
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Errore: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateStats(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    final todayApts = appointments.where((a) =>
        a.date.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
        a.date.isBefore(todayEnd)).toList();

    final weekApts = appointments.where((a) =>
        a.date.isAfter(weekStart.subtract(const Duration(seconds: 1)))).toList();

    int total = appointments.length;
    int confirmed = appointments
        .where((a) => a.status == AppointmentStatus.confirmed)
        .length;
    int pending =
        appointments.where((a) => a.status == AppointmentStatus.pending).length;
    int cancelled = appointments
        .where((a) => a.status == AppointmentStatus.cancelled)
        .length;
    double revenue = appointments
        .where((a) =>
            a.status == AppointmentStatus.confirmed ||
            a.status == AppointmentStatus.completed)
        .fold(0.0, (sum, a) => sum + a.price);

    final todayTotal = todayApts.length;
    final todayConfirmed = todayApts
        .where((a) => a.status == AppointmentStatus.confirmed).length;
    final todayRevenue = todayApts
        .where((a) => a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.completed)
        .fold(0.0, (sum, a) => sum + a.price);

    final weekRevenue = weekApts
        .where((a) => a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.completed)
        .fold(0.0, (sum, a) => sum + a.price);
    final weekTotal = weekApts.length;

    return {
      'total': total,
      'confirmed': confirmed,
      'pending': pending,
      'cancelled': cancelled,
      'revenue': revenue.toStringAsFixed(0),
      'todayTotal': todayTotal,
      'todayConfirmed': todayConfirmed,
      'todayRevenue': todayRevenue.toStringAsFixed(0),
      'weekRevenue': weekRevenue.toStringAsFixed(0),
      'weekTotal': weekTotal,
    };
  }
}


class _TodayCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _TodayCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final pending = stats['pending'] as int;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'OGGI',
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                    const Spacer(),
                    // Week revenue chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SETT. ',
                            style: GoogleFonts.montserrat(
                              color: Colors.white38,
                              fontSize: 9,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '€${stats['weekRevenue']}',
                            style: GoogleFonts.cinzel(
                              color: Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Big Revenue ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '€${stats['todayRevenue']}',
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'INCASSATI',
                        style: GoogleFonts.montserrat(
                          color: Colors.white24,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
              ),

              // ── 3 Stats Row ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
                child: Row(
                  children: [
                    _statChip(
                      context,
                      icon: Icons.calendar_today_rounded,
                      label: 'APPUNTAMENTI',
                      value: stats['todayTotal'].toString(),
                      accent: Colors.white,
                    ),
                    _dividerV(),
                    _statChip(
                      context,
                      icon: Icons.check_circle_outline_rounded,
                      label: 'CONFERMATI',
                      value: stats['todayConfirmed'].toString(),
                      accent: Colors.white,
                    ),
                    _dividerV(),
                    _statChip(
                      context,
                      icon: Icons.hourglass_top_rounded,
                      label: 'IN ATTESA',
                      value: stats['pending'].toString(),
                      accent: pending > 0 ? accent : Colors.white,
                      highlight: pending > 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent.withValues(alpha: highlight ? 0.9 : 0.35)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.cinzel(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: accent.withValues(alpha: highlight ? 0.6 : 0.3),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _dividerV() => Container(
    width: 1,
    height: 48,
    color: Colors.white.withValues(alpha: 0.07),
  );
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 120,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
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
