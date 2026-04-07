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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    // Still determining auth state
    if (authState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    // Not logged in: show guest screen with login CTA
    if (authState.value == null) {
      return _GuestProfileScreen();
    }

    // Logged in but profile still loading
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isAdmin = user.role == UserRole.admin;
    final showHistory = isAdmin || user.role == UserRole.client;

    return DefaultTabController(
      length: showHistory ? 2 : 1,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 900 : double.infinity),
            child: Column(
          children: [
            // Premium Header
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: double.infinity,
                padding:
                    EdgeInsets.symmetric(vertical: 32, horizontal: isDesktop ? 48 : 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
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
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A1A1A),
                              border: Border.all(
                                  color: const Color(0xFFFFFFFF), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFFFFFF).withValues(alpha: 0.15),
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
                                            fontSize: 48,
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
                                  color: Colors.white.withValues(alpha: 0.7),
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
                                    size: 14, color: const Color(0xFFD4AF37).withValues(alpha: 0.7)),
                                const SizedBox(width: 8),
                                Text(
                                  'Aggiungi email',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 13,
                                    color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
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
                                  color: Colors.white.withValues(alpha: 0.7),
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
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                indicatorColor: const Color(0xFFFFFFFF),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: const Color(0xFFFFFFFF),
                unselectedLabelColor: Colors.grey,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                tabs: [
                  const Tab(text: 'IN PROGRAMMA'),
                  if (showHistory) const Tab(text: 'STORICO'),
                ],
              ),
            ),

            // Appointments Lists
            Expanded(
              child: TabBarView(
                children: [
                  _AppointmentsList(
                      userId: user.id, userRole: user.role, isHistory: false),
                  if (showHistory)
                    _AppointmentsList(
                        userId: user.id, userRole: user.role, isHistory: true),
                ],
              ),
            ),
          ],
            ),
          ),
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
                    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
                      Divider(height: 1, color: Colors.white.withValues(alpha: 0.06), indent: 60),
                      _buildSettingsTileNew(
                        icon: Icons.pin_outlined,
                        title: 'Cambia PIN',
                        subtitle: 'Modifica il PIN di accesso',
                        onTap: () {
                          Navigator.pop(context);
                          _showChangePinModal(outerCtx, ref);
                        },
                      ),
                    ],
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
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 0.5,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildMonogram('Y'),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          _buildMonogram('O'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Yahia & Omar',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white.withValues(alpha: 0.22),
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: 32,
                        height: 0.5,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildMonogram(String initial) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.cinzel(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.28),
            letterSpacing: 0.5,
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
            backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
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
                          color: Colors.white.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 1.0),
                      prefixIcon: Icon(Icons.person_outline, 
                          color: Colors.white.withValues(alpha: 0.7), size: 20),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
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
                          color: Colors.white.withValues(alpha: 0.3), fontSize: 12, letterSpacing: 1.0),
                      prefixIcon: Icon(Icons.phone_outlined,
                          color: Colors.white.withValues(alpha: 0.3), size: 20),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.15),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
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
                        color: Colors.white.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 1.0),
                    prefixIcon: Icon(Icons.email_outlined, 
                        color: Colors.white.withValues(alpha: 0.7), size: 20),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                       borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
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
                      icon: Icon(Icons.lock_reset, color: Colors.white.withValues(alpha: 0.6), size: 18),
                      label: Text(
                        'CAMBIA PASSWORD',
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withValues(alpha: 0.6),
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
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.1))
                        ),
                      ),
                      child: Text('ANNULLA', 
                          style: GoogleFonts.montserrat(
                              color: Colors.white.withValues(alpha: 0.6), 
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

  void _showChangePinModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _ChangePinSheet(outerContext: context),
    );
  }
}

class _ChangePinSheet extends StatefulWidget {
  final BuildContext outerContext;
  const _ChangePinSheet({required this.outerContext});

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  int _step = 0;
  bool _isLoading = false;
  // ValueNotifier so error text updates without rebuilding the TextFields
  final _errorNotifier = ValueNotifier<String?>(null);

