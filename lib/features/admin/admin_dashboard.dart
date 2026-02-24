import 'package:flutter/material.dart';
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
        title: Text('DASHBOARD AMMINISTRATORE',
            style: GoogleFonts.cinzel(
                letterSpacing: 1.5,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Benvenuto, ${user?.name ?? 'Admin'}',
                        style: GoogleFonts.montserrat(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Panoramica',
                        style: GoogleFonts.cinzel(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Revenue Chart Section
                FadeInUp(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161616) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
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
                                  'Andamento Ricavi',
                                  style: GoogleFonts.montserrat(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '€${stats['revenue']}',
                                  style: GoogleFonts.cinzel(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.show_chart,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: _RevenueChart(appointments: appointments),
                        ),
                      ],
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
                            icon: Icons.calendar_today,
                            title: 'Totali',
                            value: stats['total'].toString(),
                            color: Colors.white, // Monochrome
                          ),
                          const SizedBox(height: 16),
                          _StatCard(
                            icon: Icons.check_circle_outline,
                            title: 'Confermati',
                            value: stats['confirmed'].toString(),
                            color: Colors.white, // Monochrome
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 220,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161616) : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border:
                              Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Stato Appuntamenti',
                              style: GoogleFonts.montserrat(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
                        'Azioni Rapide',
                        style: GoogleFonts.cinzel(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                            'Appuntamenti Recenti',
                            style: GoogleFonts.cinzel(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                      DateFormat('E', 'it').format(last7Days[index]),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10),
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
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.primary.withOpacity(0.0),
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
        sectionsSpace: 2, // Added space for definition
        centerSpaceRadius: 30,
        sections: [
          if (confirmed > 0)
            PieChartSectionData(
              color: Theme.of(context).colorScheme.primary,
              value: confirmed.toDouble(),
              title: '${(confirmed / total * 100).toStringAsFixed(0)}%',
              radius: 40,
              titleStyle: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary),
            ),
          if (pending > 0)
            PieChartSectionData(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              value: pending.toDouble(),
              title: '${(pending / total * 100).toStringAsFixed(0)}%',
              radius: 40,
              titleStyle: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface),
            ),
          if (cancelled > 0)
            PieChartSectionData(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              value: cancelled.toDouble(),
              title: '${(cancelled / total * 100).toStringAsFixed(0)}%',
              radius: 38,
              borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3), width: 1),
              titleStyle: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
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
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.cinzel(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
