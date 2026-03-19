import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'widgets/video_header.dart';
import 'dart:async';
import '../../services/firestore_service.dart';
import 'home_screen_widgets.dart';
import '../../services/notification_service.dart';
import '../../models/appointment_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  bool _pendingNotificationsDelivered = false; // ignore: prefer_final_fields

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    // Start animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _logoController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    // Deliver any pending notifications queued by admin (confirmation, announcements, etc.)
    // Covers both: app already logged in on open, and fresh login transition
    if (user != null && !_pendingNotificationsDelivered) {
      _pendingNotificationsDelivered = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) ref.read(notificationServiceProvider).deliverPendingNotifications(user.id);
      });
    }
    ref.listen<AsyncValue<UserModel?>>(currentUserProfileProvider, (previous, next) {
      final prevUser = previous?.value;
      final nextUser = next.value;
      if (prevUser == null && nextUser != null) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) ref.read(notificationServiceProvider).deliverPendingNotifications(nextUser.id);
        });
      }
    });

    // [NEW] Notification Sync Listening
    // When we have a user, we listen to their appointments changes to sync notifications
    if (user != null) {
      ref.listen<AsyncValue<List<AppointmentModel>>>(
        userAppointmentsProvider(user.id),
        (previous, next) {
          next.whenData((appointments) {
            final prevAppointments = previous?.value;
            
            // Only process if we have previous data and it actually changed
            if (prevAppointments != null && prevAppointments != appointments) {
               // 1. Check for status/time changes initiated by admin
               for (final apt in appointments) {
                 final oldApt = prevAppointments.where((p) => p.id == apt.id).firstOrNull;
                 if (oldApt != null) {
                   // If status changed to cancelled (and not by current user action in this session)
                   if (oldApt.status != apt.status && apt.status == AppointmentStatus.cancelled) {
                     ref.read(notificationServiceProvider).showImmediateNotification(
                       title: 'Appuntamento Annullato',
                       body: 'Il tuo appuntamento per ${apt.serviceName} del ${DateFormat('dd/MM HH:mm').format(apt.date)} è stato annullato dal salone.',
                       payload: '/calendar',
                     );
                   }
                   // If date/time changed
                   else if (!oldApt.date.isAtSameMomentAs(apt.date)) {
                     ref.read(notificationServiceProvider).showImmediateNotification(
                       title: 'Orario Modificato',
                       body: 'L\'orario del tuo appuntamento per ${apt.serviceName} è stato spostato al ${DateFormat('dd/MM HH:mm').format(apt.date)}.',
                       payload: '/calendar',
                     );
                   }
                 }
               }
               
               // 2. Reschedule all reminders
               ref.read(notificationServiceProvider).rescheduleAllAppointments(appointments);
            } else if (prevAppointments == null) {
               // First load: just schedule reminders
               ref.read(notificationServiceProvider).rescheduleAllAppointments(appointments);
            }
          });
        },
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Explicitly set to deep black to match VideoHeader
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // HIDE APP BAR completely for a cleaner Full-Screen look
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Hero Section - Neo-Classic Luxury Design
            FadeIn(
              duration: const Duration(milliseconds: 800),
              child: Stack(
                clipBehavior: Clip.none, // Permette al filler di estendersi oltre i limiti dello Stack
                children: [
                  // Filler superiore per l'overscroll su iOS
                  Positioned(
                    top: -1000,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1000,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                  VideoHeader(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Subtle Background Glow
                        Positioned(
                          top: 60,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.02), // Very subtle
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),

                        Column(
                          children: [
                            // 1. Logo - Static & Iconic
                            SizedBox(height: MediaQuery.of(context).padding.top + 20),
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
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
                            
                            const SizedBox(height: 24), // Tighter spacing

                            // 2. Title - Cinzel (Modern Classic)
                            Text(
                              'THE GENTLEMEN',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cinzel(
                                fontSize: 32, 
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: 4,
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // 3. Subtitle - Montserrat (Clean)
                            Text(
                              'BARBERSTYLE',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                letterSpacing: 8,
                              ),
                            ),

                            const SizedBox(height: 36),

                            // 4. Divider Line (Silver)
                            Container(
                              width: 40,
                              height: 1,
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                            ),

                            const SizedBox(height: 60), // Increased to lower button

                            // 5. CTA Button - Fixed Width & Smaller
                            SizedBox(
                              width: 260, // Increased from 220
                              height: 56, // Increased from 50
                              child: _PremiumAnimatedButton(
                                onPressed: () => context.push('/booking'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Next Appointment Banner sovrapposta alla fine dell'hero
            if (user != null && user.role == UserRole.client)
              Transform.translate(
                offset: const Offset(0, -28),
                child: _NextAppointmentBanner(userId: user.id),
              ),

            // Image Carousel Section
            const _HomeCarousel(),

            // Services Section
            Builder(builder: (context) {
              final isDesktop = MediaQuery.of(context).size.width > 800;
              return Container(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.grey[50],
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: isDesktop ? 60 : 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      children: [
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: Column(
                            children: [
                              Text(
                                'I NOSTRI SERVIZI',
                                style: GoogleFonts.cinzel(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: 4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: 80,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Theme.of(context).colorScheme.primary,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Trattamenti Premium per i Gentlemen Moderni',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                  letterSpacing: 1,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 56),
                        SizedBox(
                          height: isDesktop ? 400 : 360,
                          child: const RepaintBoundary(child: _ServicesCarousel()),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Footer / Business Card + Announcement
            Builder(builder: (context) {
              final isDesktop = MediaQuery.of(context).size.width > 800;
              final bgColor = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0A0A) : Colors.white;
              return Container(
                color: bgColor,
                padding: EdgeInsets.all(isDesktop ? 40 : 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Announcement Banner
                        const AnnouncementBanner(),
                        const SizedBox(height: 24),

                        // Business Card
                        FadeInUp(
                          delay: const Duration(milliseconds: 200),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : Colors.white.withValues(alpha: 0.7),
                                      Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white.withValues(alpha: 0.02)
                                          : Colors.white.withValues(alpha: 0.3),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)],
                                ),
                                child: Column(
                                  children: [
                                    // Header with Logo
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2))),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Theme.of(context).colorScheme.onSurface),
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                            ),
                                            child: ClipOval(child: Image.asset('assets/images/icon_premium_v2.png', width: 24, height: 24, fit: BoxFit.cover)),
                                          ),
                                          const SizedBox(width: 16),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('THE GENTLEMEN', style: GoogleFonts.cinzel(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 2)),
                                              Text('BARBERSTYLE', style: GoogleFonts.montserrat(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), letterSpacing: 4)),
                                              const SizedBox(height: 4),
                                              Row(children: [
                                                const Icon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366), size: 14),
                                                const SizedBox(width: 8),
                                                Text('+39 351 482 3048', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                                              ]),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Content — Row on desktop, Column on mobile
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: isDesktop
                                          ? Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // Left: contacts + social
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      ContactRow(
                                                        icon: Icons.location_on,
                                                        title: 'Via Borgo Eniano, 50',
                                                        subtitle: '35044 Montagnana PD, Italia',
                                                        onTap: () async {
                                                          final uri = Uri.parse('https://maps.google.com/?q=Via+Borgo+Eniano+50+Montagnana+PD');
                                                          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                        },
                                                      ),
                                                      const SizedBox(height: 24),
                                                      ContactRow(
                                                        icon: Icons.phone,
                                                        title: '+39 351 482 3048',
                                                        subtitle: 'Chiamaci per info',
                                                        onTap: () async {
                                                          final uri = Uri.parse('tel:+393514823048');
                                                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                                                        },
                                                      ),
                                                      const SizedBox(height: 32),
                                                      const Row(
                                                        children: [
                                                          SocialButton(icon: FontAwesomeIcons.instagram, url: 'https://www.instagram.com/the_gentlemen_barberstyle/'),
                                                          SizedBox(width: 20),
                                                          SocialButton(icon: FontAwesomeIcons.whatsapp, url: 'https://wa.me/393514823048'),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 40),
                                                // Right: hours
                                                Expanded(
                                                  child: Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.3),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text('ORARI DI APERTURA', style: GoogleFonts.montserrat(color: const Color(0xFFFAFAFA), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                                        const SizedBox(height: 16),
                                                        const HoursRow(day: 'Lun - Gio', hours: '10:00-12:30 | 14:30-20:00'),
                                                        const SizedBox(height: 8),
                                                        const HoursRow(day: 'Venerdì', hours: '10:00-12:30 | 14:00-20:30'),
                                                        const SizedBox(height: 8),
                                                        const HoursRow(day: 'Sabato', hours: '09:00 - 20:00'),
                                                        const SizedBox(height: 8),
                                                        const HoursRow(day: 'Domenica', hours: '10:00 - 18:00'),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              children: [
                                                ContactRow(
                                                  icon: Icons.location_on,
                                                  title: 'Via Borgo Eniano, 50',
                                                  subtitle: '35044 Montagnana PD, Italia',
                                                  onTap: () async {
                                                    final uri = Uri.parse('https://maps.google.com/?q=Via+Borgo+Eniano+50+Montagnana+PD');
                                                    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                                                  },
                                                ),
                                                const SizedBox(height: 24),
                                                ContactRow(
                                                  icon: Icons.phone,
                                                  title: '+39 351 482 3048',
                                                  subtitle: 'Chiamaci per info',
                                                  onTap: () async {
                                                    final uri = Uri.parse('tel:+393514823048');
                                                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                                                  },
                                                ),
                                                const SizedBox(height: 32),
                                                Container(
                                                  padding: const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.3),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Text('ORARI DI APERTURA', style: GoogleFonts.montserrat(color: const Color(0xFFFAFAFA), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                                      const SizedBox(height: 16),
                                                      const HoursRow(day: 'Lun - Gio', hours: '10:00-12:30 | 14:30-20:00'),
                                                      const SizedBox(height: 8),
                                                      const HoursRow(day: 'Venerdì', hours: '10:00-12:30 | 14:00-20:30'),
                                                      const SizedBox(height: 8),
                                                      const HoursRow(day: 'Sabato', hours: '09:00 - 20:00'),
                                                      const SizedBox(height: 8),
                                                      const HoursRow(day: 'Domenica', hours: '10:00 - 18:00'),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 32),
                                                const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    SocialButton(icon: FontAwesomeIcons.instagram, url: 'https://www.instagram.com/the_gentlemen_barberstyle/'),
                                                    SizedBox(width: 20),
                                                    SocialButton(icon: FontAwesomeIcons.whatsapp, url: 'https://wa.me/393514823048'),
                                                  ],
                                                ),
                                              ],
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
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

}

class _HomeCarousel extends ConsumerStatefulWidget {
  const _HomeCarousel();

  @override
  ConsumerState<_HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends ConsumerState<_HomeCarousel> {
  PageController? _pageController; // Nullable for safety
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  bool _active = true; // tracks whether widget is still in tree
  static const int _infiniteCount = 10000;
  static const int _initialPage = _infiniteCount ~/ 2;

  // Viewport fraction for the carousel items
  static const double _viewportFraction = 0.8;

  @override
  void initState() {
    super.initState();
    _active = true;
    // Initialize defaults
    _currentPage = _initialPage;
    _startAutoPlay();
  }

  void _ensureController() {
    _pageController ??= PageController(
        viewportFraction: _viewportFraction,
        initialPage: _initialPage,
      );
  }

  void _startAutoPlay() {
    // ensure that timer is restarted only when widget is active
    _stopAutoPlay();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      // if state has been disposed, deactivated, or otherwise inactive, stop further work
      if (!_active || !mounted || _pageController == null) {
        timer.cancel();
        return;
      }
      if (_pageController!.hasClients) {
        _pageController!.nextPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  @override
  void deactivate() {
    // widget is leaving the tree; prevent timer callbacks while deactivated
    _active = false;
    _stopAutoPlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureController(); // Lazy Init

    final shopSettings = ref.watch(shopSettingsProvider).value;
    final List<String> galleryImages = (shopSettings?.galleryImages.isNotEmpty == true)
        ? shopSettings!.galleryImages
        : [
            'assets/images/gallery/gallery_user_1.jpg',
            'assets/images/gallery/gallery_user_2.jpg',
            'assets/images/gallery/gallery_user_3.jpg',
            'assets/images/gallery/gallery_user_4.jpg',
            'assets/images/gallery/gallery_user_5.jpg',
            'assets/images/gallery/gallery_user_6.jpg',
            'assets/images/gallery/gallery_user_7.jpg',
          ];

    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Container(
      color: const Color(0xFF0A0A0A),
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: isDesktop ? 60 : 0),
      child: Column(
        children: [
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Column(
              children: [
                Text(
                  'I NOSTRI LAVORI',
                  style: GoogleFonts.cinzel(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFAFAFA),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 80,
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xFFFFFFFF), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          if (isDesktop)
            // Desktop: 3-column grid
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: galleryImages.length,
                  itemBuilder: (context, index) {
                    final imagePath = galleryImages[index];
                    return _buildGalleryItem(imagePath);
                  },
                ),
              ),
            )
          else ...[
            // Mobile: cinematic carousel
            SizedBox(
              height: 400,
              child: GestureDetector(
                onPanDown: (_) => _stopAutoPlay(),
                onPanCancel: () => _startAutoPlay(),
                onPanEnd: (_) => _startAutoPlay(),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _infiniteCount,
                  itemBuilder: (context, index) {
                    final imageIndex = index % galleryImages.length;
                    final imagePath = galleryImages[imageIndex];

                    return AnimatedBuilder(
                      animation: _pageController!,
                      builder: (context, child) {
                        double value = 0.0;
                        if (_pageController?.hasClients == true &&
                            _pageController!.positions.length == 1 &&
                            _pageController!.position.haveDimensions) {
                          value = _pageController!.page! - index;
                        } else {
                          value = (_currentPage - index).toDouble();
                        }
                        final double dist = value.clamp(-1.0, 1.0);
                        final double scale = 1.0 - (dist.abs() * 0.15);
                        final double opacity = 1.0 - (dist.abs() * 0.5).clamp(0.0, 0.6);
                        final double rotation = dist * 0.1;

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(rotation),
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(scale: scale, child: child),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFFFFF).withValues(alpha: 0.3), width: 1),
                          boxShadow: [BoxShadow(color: const Color(0xFF000000).withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, 10))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildGalleryImage(imagePath),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.2), Colors.black.withValues(alpha: 0.6)],
                                    stops: const [0.6, 0.8, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Animated Indicators (mobile only)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(galleryImages.length, (index) {
                final activeIndex = _currentPage % galleryImages.length;
                final isActive = activeIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 32.0 : 8.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF).withValues(alpha: 0.2),
                    boxShadow: isActive ? [BoxShadow(color: const Color(0xFFFFFFFF).withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)] : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryItem(String imagePath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFFFFF).withValues(alpha: 0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildGalleryImage(imagePath),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryImage(String imagePath) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(imagePath, fit: BoxFit.cover, alignment: Alignment.center, errorBuilder: (_, __, ___) => const _GalleryFallback());
    }
    if (imagePath.startsWith('https://')) {
      return Image.network(imagePath, fit: BoxFit.cover, alignment: Alignment.center, gaplessPlayback: true, errorBuilder: (_, __, ___) => const _GalleryFallback());
    }
    // Retrocompatibilità: immagini vecchie salvate come base64
    try {
      return Image.memory(base64Decode(imagePath), fit: BoxFit.cover, alignment: Alignment.center, gaplessPlayback: true, errorBuilder: (_, __, ___) => const _GalleryFallback());
    } catch (_) {
      return const _GalleryFallback();
    }
  }
}

class _PremiumAnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _PremiumAnimatedButton({required this.onPressed});

  @override
  State<_PremiumAnimatedButton> createState() => _PremiumAnimatedButtonState();
}

class _PremiumAnimatedButtonState extends State<_PremiumAnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _glowAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _glowController]),
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF222222), // Dark Metallic
                  Color(0xFF111111), // Almost Black
                  Color(0xFF222222), // Dark Metallic
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                // Clean White Border Glow - No blurry spread
                BoxShadow(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.1 + (0.1 * _glowAnimation.value)),
                  blurRadius: 8, // Sharper
                  spreadRadius: 1, 
                  offset: const Offset(0, 0),
                ),
                // Subtle Ambient Shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(2.0), // Border Width
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2A2A2A), // Lighter Black (Top Light)
                      Color(0xFF000000), // Pure Black
                    ],
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment(_glowAnimation.value - 1.0, -0.5),
                          end: Alignment(_glowAnimation.value, 0.5),
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.25), // The "shine"
                            Colors.white.withValues(alpha: 0.0),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PRENOTA ORA',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: const Color(0xFFFAFAFA),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: Color(0xFFFAFAFA),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryFallback extends StatelessWidget {
  const _GalleryFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.white24, size: 48),
      ),
    );
  }
}

class _ServicesCarousel extends ConsumerStatefulWidget {
  const _ServicesCarousel();

  @override
  ConsumerState<_ServicesCarousel> createState() => _ServicesCarouselState();
}

class _ServicesCarouselState extends ConsumerState<_ServicesCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  double _currentViewportFraction = 0.75;
  Timer? _autoPlayTimer;
  bool _active = true;
  static const int _infiniteCount = 10000;
  static const int _initialPage = _infiniteCount ~/ 2;

  @override
  void initState() {
    super.initState();
    _active = true;
    _pageController = PageController(
      viewportFraction: _currentViewportFraction,
      initialPage: _initialPage,
    );
    _currentPage = _initialPage;
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _stopAutoPlay();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_active || !mounted) {
        timer.cancel();
        return;
      }
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  @override
  void deactivate() {
    _active = false;
    // stop while the widget is removed from the tree (e.g. navigating away)
    _stopAutoPlay();
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrWeb = screenWidth > 600;
    final newViewportFraction = isTabletOrWeb ? 0.6 : 0.75;

    if (newViewportFraction != _currentViewportFraction) {
      _currentViewportFraction = newViewportFraction;
      final oldController = _pageController;
      _pageController = PageController(
        viewportFraction: _currentViewportFraction,
        initialPage: _currentPage,
      );
      // Postpone disposal to avoid "ScrollController attached to multiple scroll views"
      // triggering if the tree is in a transient state.
      // However, usually disposing immediately is fine IF the widget rebuilds immediately.
      // The issue is likely checking .position on the OLD controller if animated builder holds it.
      
      // We will rely on Key in PageView to force fresh state.
      oldController.dispose();
    }
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  IconData _getIconForService(String name) {
    final n = name.toLowerCase();
    if (n.contains('taglio') && n.contains('barba')) return Icons.auto_awesome;
    if (n.contains('taglio') && n.contains('bambino')) return Icons.child_care;
    if (n.contains('taglio')) return Icons.content_cut;
    if (n.contains('barba')) return Icons.face;
    return Icons.star_outline;
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceListProvider);

    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) return const SizedBox.shrink();

        final screenWidth = MediaQuery.of(context).size.width;
        final isTabletOrWeb = screenWidth > 600;
        final cardWidth = isTabletOrWeb ? 500.0 : 360.0;
        const cardHeight = 340.0;

        return Column(
          children: [
            Expanded(
              child: GestureDetector(
                onPanDown: (_) => _stopAutoPlay(),
                onPanCancel: () => _startAutoPlay(),
                onPanEnd: (_) => _startAutoPlay(),
                child: PageView.builder(
                  key: ValueKey(_currentViewportFraction),
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _infiniteCount,
                  itemBuilder: (context, index) {
                    final service = services[index % services.length];

                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 0.0;
                        if (_pageController.hasClients &&
                            _pageController.positions.length == 1 &&
                            _pageController.position.haveDimensions) {
                          value = _pageController.page! - index;
                        } else {
                          value = (_currentPage - index).toDouble();
                        }

                        final double dist = value.clamp(-1.0, 1.0);
                        final double scale = 1.0 - (dist.abs() * 0.2);
                        final double opacity = 1.0 - (dist.abs() * 0.4).clamp(0.0, 0.6);
                        final double rotation = dist * 0.5;

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateY(rotation),
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.scale(
                              scale: scale,
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: Center(
                        child: SizedBox(
                          height: cardHeight,
                          width: cardWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: _PremiumServiceCard(
                              icon: _getIconForService(service.name),
                              title: service.name,
                              description: service.description,
                              price: '${service.price.toInt()}€',
                              duration: '${service.durationMinutes} min',
                              featured: service.price > 20,
                              compact: false,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(services.length, (index) {
                final activeIndex = _currentPage % services.length;
                final isActive = activeIndex == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 32 : 8,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFFFFFFFF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(
          child: Icon(Icons.error_outline, color: Colors.redAccent)),
    );
  }
}

class _PremiumServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String price;
  final String duration;
  final bool featured;
  final bool compact;

  const _PremiumServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    this.featured = false,
    this.compact = false,
  });

  @override
  State<_PremiumServiceCard> createState() => _PremiumServiceCardState();
}

class _PremiumServiceCardState extends State<_PremiumServiceCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _showServiceDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 36),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: GoogleFonts.cinzel(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Full description
              if (widget.description.isNotEmpty) ...[
                Text(
                  widget.description,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),
              ],
              // Duration + Price chips
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.schedule, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            widget.duration,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.euro, color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            widget.price,
                            style: GoogleFonts.cinzel(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              // Book button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/booking');
                  },
                  icon: const Icon(Icons.content_cut, size: 18),
                  label: Text(
                    'PRENOTA ORA',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontSize: 14,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definizione colori accent
    final accentColor = widget.featured ? const Color(0xFFE0E0E0) : const Color(0xFFFFFFFF);
    
    return GestureDetector(
      onTap: () => _showServiceDetails(context),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.featured
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.08),
                    widget.featured
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.white.withValues(alpha: 0.02),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: widget.featured ? 0.2 : 0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(widget.compact ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(widget.compact ? 10 : 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accentColor.withValues(alpha: 0.1),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.15),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: accentColor,
                            size: widget.compact ? 22 : 26,
                          ),
                        ),
                        if (widget.featured)
                          FadeIn(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                'TOP',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const Spacer(),

                    // Title
                    Text(
                      widget.title.toUpperCase(),
                      style: GoogleFonts.cinzel(
                        fontSize: widget.compact ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      widget.description,
                      style: GoogleFonts.montserrat(
                        fontSize: widget.compact ? 11 : 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),

                    // Divider
                    Container(
                      width: double.infinity,
                      height: 0.5,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),

                    // Footer (Price & Action)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price & Duration Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.price,
                              style: GoogleFonts.cinzel(
                                fontSize: widget.compact ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule, 
                                  size: 12, 
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.duration,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // "Prenota" Button with Shimmer
                        AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (context, child) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.3),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment(_shimmerAnimation.value - 1.0, -0.5),
                                  end: Alignment(_shimmerAnimation.value, 0.5),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.15),
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'PRENOTA',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 10,
                                    color: accentColor,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Banner prossimo appuntamento ─────────────────────────────────────────────

class _NextAppointmentBanner extends ConsumerWidget {
  final String userId;
  const _NextAppointmentBanner({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aptsAsync = ref.watch(userAppointmentsProvider(userId));
    return aptsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (appointments) {
        final now = DateTime.now();
        final upcoming = appointments
            .where((a) =>
                a.status != AppointmentStatus.cancelled &&
                a.date.isAfter(now))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (upcoming.isEmpty) return const SizedBox.shrink();
        final next = upcoming.first;

        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        final aptDay = DateTime(next.date.year, next.date.month, next.date.day);
        final String dayLabel;
        if (aptDay == today) {
          dayLabel = 'OGGI';
        } else if (aptDay == tomorrow) {
          dayLabel = 'DOMANI';
        } else {
          dayLabel = DateFormat('EEE d MMM', 'it').format(next.date).toUpperCase();
        }

        return FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.content_cut,
                        color: Theme.of(context).colorScheme.primary, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROSSIMO APPUNTAMENTO',
                          style: GoogleFonts.cinzel(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${next.barberName}  ·  ${next.serviceName}',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dayLabel,
                        style: GoogleFonts.cinzel(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(next.date),
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.3), size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

