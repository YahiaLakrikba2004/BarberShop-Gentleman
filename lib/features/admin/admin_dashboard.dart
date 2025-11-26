import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/seed_service.dart';
import 'user_management_screen.dart';
import 'barber_management_screen.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(allAppointmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('ADMIN DASHBOARD'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Gestione Utenti',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserManagementScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Gestione Barbieri',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BarberManagementScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Carica Dati Demo',
            onPressed: () async {
              await ref.read(seedServiceProvider).seedData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Dati demo caricati!'),
                    backgroundColor: const Color(0xFFD4AF37),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          final stats = _calculateStats(appointments);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                FadeInDown(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Statistiche Generali',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: FadeInLeft(
                        delay: const Duration(milliseconds: 100),
                        child: _StatCard(
                          icon: Icons.event,
                          title: 'Totale',
                          value: stats['total'].toString(),
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: _StatCard(
                          icon: Icons.check_circle,
                          title: 'Confermati',
                          value: stats['confirmed'].toString(),
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: FadeInLeft(
                        delay: const Duration(milliseconds: 300),
                        child: _StatCard(
                          icon: Icons.pending,
                          title: 'In Attesa',
                          value: stats['pending'].toString(),
                          color: Color(0xFFFF9800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FadeInRight(
                        delay: const Duration(milliseconds: 400),
                        child: _StatCard(
                          icon: Icons.euro,
                          title: 'Ricavi',
                          value: '${stats['revenue']}€',
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Appointments List Header
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tutti gli Appuntamenti',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFD4AF37).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFD4AF37)),
                        ),
                        child: Text(
                          '${appointments.length}',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Appointments List
                if (appointments.isEmpty)
                  FadeIn(
                    delay: const Duration(milliseconds: 600),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 80,
                              color: Color(0xFFD4AF37).withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nessun appuntamento',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...appointments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final appointment = entry.value;
                    return FadeInUp(
                      delay: Duration(milliseconds: (600 + index * 50)),
                      child: _AppointmentCard(appointment: appointment),
                    );
                  }).toList(),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
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
    double revenue = appointments
        .where((a) => a.status == AppointmentStatus.confirmed || a.status == AppointmentStatus.completed)
        .fold(0.0, (sum, a) => sum + a.price);

    return {
      'total': total,
      'confirmed': confirmed,
      'pending': pending,
      'revenue': revenue.toStringAsFixed(0),
    };
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xFFD4AF37).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFD4AF37)),
            ),
            child: Icon(
              Icons.content_cut,
              color: Color(0xFFD4AF37),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.serviceName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${appointment.durationMinutes} min • ${appointment.price.toStringAsFixed(0)}€',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getStatusColor(appointment.status)),
            ),
            child: Text(
              _getStatusText(appointment.status),
              style: TextStyle(
                color: _getStatusColor(appointment.status),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Color(0xFF4CAF50);
      case AppointmentStatus.pending:
        return Color(0xFFFF9800);
      case AppointmentStatus.cancelled:
        return Color(0xFFF44336);
      case AppointmentStatus.completed:
        return Color(0xFF2196F3);
    }
  }

  String _getStatusText(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return 'CONFERMATO';
      case AppointmentStatus.pending:
        return 'ATTESA';
      case AppointmentStatus.cancelled:
        return 'ANNULLATO';
      case AppointmentStatus.completed:
        return 'COMPLETATO';
    }
  }
}
