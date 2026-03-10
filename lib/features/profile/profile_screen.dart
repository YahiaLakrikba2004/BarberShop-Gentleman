import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../appointments/grouped_appointments_list.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    // If user is null, we can return a simple loading indicator or empty widget.
    // The redirect logic is handled by the AuthState listener in the app router.
    if (user == null) {
        return const Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
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
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF1A1A1A),
                      Color(0xFF0A0A0A),
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
                        if (user.email.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.email_outlined,
                                  size: 14, color: Color(0xFFFFFFFF)),
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
                          )
                        else
                          GestureDetector(
                            onTap: () => _showEditProfileDialog(context, ref, user),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline,
                                    size: 14, color: const Color(0xFFD4AF37).withOpacity(0.7)),
                                const SizedBox(width: 8),
                                Text(
                                  'Aggiungi email',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    color: const Color(0xFFD4AF37).withOpacity(0.7),
                                    letterSpacing: 0.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (user.phoneNumber != null &&
                            user.phoneNumber!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 14, color: Color(0xFFFFFFFF)),
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
    final outerCtx = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      isScrollControlled: true,
      builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 14),
                  // Drag Handle
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Titolo + pulsante chiudi
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text(
                            'IMPOSTAZIONI',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cinzel(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 3.0,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.45), size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- Sezione Account ---
                  _buildSettingsSectionHeader('IL TUO ACCOUNT'),
                  _buildSettingsCard([
                    _buildSettingsTileNew(
                      icon: Icons.edit_outlined,
                      title: 'Modifica Profilo',
                      subtitle: 'Nome, email e foto profilo',
                      onTap: () {
                        Navigator.pop(context);
                        _showEditProfileDialog(context, ref, user);
                      },
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // --- Sezione Legale ---
                  _buildSettingsSectionHeader('LEGALE & PRIVACY'),
                  _buildSettingsCard([
                    _buildSettingsTileNew(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Informativa sulla privacy',
                      onTap: () async {
                        final url = Uri.parse('https://barbershop-gentleman.web.app/privacy.html');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.06), indent: 60),
                    _buildSettingsTileNew(
                      icon: Icons.description_outlined,
                      title: 'Termini di Servizio',
                      subtitle: 'Condizioni d\'uso dell\'app',
                      onTap: () async {
                        final url = Uri.parse('https://barbershop-gentleman.web.app/terms.html');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    Divider(height: 1, color: Colors.white.withValues(alpha: 0.06), indent: 60),
                    _buildSettingsTileNew(
                      icon: Icons.storefront_outlined,
                      title: 'Chi Siamo',
                      subtitle: 'La storia di Gentleman',
                      onTap: () {
                        Navigator.pop(context);
                        _showAboutUsDialog(context);
                      },
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // --- Sezione Gestione Account ---
                  _buildSettingsSectionHeader('GESTIONE ACCOUNT'),
                  _buildSettingsCard([
                    _buildSettingsTileNew(
                      icon: Icons.logout,
                      title: 'Esci',
                      subtitle: 'Disconnettiti dall\'account',
                      onTap: () {
                        ref.read(authServiceProvider).signOut();
                        outerCtx.go('/auth');
                      },
                    ),
                    Divider(height: 1, color: const Color(0xFFDC143C).withValues(alpha: 0.15), indent: 60),
                    _buildSettingsTileNew(
                      icon: Icons.delete_outline,
                      title: 'Elimina Account',
                      subtitle: 'Rimozione permanente dell\'account',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showDeleteAccountDialog(outerCtx, ref);
                      },
                    ),
                  ], isDestructive: true),

                  const SizedBox(height: 36),

                  Text(
                    'Version 1.0.3',
                    style: GoogleFonts.montserrat(
                      color: Colors.white.withValues(alpha: 0.18),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildSettingsSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFDC143C).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSettingsTileNew({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? const Color(0xFFDC143C) : Colors.white.withValues(alpha: 0.75);
    final titleColor = isDestructive ? const Color(0xFFDC143C) : Colors.white;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: (isDestructive ? const Color(0xFFDC143C) : Colors.white).withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0xFFDC143C).withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        color: titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.2),
                size: 18,
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
    final emailController = TextEditingController(text: user.email);
    final isSaving = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: ValueListenableBuilder<bool>(
          valueListenable: isSaving,
          builder: (context, saving, child) => AlertDialog(
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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  // Name Field
                  TextField(
                    controller: nameController,
                    enabled: !saving,
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
                  // Phone Field (read-only — tied to Firebase Auth login)
                  TextField(
                    controller: phoneController,
                    enabled: false,
                    style: GoogleFonts.montserrat(color: Colors.white38),
                    keyboardType: TextInputType.phone,
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'TELEFONO',
                      labelStyle: GoogleFonts.montserrat(
                          color: Colors.white.withOpacity(0.3), fontSize: 12, letterSpacing: 1.0),
                      prefixIcon: Icon(Icons.phone_outlined,
                          color: Colors.white.withOpacity(0.3), size: 20),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.15),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                 const SizedBox(height: 20),
                // Email Field (Editable)
                TextField(
                  controller: emailController,
                  enabled: !saving,
                   style: GoogleFonts.montserrat(color: Colors.white),
                   cursorColor: Colors.white,
                   decoration: InputDecoration(
                    labelText: 'EMAIL',
                    labelStyle: GoogleFonts.montserrat(
                        color: Colors.white.withOpacity(0.5), fontSize: 12, letterSpacing: 1.0),
                    prefixIcon: Icon(Icons.email_outlined, 
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
  
                  // Show password reset only for real email accounts (not phone-auth fake emails)
                  if (user.email.isNotEmpty && !user.email.endsWith('@gentleman.app')) ...[
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: saving ? null : () async {
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
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: saving ? null : () => Navigator.pop(context),
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
                      onPressed: saving ? null : () async {
                        final newName = nameController.text.trim();
                        final newEmail = emailController.text.trim();

                        if (newName.isNotEmpty) {
                          isSaving.value = true;
                          try {
                            final authService = ref.read(authServiceProvider);

                            // 1. Update Display Name if changed
                            if (newName != user.name) {
                              await authService.updateDisplayName(newName);
                            }

                            // 2. Update Firestore (phone and Auth email are locked — deterministic login)
                            await ref.read(firestoreServiceProvider).updateUserFields(user.id, {
                              'name': newName,
                              'email': newEmail
                            });
  
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profilo aggiornato con successo!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                             if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text('Errore durante l\'aggiornamento: $e'),
                                   backgroundColor: Colors.redAccent,
                                 ),
                               );
                             }
                          } finally {
                            isSaving.value = false;
                          }
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
                      child: saving 
                        ? const SizedBox(
                            height: 20, 
                            width: 20, 
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                          )
                        : Text('SALVA', 
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
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final outerCtx = context;
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
                        if (outerCtx.mounted) outerCtx.go('/auth');
                      } catch (e) {
                        if (outerCtx.mounted) {
                          ScaffoldMessenger.of(outerCtx).showSnackBar(
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
        title: const Text('ELIMINA APPUNTAMENTO',
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(
          'Sei sicuro di voler eliminare l\'appuntamento del ${DateFormat('dd/MM/yyyy HH:mm').format(apt.date)}?\nL\'operazione non può essere annullata.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NO, MANTIENI', style: TextStyle(color: Colors.grey)),
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
                        content: Text('Appuntamento eliminato con successo')),
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
            child: const Text('SÌ, ELIMINA',
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
