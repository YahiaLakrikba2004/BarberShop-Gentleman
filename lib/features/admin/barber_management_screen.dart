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
      appBar: AppBar(
        title: const Text('Gestione Barbieri'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: barber.imageUrl.isNotEmpty
                      ? (barber.imageUrl.startsWith('assets/')
                          ? AssetImage(barber.imageUrl) as ImageProvider
                          : NetworkImage(barber.imageUrl))
                      : null,
                  child: barber.imageUrl.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Orario: ${barber.startHour}:00 - ${barber.endHour}:00',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('Stato Disponibilità:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: BarberAvailability.values.map((status) {
                final isSelected = barber.availabilityStatus == status;
                return ChoiceChip(
                  label: Text(_getStatusLabel(status)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _updateStatus(ref, barber, status);
                    }
                  },
                  selectedColor: _getStatusColor(status),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(BarberAvailability status) {
    switch (status) {
      case BarberAvailability.available: return 'Disponibile';
      case BarberAvailability.sick: return 'Malattia';
      case BarberAvailability.vacation: return 'Ferie';
      case BarberAvailability.dayOff: return 'Non Disponibile';
    }
  }

  Color _getStatusColor(BarberAvailability status) {
    switch (status) {
      case BarberAvailability.available: return Colors.green;
      case BarberAvailability.sick: return Colors.red;
      case BarberAvailability.vacation: return Colors.orange;
      case BarberAvailability.dayOff: return Colors.grey;
    }
  }

  Future<void> _updateStatus(WidgetRef ref, BarberModel barber, BarberAvailability status) async {
    final updatedBarber = barber.copyWith(availabilityStatus: status);
    await ref.read(firestoreServiceProvider).updateBarberAvailability(barber.id, updatedBarber.toMap());
  }
}
