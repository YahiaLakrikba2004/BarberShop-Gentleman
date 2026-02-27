import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart'; // Added Import
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/seed_service.dart';
import 'user_management_screen.dart';
import 'barber_management_screen.dart';
import 'service_management_screen.dart'; // Added Import
import '../calendar/calendar_screen.dart';
import '../../services/auth_service.dart';
import '../appointments/grouped_appointments_list.dart';
import 'shop_management_screen.dart';
import 'team_agenda_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

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

                // Revenue Chart Section
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ANDAMENTO RICAVI',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '€${stats['revenue']}',
                                      style: GoogleFonts.cinzel(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: const Icon(Icons.auto_graph_rounded,
                                      color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 180,
                              child: _RevenueChart(appointments: appointments),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Stats Grid & Pie Chart
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _StatCard(
                            icon: Icons.calendar_today_rounded,
                            title: 'TOTALI',
                            value: stats['total'].toString(),
                          ),
                          const SizedBox(height: 16),
                          _StatCard(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'CONFERMATI',
                            value: stats['confirmed'].toString(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 220,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'STATO APPUNTAMENTI',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white.withOpacity(0.6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: _StatusPieChart(stats: stats),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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

    return {
      'total': total,
      'confirmed': confirmed,
      'pending': pending,
      'cancelled': cancelled,
      'revenue': revenue.toStringAsFixed(0),
    };
  }
}

class _RevenueChart extends StatelessWidget {
  final List<AppointmentModel> appointments;

  const _RevenueChart({required this.appointments});

  @override
  Widget build(BuildContext context) {
    // Calculate daily revenue for the last 7 days
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return DateTime(day.year, day.month, day.day);
    });

    final spots = last7Days.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;

      final dailyRevenue = appointments
          .where((a) =>
              (a.status == AppointmentStatus.confirmed ||
                  a.status == AppointmentStatus.completed) &&
              a.date.year == day.year &&
              a.date.month == day.month &&
              a.date.day == day.day)
          .fold(0.0, (sum, a) => sum + a.price);

      return FlSpot(index.toDouble(), dailyRevenue);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < last7Days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('E', 'it').format(last7Days[index]).toUpperCase(),
                      style:
                          GoogleFonts.montserrat(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const SizedBox();
              },
              interval: 1,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.white,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.white.withOpacity(0.05),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatusPieChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final confirmed = stats['confirmed'] as int;
    final pending = stats['pending'] as int;
    final cancelled = stats['cancelled'] as int;
    final total = confirmed + pending + cancelled;

    if (total == 0) {
      return Center(
          child: Text('Dati insufficienti',
              style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 12)));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 30,
        sections: [
          if (confirmed > 0)
            PieChartSectionData(
              color: Colors.white,
              value: confirmed.toDouble(),
              title: '${(confirmed / total * 100).toStringAsFixed(0)}%',
              radius: 40,
              titleStyle: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          if (pending > 0)
            PieChartSectionData(
              color: Colors.white.withOpacity(0.3),
              value: pending.toDouble(),
              title: '${(pending / total * 100).toStringAsFixed(0)}%',
              radius: 35,
              titleStyle: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          if (cancelled > 0)
            PieChartSectionData(
              color: Colors.white.withOpacity(0.1),
              value: cancelled.toDouble(),
              title: '${(cancelled / total * 100).toStringAsFixed(0)}%',
              radius: 30,
              titleStyle: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white24),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Text(
                    value,
                    style: GoogleFonts.cinzel(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
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
