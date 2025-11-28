import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/seed_service.dart';
import 'user_management_screen.dart';
import 'barber_management_screen.dart';
import '../calendar/calendar_screen.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(allAppointmentsProvider);
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('DASHBOARD AMMINISTRATORE', style: TextStyle(letterSpacing: 1.5, fontSize: 16, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Panoramica',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PlayfairDisplay',
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
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                                const Text(
                                  'Andamento Ricavi',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '€${stats['revenue']}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.show_chart, color: Color(0xFFFFFFFF)),
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
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          _StatCard(
                            icon: Icons.check_circle_outline,
                            title: 'Confermati',
                            value: stats['confirmed'].toString(),
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 220, // Match height of 2 cards + spacing approx
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Stato Appuntamenti',
                              style: TextStyle(
                                color: Colors.white,
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
                      const Text(
                        'Azioni Rapide',
                        style: TextStyle(
                          color: Colors.white,
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
                              icon: Icons.people_outline,
                              title: 'Gestione\nUtenti',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _QuickActionCard(
                              icon: Icons.content_cut,
                              title: 'Gestione\nBarbieri',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BarberManagementScreen()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _QuickActionCard(
                              icon: Icons.calendar_month,
                              title: 'Calendario\nCompleto',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CalendarScreen()),
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
                          const Text(
                            'Appuntamenti Recenti',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                               Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CalendarScreen()),
                              );
                            },
                            child: const Text('Vedi Tutti', style: TextStyle(color: Color(0xFFFFFFFF))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (appointments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 48, color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 16),
                              Text(
                                'Nessun appuntamento trovato',
                                style: TextStyle(color: Colors.white.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        )
                      else
                        ...appointments.take(5).map((appointment) => _AppointmentCard(appointment: appointment)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
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
    int confirmed = appointments.where((a) => a.status == AppointmentStatus.confirmed).length;
    int pending = appointments.where((a) => a.status == AppointmentStatus.pending).length;
    int cancelled = appointments.where((a) => a.status == AppointmentStatus.cancelled).length;
    double revenue = appointments
        .where((a) => a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.completed)
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
              (a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.completed) &&
              a.date.year == day.year && 
              a.date.month == day.month && 
              a.date.day == day.day)
          .fold(0.0, (sum, a) => sum + a.price);

      return FlSpot(index.toDouble(), dailyRevenue);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
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
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFFFFFFF),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFFFFFF).withOpacity(0.1),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFFFFF).withOpacity(0.3),
                  const Color(0xFFFFFFFF).withOpacity(0.0),
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
      return const Center(child: Text('Dati insufficienti', style: TextStyle(color: Colors.white54, fontSize: 12)));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 30,
        sections: [
          if (confirmed > 0)
            PieChartSectionData(
              color: Colors.green,
              value: confirmed.toDouble(),
              title: '${(confirmed / total * 100).toStringAsFixed(0)}%',
              radius: 40,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          if (pending > 0)
            PieChartSectionData(
              color: Colors.blueGrey,
              value: pending.toDouble(),
              title: '${(pending / total * 100).toStringAsFixed(0)}%',
              radius: 40,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          if (cancelled > 0)
            PieChartSectionData(
              color: Colors.red,
              value: cancelled.toDouble(),
              title: '${(cancelled / total * 100).toStringAsFixed(0)}%',
              radius: 40,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C2C2C),
              const Color(0xFF1A1A1A),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFFFFFF), size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends ConsumerWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCancelled = appointment.status == AppointmentStatus.cancelled;
    final isCompleted = appointment.status == AppointmentStatus.completed;

    // Common card decoration
    final cardDecoration = BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );

    // Completed appointments cannot be swiped
    if (isCompleted) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: cardDecoration,
        child: _buildCardBody(context),
      );
    }

    // Dismissible for active/cancelled appointments
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: Key(appointment.id),
          direction: DismissDirection.endToStart, // Only allow swipe left
          background: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCancelled 
                    ? [const Color(0xFF8B0000), const Color(0xFFB71C1C)] // Darker Red Gradient
                    : [const Color(0xFF424242), const Color(0xFF616161)], // Grey Gradient
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  isCancelled ? 'ELIMINA' : 'ANNULLA',
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.5,
                    fontFamily: 'PlayfairDisplay',
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCancelled ? Icons.delete_forever_rounded : Icons.cancel_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (isCancelled) {
              // DELETE ACTION
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: const Text('Elimina Definitivamente', style: TextStyle(color: Colors.red)),
                  content: const Text(
                    'Sei sicuro di voler eliminare definitivamente questo appuntamento dallo storico? Questa azione è irreversibile.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Elimina', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(firestoreServiceProvider).deleteAppointment(appointment.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appuntamento eliminato definitivamente'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return true;
              }
            } else {
              // CANCEL ACTION
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: const Text('Annulla Appuntamento', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'Sei sicuro di voler annullare questo appuntamento? Il cliente verrà notificato.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('No, mantieni', style: TextStyle(color: Colors.white54)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sì, annulla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(firestoreServiceProvider).updateAppointmentStatus(
                  appointment.id, 
                  AppointmentStatus.cancelled
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Appuntamento annullato con successo'),
                      backgroundColor: Colors.grey[800],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return false;
              }
            }
            return false;
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A1A), // Solid background for the card content
            child: _buildCardBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildCardBody(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              DateFormat('d\nMMM', 'it').format(appointment.date),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                height: 1.1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.customerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${appointment.serviceName} con ${appointment.barberName}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _getStatusColor(appointment.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getStatusColor(appointment.status).withOpacity(0.5)),
          ),
          child: Text(
            DateFormat('HH:mm').format(appointment.date),
            style: TextStyle(
              color: _getStatusColor(appointment.status),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return const Color(0xFF4CAF50);
      case AppointmentStatus.pending:
        return Colors.blueGrey;
      case AppointmentStatus.cancelled:
        return const Color(0xFFF44336);
      case AppointmentStatus.completed:
        return const Color(0xFF2196F3);
    }
  }
}
