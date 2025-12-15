import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:uuid/uuid.dart';
import '../../models/service_model.dart';
import '../../services/firestore_service.dart';

class ServiceManagementScreen extends ConsumerWidget {
  const ServiceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GESTIONE SERVIZI',
          style: GoogleFonts.cinzel(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceDialog(context, ref),
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return Center(
              child: Text(
                'Nessun servizio disponibile',
                style: GoogleFonts.montserrat(color: Colors.white54),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: GoogleFonts.cinzel(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${service.durationMinutes} min • €${service.price.toStringAsFixed(0)}',
                              style: GoogleFonts.montserrat(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            if (service.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                service.description,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Colors.white),
                            onPressed: () => _showServiceDialog(context, ref,
                                service: service),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () =>
                                _showDeleteDialog(context, ref, service),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(
            child: Text('Errore: $err',
                style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  void _showServiceDialog(BuildContext context, WidgetRef ref,
      {ServiceModel? service}) {
    final nameController = TextEditingController(text: service?.name ?? '');
    final priceController =
        TextEditingController(text: service?.price.toString() ?? '');
    final durationController =
        TextEditingController(text: service?.durationMinutes.toString() ?? '30');
    final descriptionController =
        TextEditingController(text: service?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.white.withOpacity(0.1))),
        title: Text(
          service == null ? 'Nuovo Servizio' : 'Modifica Servizio',
          style: GoogleFonts.cinzel(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Nome Servizio', Icons.content_cut),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                        priceController, 'Prezzo (€)', Icons.euro,
                        isNumber: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                        durationController, 'Durata (min)', Icons.timer,
                        isNumber: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                  descriptionController, 'Descrizione', Icons.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla',
                style: GoogleFonts.montserrat(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                return;
              }

              final newService = ServiceModel(
                id: service?.id ?? const Uuid().v4(),
                name: nameController.text.trim(),
                price: double.tryParse(priceController.text) ?? 0.0,
                durationMinutes: int.tryParse(durationController.text) ?? 30,
                description: descriptionController.text.trim(),
              );

              try {
                if (service == null) {
                  await ref
                      .read(firestoreServiceProvider)
                      .createService(newService);
                } else {
                  await ref
                      .read(firestoreServiceProvider)
                      .updateService(newService);
                }
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')));
              }
            },
            child: Text('Salva',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, ServiceModel service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.redAccent.withOpacity(0.3))),
        title: Text('Elimina Servizio',
            style: GoogleFonts.cinzel(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
            'Sei sicuro di voler eliminare "${service.name}"? Questa azione è irreversibile.',
            style: GoogleFonts.montserrat(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla',
                style: GoogleFonts.montserrat(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(firestoreServiceProvider).deleteService(service.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Elimina',
                style: GoogleFonts.montserrat(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      style: GoogleFonts.montserrat(color: Colors.white),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
