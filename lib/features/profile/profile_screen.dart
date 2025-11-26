import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    if (user == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          title: Text(
            'IL MIO PROFILO',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: const Color(0xFFD4AF37),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0A0A0A),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFFD4AF37)),
              onPressed: () => _showSettingsModal(context, ref, user),
            ),
          ],
        ),
        body: Column(
          children: [
            // Premium Header
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A1A1A),
                      const Color(0xFF0A0A0A),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar with Glow and Edit Action
                    GestureDetector(
                      onTap: () => _pickAndUploadImage(context, ref, user),
                      child: Stack(
                        children: [
                          Container(
                            height: 100,
                            width: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A1A1A),
                              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                              image: user.imageUrl != null && user.imageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: user.imageUrl!.startsWith('http')
                                          ? NetworkImage(user.imageUrl!)
                                          : MemoryImage(base64Decode(user.imageUrl!)) as ImageProvider,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: user.imageUrl == null || user.imageUrl!.isEmpty
                                ? Center(
                                    child: Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFD4AF37),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Color(0xFF0A0A0A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Name
                    Text(
                      user.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 16),
                    // Minimalist Contact Info
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.email_outlined, size: 16, color: const Color(0xFFD4AF37)),
                            const SizedBox(width: 8),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_outlined, size: 16, color: const Color(0xFFD4AF37)),
                              const SizedBox(width: 8),
                              Text(
                                user.phoneNumber!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tab Bar
            Container(
              color: const Color(0xFF0A0A0A),
              child: const TabBar(
                indicatorColor: Color(0xFFD4AF37),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Color(0xFFD4AF37),
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                tabs: [
                  Tab(text: 'IN PROGRAMMA'),
                  Tab(text: 'STORICO'),
                ],
              ),
            ),

            // Appointments Lists
            Expanded(
              child: TabBarView(
                children: [
                  _AppointmentsList(userId: user.id, isHistory: false),
                  _AppointmentsList(userId: user.id, isHistory: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref, UserModel user) async {
    final picker = ImagePicker();
    // Pick and compress image to avoid Firestore 1MB limit
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Elaborazione immagine...')),
        );
      }

      try {
        final File imageFile = File(pickedFile.path);
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // Save Base64 string directly to Firestore
        final updatedUser = user.copyWith(imageUrl: base64Image);
        await ref.read(firestoreServiceProvider).updateUser(updatedUser);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profilo aggiornata!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore durante il salvataggio: $e')),
          );
        }
      }
    }
  }

  void _showSettingsModal(BuildContext context, WidgetRef ref, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'IMPOSTAZIONI',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Account Section
              _buildSettingsSectionTitle('ACCOUNT'),
              _buildSettingsTile(
                icon: Icons.edit_outlined,
                title: 'Modifica Profilo',
                onTap: () {
                  Navigator.pop(context);
                  _showEditProfileDialog(context, ref, user);
                },
              ),
              
              const SizedBox(height: 16),
              
              // Legal Section
              _buildSettingsSectionTitle('INFO LEGALI'),
              _buildSettingsTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Apertura Privacy Policy...')),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              Divider(color: Colors.white.withOpacity(0.1), height: 1),
              const SizedBox(height: 24),
              
              // Actions
              _buildSettingsTile(
                icon: Icons.logout,
                title: 'Esci',
                color: Colors.white,
                isDestructive: false,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authServiceProvider).signOut();
                },
              ),
              _buildSettingsTile(
                icon: Icons.delete_forever_outlined,
                title: 'Elimina Account',
                color: const Color(0xFFDC143C),
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteAccountDialog(context, ref);
                },
              ),
              
              const SizedBox(height: 16),
              Text(
                'Versione 1.0.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFFD4AF37),
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDestructive ? color.withOpacity(0.1) : const Color(0xFF2C2C2C),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDestructive ? Colors.transparent : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDestructive ? color : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        ),
        title: Text('Modifica Profilo', style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              cursorColor: const Color(0xFFD4AF37),
              decoration: InputDecoration(
                labelText: 'Nome',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              cursorColor: const Color(0xFFD4AF37),
              decoration: InputDecoration(
                labelText: 'Telefono',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();
              if (newName.isNotEmpty) {
                final updatedUser = user.copyWith(name: newName, phoneNumber: newPhone);
                await ref.read(firestoreServiceProvider).updateUser(updatedUser);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Salva', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: const Text('Elimina Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Sei sicuro di voler eliminare il tuo account? Questa azione è irreversibile e perderai tutti i tuoi dati e appuntamenti.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await ref.read(authServiceProvider).deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              }
            },
            child: const Text('Elimina Definitivamente', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsList extends ConsumerWidget {
  final String userId;
  final bool isHistory;

  const _AppointmentsList({
    required this.userId,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(userAppointmentsProvider(userId));

    return appointmentsAsync.when(
      data: (appointments) {
        final now = DateTime.now();
        final filteredAppointments = appointments.where((app) {
          final appDateTime = app.date;
          if (isHistory) {
            return appDateTime.isBefore(now);
          } else {
            return appDateTime.isAfter(now);
          }
        }).toList();

        filteredAppointments.sort((a, b) {
          if (isHistory) {
            return b.date.compareTo(a.date);
          } else {
            return a.date.compareTo(b.date);
          }
        });

        if (filteredAppointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isHistory ? Icons.history : Icons.calendar_today,
                  size: 64,
                  color: Colors.grey.withOpacity(0.1),
                ),
                const SizedBox(height: 16),
                Text(
                  isHistory
                      ? 'Nessun appuntamento passato'
                      : 'Nessun appuntamento in programma',
                  style: TextStyle(
                    color: Colors.grey.withOpacity(0.3),
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            final appointment = filteredAppointments[index];
            return _AppointmentTicket(appointment: appointment, isHistory: isHistory);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      error: (e, _) => Center(child: Text('Errore: $e')),
    );
  }
}

class _AppointmentTicket extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isHistory;

  const _AppointmentTicket({
    required this.appointment,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM y', 'it');
    final timeFormat = DateFormat('HH:mm');

    return FadeInUp(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Border Indicator
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: isHistory ? Colors.grey : const Color(0xFFD4AF37),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              appointment.serviceName.toUpperCase(),
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isHistory ? Colors.white70 : Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isHistory)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                              ),
                              child: const Text(
                                'CONFIRMED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD4AF37),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 8),
                          Text(
                            appointment.barberName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withOpacity(0.1), height: 1),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 16, color: const Color(0xFFD4AF37)),
                              const SizedBox(width: 8),
                              Text(
                                dateFormat.format(appointment.date).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: const Color(0xFFD4AF37)),
                              const SizedBox(width: 8),
                              Text(
                                timeFormat.format(appointment.date),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