  final _currentControllers = List.generate(6, (_) => TextEditingController());
  final _currentFocus = List.generate(6, (_) => FocusNode());
  final _newControllers = List.generate(6, (_) => TextEditingController());
  final _newFocus = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _errorNotifier.dispose();
    for (final c in [..._currentControllers, ..._newControllers]) { c.dispose(); }
    for (final f in [..._currentFocus, ..._newFocus]) { f.dispose(); }
    super.dispose();
  }

  Future<void> _submitCurrentPin() async {
    final currentPin = _currentControllers.map((c) => c.text).join();
    if (currentPin.length < 6) return;
    setState(() => _isLoading = true);
    _errorNotifier.value = null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => _isLoading = false);
      _errorNotifier.value = 'Utente non trovato';
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(email: user.email!, password: currentPin);
      await user.reauthenticateWithCredential(credential);
      setState(() { _step = 1; _isLoading = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _newFocus[0].requestFocus();
      });
    } on FirebaseAuthException catch (e) {
      for (final c in _currentControllers) { c.clear(); }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _currentFocus[0].requestFocus();
      });
      setState(() => _isLoading = false);
      _errorNotifier.value = e.code == 'wrong-password' || e.code == 'invalid-credential'
          ? 'PIN attuale non corretto'
          : 'Errore: ${e.message}';
    }
  }

  Future<void> _submitNewPin() async {
    final newPin = _newControllers.map((c) => c.text).join();
    if (newPin.length < 6) return;
    setState(() => _isLoading = true);
    _errorNotifier.value = null;

    final messenger = ScaffoldMessenger.of(widget.outerContext);
    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(newPin);
      if (mounted) {
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('PIN aggiornato con successo'),
            backgroundColor: Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      for (final c in _newControllers) { c.clear(); }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _newFocus[0].requestFocus();
      });
      setState(() => _isLoading = false);
      _errorNotifier.value = 'Errore aggiornamento PIN';
    }
  }

  // Stable PIN row — single unified bar with dividers
  Widget _pinRow(List<TextEditingController> ctrls, List<FocusNode> fNodes, void Function() onComplete) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: List.generate(6, (i) => Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Container(width: 1, height: 52, color: Colors.white.withValues(alpha: 0.08)),
                Expanded(
                  child: TextField(
                    controller: ctrls[i],
                    focusNode: fNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    obscureText: true,
                    style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(counterText: '', border: InputBorder.none, contentPadding: EdgeInsets.zero),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      if (_errorNotifier.value != null) _errorNotifier.value = null;
                      if (val.isNotEmpty && i < 5) fNodes[i + 1].requestFocus();
                      if (val.isEmpty && i > 0) fNodes[i - 1].requestFocus();
                      if (ctrls.every((c) => c.text.isNotEmpty)) onComplete();
                    },
                  ),
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = _step == 0;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Icon(Icons.pin_outlined, color: Colors.white54, size: 36),
            const SizedBox(height: 12),
            Text('CAMBIA PIN',
              style: GoogleFonts.cinzel(color: Colors.white, fontSize: 15, letterSpacing: 2)),
            const SizedBox(height: 6),
            Text(
              isCurrent ? 'Inserisci il PIN attuale' : 'Scegli il nuovo PIN a 6 cifre',
              style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 28),
            isCurrent
                ? _pinRow(_currentControllers, _currentFocus, _submitCurrentPin)
                : _pinRow(_newControllers, _newFocus, _submitNewPin),
            // Error text only — no rebuild of PIN boxes
            ValueListenableBuilder<String?>(
              valueListenable: _errorNotifier,
              builder: (_, error, __) => error != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error,
                        style: GoogleFonts.montserrat(color: const Color(0xFFDC143C), fontSize: 12),
                      ),
                    )
                  : const SizedBox(height: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (isCurrent ? _submitCurrentPin : _submitNewPin),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                    : Text('SALVA PIN', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final outerCtx = context;
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: const Color(0xFFFF453A).withValues(alpha: 0.3), width: 1),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Questa azione è irreversibile. Inserisci il tuo PIN per confermare.',
                style: GoogleFonts.montserrat(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), letterSpacing: 8),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFFF453A).withValues(alpha: 0.5)),
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
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1))
                      ),
                    ),
                    child: Text('ANNULLA',
                        style: GoogleFonts.montserrat(
                            color: Colors.white.withValues(alpha: 0.6),
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
                      final pin = pinController.text.trim();
                      Navigator.pop(context);
                      try {
                        await ref.read(authServiceProvider).deleteAccount(
                          password: pin.isNotEmpty ? pin : null,
                        );
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
                      backgroundColor: const Color(0xFF2A1010),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: const Color(0xFFFF453A).withValues(alpha: 0.5)),
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
            return appDateTime.isBefore(now) ||
                app.status == AppointmentStatus.cancelled;
          } else {
            return appDateTime.isAfter(now) &&
                app.status != AppointmentStatus.cancelled &&
                app.status != AppointmentStatus.noShow;
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
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 16),
                Text(
                  isHistory
                      ? 'Nessun appuntamento passato'
                      : 'Nessun appuntamento in programma',
                  style: TextStyle(
                    color: Colors.grey.withValues(alpha: 0.3),
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
                if (!isHistory) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/booking'),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(
                      'PRENOTA ORA',
                      style: GoogleFonts.montserrat(
                          fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4AF37),
                      side: BorderSide(color: const Color(0xFFD4AF37).withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return GroupedAppointmentsList(
          appointments: filteredAppointments,
          showBarber: userRole == UserRole.client,
          initiallyExpanded: true,
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
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
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
                    .updateAppointmentStatus(apt.id, AppointmentStatus.cancelled);
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
      barrierColor: Colors.black.withValues(alpha: 0.9), // Darker barrier
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
                    color: Colors.white.withValues(alpha: 0.1), // Subtle Silver Border
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05), // Cold Silver Glow
                      blurRadius: 30,
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Header con watermark ---
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(26),
                        topRight: Radius.circular(26),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF1C1C1C), Color(0xFF111111)],
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Watermark logo sfocato
                            Positioned.fill(
                              child: Opacity(
                                opacity: 0.04,
                                child: Image.asset(
                                  'assets/images/icon_premium_v2.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  width: 78,
                                  height: 78,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/icon_premium_v2.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'THE GENTLEMEN',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'B A R B E R S T Y L E',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.3),
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Sottile linea separatrice
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // --- Content Body ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                      child: Column(
                        children: [
                          // Quote con bordo laterale sinistro
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 2,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.5),
                                        Colors.white.withValues(alpha: 0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'L\'Eccellenza è uno stile di vita.',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white.withValues(alpha: 0.9),
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '— The Gentlemen',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.35),
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Non offriamo solo tagli, ma un\'atmosfera dove la tradizione incontra il lusso moderno. Ogni dettaglio è stato pensato per offrirti un momento di puro relax ed eleganza.',
                            textAlign: TextAlign.left,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.5),
                              height: 1.75,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Instagram Button — gradient ufficiale
                          SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF833AB4),
                                    Color(0xFFE1306C),
                                    Color(0xFFFCAF45),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE1306C).withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
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
                                      debugPrint('Could not launch Instagram: \$e');
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(FontAwesomeIcons.instagram,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 12),
                                        Text(
                                          'SEGUICI SU INSTAGRAM',
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            fontSize: 12,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Footer ---
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.05)),
                        ),
                      ),
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(26),
                              bottomRight: Radius.circular(26),
                            ),
                          ),
                        ),
                        child: Text(
                          'CHIUDI',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                            fontSize: 11,
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

class _GuestProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.8),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/icon_premium_v2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                Text(
                  'IL TUO PROFILO',
                  style: GoogleFonts.cinzel(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),

                const SizedBox(height: 6),

                // Divider line like home screen
                Container(
                  width: 60,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),

                const SizedBox(height: 16),

                Text(
                  'Accedi per gestire i tuoi appuntamenti\ne vedere la cronologia.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.white38,
                    height: 1.7,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 52),

                // Primary button - same dark metallic style as home "PRENOTA ORA"
                GestureDetector(
                  onTap: () => context.go('/auth'),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF222222),
                          Color(0xFF111111),
                          Color(0xFF222222),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.08),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(1.5),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(27),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF2A2A2A), Color(0xFF000000)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'ACCEDI',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              color: const Color(0xFFFAFAFA),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Secondary - subtle text link
                GestureDetector(
                  onTap: () => context.go('/auth'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Non hai un account?  REGISTRATI',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: Colors.white38,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Legal links - accessible before login per Apple guideline 5.1.1
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final url = Uri.parse('https://barbershop-gentleman.web.app/privacy.html');
                        if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      child: Text(
                        'Privacy Policy',
                        style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white24, letterSpacing: 0.5),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('·', style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white12)),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final url = Uri.parse('https://barbershop-gentleman.web.app/terms.html');
                        if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      child: Text(
                        'Termini di Servizio',
                        style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white24, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
