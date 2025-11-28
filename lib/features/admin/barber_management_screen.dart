import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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
        title: const Text('Gestione Barbieri', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFFFFF), width: 2), // White border
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFFFFF).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: _getBarberImage(barber.imageUrl),
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
                              const Icon(Icons.access_time, size: 14, color: Color(0xFFFFFFFF)),
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
                            color: Colors.purple.shade600,
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
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
                onPressed: () => _showEditBarberDialog(context, ref, barber),
              ),
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

Future<void> _showEditBarberDialog(BuildContext context, WidgetRef ref, BarberModel barber) async {
  final nameController = TextEditingController(text: barber.name);
  final startHourController = TextEditingController(text: barber.startHour.toString());
  final endHourController = TextEditingController(text: barber.endHour.toString());
  String? newImageBase64;
  final ImagePicker picker = ImagePicker();

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Modifica Barbiere', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 512,
                    maxHeight: 512,
                    imageQuality: 25,
                  );
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    setState(() {
                      newImageBase64 = base64Encode(bytes);
                    });
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    shape: BoxShape.circle,
                    image: newImageBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(newImageBase64!)),
                            fit: BoxFit.cover,
                          )
                        : (barber.imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: _getBarberImage(barber.imageUrl)!,
                                fit: BoxFit.cover,
                              )
                            : null),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: newImageBase64 == null && barber.imageUrl.isEmpty
                      ? const Icon(Icons.camera_alt, color: Colors.white, size: 40)
                      : (newImageBase64 != null ? null : const Icon(Icons.camera_alt, color: Colors.white54, size: 30)),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Tocca per cambiare foto', style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startHourController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Inizio Turno',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endHourController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Fine Turno',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (newImageBase64 != null) {
                  // Check size (approximate)
                  final sizeInBytes = (newImageBase64!.length * 3) / 4;
                  if (sizeInBytes > 1000000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('L\'immagine è ancora troppo grande. Riprova con un\'altra foto.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                final updatedBarber = barber.copyWith(
                  name: nameController.text,
                  imageUrl: newImageBase64 ?? barber.imageUrl,
                  startHour: int.tryParse(startHourController.text) ?? barber.startHour,
                  endHour: int.tryParse(endHourController.text) ?? barber.endHour,
                );
                
                await ref.read(firestoreServiceProvider).updateBarber(updatedBarber);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Barbiere aggiornato con successo!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Errore durante l\'aggiornamento: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Salva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

ImageProvider? _getBarberImage(String imageUrl) {
  if (imageUrl.isEmpty) return null;
  if (imageUrl.startsWith('assets/')) {
    return AssetImage(imageUrl);
  } else if (imageUrl.startsWith('http')) {
    return NetworkImage(imageUrl);
  } else {
    try {
      return MemoryImage(base64Decode(imageUrl));
    } catch (e) {
      return null;
    }
  }
}


