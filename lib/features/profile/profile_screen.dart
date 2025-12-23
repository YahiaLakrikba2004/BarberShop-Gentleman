import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../appointments/grouped_appointments_list.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    // If user is null (account deleted or error), show error and allow logout
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          title: Text('ERRORE PROFILO', style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF0A0A0A),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => ref.read(authServiceProvider).signOut(),
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Profilo non trovato.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                child: const Text('ESEGUI LOGOUT', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          title: Text(
            'IL MIO PROFILO',
            style: GoogleFonts.cinzel(
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              color: const Color(0xFFFFFFFF),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF0A0A0A),
          elevation: 0,
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.settings_outlined, color: Color(0xFFFFFFFF)),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
                      color: const Color(0xFFFFFFFF).withOpacity(0.1),
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
                              border: Border.all(
                                  color: const Color(0xFFFFFFFF), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFFFFFF).withOpacity(0.15),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                              image: _getUserImage(user.imageUrl),
                            ),
                            child:
                                user.imageUrl == null || user.imageUrl!.isEmpty
                                    ? Center(
                                        child: Text(
                                          user.name.isNotEmpty
                                              ? user.name[0].toUpperCase()
                                              : 'U',
                                          style: GoogleFonts.cinzel(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFFFFFF),
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
                                color: const Color(0xFFFFFFFF),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFF0A0A0A), width: 2),
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
                      user.name.toUpperCase(),
                      style: GoogleFonts.cinzel(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Minimalist Contact Info
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.email_outlined,
                                size: 14, color: const Color(0xFFFFFFFF)),
                            const SizedBox(width: 8),
                            Text(
                              user.email,
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        if (user.phoneNumber != null &&
                            user.phoneNumber!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone_outlined,
                                  size: 14, color: const Color(0xFFFFFFFF)),
                              const SizedBox(width: 8),
                              Text(
                                user.phoneNumber!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
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
                indicatorColor: Color(0xFFFFFFFF),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Color(0xFFFFFFFF),
                unselectedLabelColor: Colors.grey,
                labelStyle:
                    TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
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
                  _AppointmentsList(
                      userId: user.id, userRole: user.role, isHistory: false),
                  _AppointmentsList(
                      userId: user.id, userRole: user.role, isHistory: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(
      BuildContext context, WidgetRef ref, UserModel user) async {
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
        // Use XFile.readAsBytes() directly to handle all file sources safely
        final bytes = await pickedFile.readAsBytes();
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
      isScrollControlled: true, // Allow full height control
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glass effect
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E1E1E).withOpacity(0.95),
                const Color(0xFF0A0A0A).withOpacity(0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1), // Silver border
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    // Silver Drag Handle
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2), // Simple Silver
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      'IMPOSTAZIONI',
                      style: GoogleFonts.cinzel(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Pure White
                        letterSpacing: 4.0,
                        shadows: [
                          Shadow(color: Colors.white.withOpacity(0.1), blurRadius: 15),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Account Section
                    _buildSettingsSectionTitle('IL TUO ACCOUNT'),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildSettingsTile(
                              icon: Icons.edit_outlined,
                              title: 'Modifica Profilo',
                              onTap: () {
                                Navigator.pop(context);
                                _showEditProfileDialog(context, ref, user);
                              },
                            ),
                            // Removed Notifications Tile as requested
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // Legal Section
                      _buildSettingsSectionTitle('LEGAL & PRIVACY'),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(20),
                           border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildSettingsTile(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              onTap: () async {
                                final url = Uri.parse('https://barbershop-gentleman.web.app/privacy.html');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                             Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 60, endIndent: 20),
                             _buildSettingsTile(
                              icon: Icons.description_outlined,
                              title: 'Termini di Servizio',
                              onTap: () async {
                                final url = Uri.parse('https://barbershop-gentleman.web.app/terms.html');
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Info Section
                      _buildSettingsSectionTitle('INFORMAZIONI'),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: _buildSettingsTile(
                          icon: Icons.storefront_outlined,
                          title: 'Chi Siamo',
                          onTap: () {
                             Navigator.pop(context);
                             _showAboutUsDialog(context);
                          },
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Danger Zone
                    _buildSettingsSectionTitle('GESTIONE ACCOUNT'),
                     Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2A1010).withOpacity(0.4),
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          _buildSettingsTile(
                            icon: Icons.logout,
                            title: 'Esci',
                            color: const Color(0xFFE0E0E0),
                            onTap: () {
                              Navigator.pop(context);
                              ref.read(authServiceProvider).signOut();
                            },
                          ),
                           Divider(height: 1, color: const Color(0xFF8B0000).withOpacity(0.2), indent: 60, endIndent: 20),
                          _buildSettingsTile(
                            icon: Icons.delete_forever_outlined,
                            title: 'Elimina Account',
                            color: const Color(0xFFFF453A),
                            isDestructive: true,
                            onTap: () {
                              Navigator.pop(context);
                              _showDeleteAccountDialog(context, ref);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Version & Credits
                    Column(
                      children: [
                        Text(
                          'Version 1.0.3 (Build 240)',
                          style: GoogleFonts.sourceCodePro(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Developer Credits - Monochrome Badge
                         Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            border: Border.all(color: Colors.white.withOpacity(0.1)), // Silver border
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'CRAFTED BY ',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'YAHIA & OMAR',
                                style: GoogleFonts.cinzel(
                                  color: Colors.white.withOpacity(0.9), // Silver Names
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.cinzel(
            color: Colors.white.withOpacity(0.5), // Back to elegant Silver
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFFE0E0E0),
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: (isDestructive ? Colors.red : Colors.white).withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDestructive 
                    ? const Color(0xFF2A1010) 
                    : const Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDestructive 
                      ? const Color(0xFFFF453A).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1), // Silver border
                  ),
                ),
                child: Icon(
                  icon, 
                  color: isDestructive ? const Color(0xFFFF453A) : Colors.white.withOpacity(0.9), // White icon
                  size: 18
                ),
              ),
              const SizedBox(width: 20),
              // Text
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: isDestructive ? const Color(0xFFFF453A) : color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right,
                color: (isDestructive ? Colors.red : Colors.white).withOpacity(0.2), 
                size: 18
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, WidgetRef ref, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          title: Text(
            'MODIFICA PROFILO',
            style: GoogleFonts.cinzel(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              // Name Field
              TextField(
                controller: nameController,
                style: GoogleFonts.montserrat(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'NOME',
                  labelStyle: GoogleFonts.montserrat(
                      color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 1.0),
                  prefixIcon: Icon(Icons.person_outline, 
                      color: Colors.white.withOpacity(0.7), size: 20),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              // Phone Field
              TextField(
                controller: phoneController,
                style: GoogleFonts.montserrat(color: Colors.white),
                keyboardType: TextInputType.phone,
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'TELEFONO',
                  labelStyle: GoogleFonts.montserrat(
                      color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 1.0),
                  prefixIcon: Icon(Icons.phone_outlined, 
                      color: Colors.white.withOpacity(0.7), size: 20),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                  ),
                   contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
             const SizedBox(height: 20),
            // Email Field (Read Only)
            TextField(
              enabled: false,
              controller: TextEditingController(text: user.email),
              style: GoogleFonts.montserrat(color: Colors.white.withOpacity(0.5)),
              decoration: InputDecoration(
                labelText: 'EMAIL',
                labelStyle: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.3), fontSize: 12, letterSpacing: 1.0),
                prefixIcon: Icon(Icons.email_outlined, 
                    color: Colors.white.withOpacity(0.3), size: 20),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                 contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
             const SizedBox(height: 24),
            // Password Reset Action
            TextButton.icon(
              onPressed: () async {
                 try {
                   await ref.read(authServiceProvider).sendPasswordResetEmail(user.email);
                   if (context.mounted) {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text('Email di reset inviata a ${user.email}'),
                         backgroundColor: Colors.green,
                       ),
                     );
                   }
                 } catch (e) {
                    if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Errore durante l\'invio della mail')),
                     );
                   }
                 }
              },
              icon: Icon(Icons.lock_reset, color: Colors.white.withOpacity(0.6), size: 18),
              label: Text(
                'CAMBIA PASSWORD',
                style: GoogleFonts.montserrat(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  letterSpacing: 1.0,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.1))
                      ),
                    ),
                    child: Text('ANNULLA', 
                        style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.6), 
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0
                        )
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final newName = nameController.text.trim();
                      final newPhone = phoneController.text.trim();
                      if (newName.isNotEmpty) {
                        final updatedUser =
                            user.copyWith(name: newName, phoneNumber: newPhone);
                        await ref
                            .read(firestoreServiceProvider)
                            .updateUser(updatedUser);
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                     style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('SALVA', 
                        style: GoogleFonts.montserrat(
                            color: Colors.black, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0
                        )
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: const Color(0xFFFF453A).withOpacity(0.3), width: 1),
          ),
          title: Text(
            'ELIMINA ACCOUNT',
            style: GoogleFonts.cinzel(
              color: const Color(0xFFFF453A),
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 2.0,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Sei sicuro di voler eliminare il tuo account? Questa azione è irreversibile e perderai tutti i tuoi dati e appuntamenti.',
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withOpacity(0.1))
                      ),
                    ),
                    child: Text('ANNULLA', 
                        style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.6), 
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0
                        )
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
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
                     style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A1010), // Dark Red Background
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: const Color(0xFFFF453A).withOpacity(0.5)),
                      ),
                    ),
                    child: Text('ELIMINA', 
                        style: GoogleFonts.montserrat(
                            color: const Color(0xFFFF453A), 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0
                        )
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentsList extends ConsumerWidget {
  final String userId;
  final UserRole userRole;
  final bool isHistory;

  const _AppointmentsList({
    required this.userId,
    required this.userRole,
    required this.isHistory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = userRole == UserRole.barber
        ? ref.watch(allBarberAppointmentsProvider(userId))
        : ref.watch(userAppointmentsProvider(userId));

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

        return GroupedAppointmentsList(
          appointments: filteredAppointments,
          showBarber: userRole == UserRole.client,
          onAppointmentTap: (apt) {
            // Optional: Show details
          },
          onAppointmentCancel: isHistory
              ? null
              : (apt) => _showCancelAppointmentDialog(context, ref, apt),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFFFFF))),
      error: (e, _) => Center(child: Text('Errore: $e')),
    );
  }

  void _showCancelAppointmentDialog(
      BuildContext context, WidgetRef ref, AppointmentModel apt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: const Text('Annulla Appuntamento',
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          'Sei sicuro di voler annullare l\'appuntamento del ${DateFormat('dd/MM/yyyy HH:mm').format(apt.date)}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(firestoreServiceProvider)
                    .deleteAppointment(apt.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Appuntamento annullato con successo')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              }
            },
            child: const Text('Sì, Annulla',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

  void _showAboutUsDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.9), // Darker barrier
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1), // Subtle Silver Border
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05), // Cold Silver Glow
                      blurRadius: 30,
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Header with Silver Gradient ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(26),
                          topRight: Radius.circular(26),
                        ),
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Luxury Icon Container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                   Colors.white.withOpacity(0.05),
                                   Colors.transparent,
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.05),
                                  blurRadius: 20,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFE0E0E0), // Silver
                                  Color(0xFFFFFFFF), // White
                                  Color(0xFFBDBDBD), // Grey
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Icon(
                                FontAwesomeIcons.scissors,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'THE GENTLEMEN',
                            style: GoogleFonts.cinzel(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Pure White
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'BARBERSTYLE',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.4),
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Content Body ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                      child: Column(
                        children: [
                          Text(
                            '"L\'Eccellenza è uno stile di vita."',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Non offriamo solo tagli, ma un\'atmosfera dove la tradizione incontra il lusso moderno.\n\nOgni dettaglio è stato pensato per offrirti un momento di puro relax ed eleganza.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.6),
                              height: 1.6,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Instagram Button - Clean White
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white, // Solid White
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final uri = Uri.parse(
                                      'https://www.instagram.com/the_gentlemen_barberstyle/');
                                  try {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  } catch (e) {
                                    debugPrint(
                                        'Could not launch Instagram: \$e');
                                  }
                                },
                                borderRadius: BorderRadius.circular(30),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(FontAwesomeIcons.instagram,
                                          color: Colors.black, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        'SEGUICI SU INSTAGRAM',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontSize: 13,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Footer Action ---
                     Container(
                      decoration: BoxDecoration(
                         border: Border(
                          top: BorderSide(
                              color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      width: double.infinity,
                       child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                           shape: const RoundedRectangleBorder(
                             borderRadius: BorderRadius.only(
                               bottomLeft: Radius.circular(26),
                               bottomRight: Radius.circular(26)
                             )
                           )
                        ),
                        child: Text(
                          'CHIUDI',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


DecorationImage? _getUserImage(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return null;

  ImageProvider? imageProvider;
  if (imageUrl.startsWith('assets/')) {
    imageProvider = AssetImage(imageUrl);
  } else if (imageUrl.startsWith('http')) {
    imageProvider = NetworkImage(imageUrl);
  } else {
    try {
      imageProvider = MemoryImage(base64Decode(imageUrl));
    } catch (e) {
      return null;
    }
  }

  return DecorationImage(
    image: imageProvider,
    fit: BoxFit.cover,
  );
}
