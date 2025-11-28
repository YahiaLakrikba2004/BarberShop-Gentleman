import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/barber_model.dart';
import '../../services/firestore_service.dart';

class BarberManagementScreen extends ConsumerWidget {
  const BarberManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barbersAsync = ref.watch(barberListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Gestione Barbieri'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.grey[850]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4AF37), width: 2), // Gold border
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: barber.imageUrl.isNotEmpty
                        ? (barber.imageUrl.startsWith('assets/')
                            ? AssetImage(barber.imageUrl) as ImageProvider
                            : NetworkImage(barber.imageUrl))
                        : null,
                    backgroundColor: Colors.grey[800],
                    child: barber.imageUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.white70, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 4),
                          Text(
                            '${barber.startHour}:00 - ${barber.endHour}:00',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            const SizedBox(height: 16),
            const Text(
              'Stato Disponibilità',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatusButton(
                        label: 'Ferie',
                        isSelected: barber.availabilityStatus == BarberAvailability.vacation,
                        color: Colors.orange.shade600,
                        onTap: () => _updateStatus(ref, barber, BarberAvailability.vacation),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 160,
                  child: _StatusButton(
                    label: 'Non Disponibile',
                    isSelected: barber.availabilityStatus == BarberAvailability.dayOff,
                    color: Colors.grey.shade600,
                    onTap: () => _updateStatus(ref, barber, BarberAvailability.dayOff),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(WidgetRef ref, BarberModel barber, BarberAvailability status) async {
    final updatedBarber = barber.copyWith(availabilityStatus: status);
    await ref.read(firestoreServiceProvider).updateBarberAvailability(barber.id, updatedBarber.toMap());
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


