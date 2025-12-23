import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/seed_service.dart';
import '../../core/ui/hexagon_painter.dart';
import 'widgets/video_header.dart';
import 'dart:ui';
import 'dart:async';
import '../../services/firestore_service.dart';
import '../../models/shop_settings_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _drawAnimation;


  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _drawAnimation =
        CurvedAnimation(parent: _logoController, curve: Curves.easeInOut);

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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              child: VideoHeader(
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
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.02), // Very subtle
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
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
                                color: Colors.black.withOpacity(0.8),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/icon_premium.png',
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            letterSpacing: 8,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // 4. Divider Line (Silver)
                        Container(
                          width: 40,
                          height: 1,
                          color: Theme.of(context).dividerColor.withOpacity(0.6),
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
            ),
            


            // Image Carousel Section
            const _HomeCarousel(),

            // Services Section
            Container(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.grey[50], // Matches the section below
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Column(
                children: [
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        Text(
                          'I NOSTRI SERVIZI',
                          style: GoogleFonts.cinzel(
                            // Consistent font
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
                            // Consistent font
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            letterSpacing: 1,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),

                  // Service Cards Carousel
                  const SizedBox(
                    height: 360, // Increased height for better spacing
                    child: RepaintBoundary(
                      child: _ServicesCarousel(),
                    ),
                  ),
                ],
              ),
            ),

            // Premium Digital Business Card Section
            Container(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0A0A) : Colors.white,
              child: Column(
                children: [
                   // Announcement Banner (Moved here)
                   Container(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0A0A) : Colors.white,
                      padding: const EdgeInsets.only(top: 24, left: 24, right: 24), // Added padding for spacing
                      child: const _AnnouncementBanner(),
                   ),
                   const SizedBox(height: 8),
                ],
              ),
            ),

            // Footer / Business Card Content
            Container(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0A0A) : Colors.white,
              padding: const EdgeInsets.all(24),
              child: FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    colors: [
                        Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white,
                        Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0A0A) : Colors.grey[200]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white.withOpacity(0.1) 
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header with Logo
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Theme.of(context).colorScheme.onSurface),
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/icon_premium.png',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'THE GENTLEMEN',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'BARBERSTYLE',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    letterSpacing: 4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      FontAwesomeIcons.whatsapp,
                                      color: Color(0xFF25D366),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+39 351 482 3048',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Address
                            _ContactRow(
                              icon: Icons.location_on,
                              title: 'Via Borgo Eniano, 50',
                              subtitle: '35044 Montagnana PD, Italy',
                              onTap: () async {
                                final uri = Uri.parse(
                                    'https://maps.google.com/?q=Via+Borgo+Eniano+50+Montagnana+PD');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                            const SizedBox(height: 24),

                            // Phone
                            _ContactRow(
                              icon: Icons.phone,
                              title: '+39 351 482 3048',
                              subtitle: 'Chiamaci per info',
                              onTap: () async {
                                final uri = Uri.parse('tel:+393514823048');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              },
                            ),
                            const SizedBox(height: 32),

                            // Hours Grid
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'ORARI DI APERTURA',
                                    style: GoogleFonts.montserrat(
                                      color: const Color(0xFFFAFAFA),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _HoursRow(
                                      day: 'Lun - Gio',
                                      hours: '10:00-12:30 | 14:30-20:00'),
                                  const SizedBox(height: 8),
                                  _HoursRow(
                                      day: 'Venerdì',
                                      hours: '10:00-12:30 | 14:00-20:30'),
                                  const SizedBox(height: 8),
                                  _HoursRow(
                                      day: 'Sabato', hours: '09:00 - 20:00'),
                                  const SizedBox(height: 8),
                                  _HoursRow(
                                      day: 'Domenica', hours: '10:00 - 18:00'),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Social Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SocialButton(
                                  icon: FontAwesomeIcons.instagram,
                                  url:
                                      'https://www.instagram.com/the_gentlemen_barberstyle/',
                                ),
                                const SizedBox(width: 20),
                                _SocialButton(
                                  icon: FontAwesomeIcons.whatsapp,
                                  url: 'https://wa.me/393514823048',
                                ),
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
          ],
        ),
      ),
    );
  }

}

class _HomeCarousel extends StatefulWidget {
  const _HomeCarousel();

  @override
  State<_HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<_HomeCarousel> {
  PageController? _pageController; // Nullable for safety
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  static const int _infiniteCount = 10000;
  static const int _initialPage = _infiniteCount ~/ 2;

  // Viewport fraction for the carousel items
  static const double _viewportFraction = 0.8;

  @override
  void initState() {
    super.initState();
    // Initialize defaults
    _currentPage = _initialPage;
    _startAutoPlay();
  }

  void _ensureController() {
    if (_pageController == null) {
      _pageController = PageController(
        viewportFraction: _viewportFraction,
        initialPage: _initialPage,
      );
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController != null && _pageController!.hasClients) {
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
  void dispose() {
    _stopAutoPlay();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureController(); // Lazy Init

    final List<String> galleryImages = [
      'assets/images/gallery/haircut1.png',
      'assets/images/gallery/haircut2.png',
      'assets/images/gallery/haircut3.png',
      'assets/images/gallery/haircut4.png',
      'assets/images/gallery/haircut5.png',
    ];

    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.symmetric(vertical: 60),
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
                      colors: [
                        Colors.transparent,
                        Color(0xFFFFFFFF),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Cinematic Carousel
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
                      // Safe access to position
                      if (_pageController?.hasClients == true && 
                          _pageController!.positions.length == 1 &&
                          _pageController!.position.haveDimensions) {
                        value = _pageController!.page! - index;
                      } else {
                        value = (_currentPage - index).toDouble();
                      }

                      // Calculations for 3D effect
                      final double dist = value.clamp(-1.0, 1.0);
                      final double scale = 1.0 - (dist.abs() * 0.15); 
                      final double opacity = 1.0 - (dist.abs() * 0.5).clamp(0.0, 0.6); 
                      final double rotation = dist * 0.1; 

                      final Alignment imageAlignment = Alignment(dist * 0.5, 0);

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
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFFFFF).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                             Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                alignment: Alignment.center, 
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF1A1A1A),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.white24,
                                        size: 48,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.2),
                                    Colors.black.withOpacity(0.6),
                                  ],
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
          
          // Animated Indicators
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
                  color: isActive
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFFFFFFFF).withOpacity(0.2),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFFFFF).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
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
                  color: const Color(0xFFFFFFFF).withOpacity(0.1 + (0.1 * _glowAnimation.value)),
                  blurRadius: 8, // Sharper
                  spreadRadius: 1, 
                  offset: const Offset(0, 0),
                ),
                // Subtle Ambient Shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
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
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFFFFFFFF),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'PRENOTA ORA',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: const Color(0xFFFFFFFF),
                          ),
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

class _ServicesCarousel extends StatefulWidget {
  const _ServicesCarousel({super.key});

  @override
  State<_ServicesCarousel> createState() => _ServicesCarouselState();
}

class _ServicesCarouselState extends State<_ServicesCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  double _currentViewportFraction = 0.75;
  Timer? _autoPlayTimer;
  static const int _infiniteCount = 10000;
  static const int _initialPage = _infiniteCount ~/ 2;

  final List<Map<String, dynamic>> _services = [
    {
      'icon': Icons.content_cut,
      'title': 'Taglio Capelli',
      'description': 'Taglio classico o moderno eseguito con precisione e stile.',
      'price': '25€',
      'duration': '30 min',
      'featured': false,
    },
    {
      'icon': Icons.face,
      'title': 'Regolazione Barba',
      'description': 'Modellatura, rifinitura e trattamento panno caldo.',
      'price': '15€',
      'duration': '20 min',
      'featured': false,
    },
    {
      'icon': Icons.auto_awesome,
      'title': 'Taglio + Barba',
      'description': 'Il pacchetto completo per un look impeccabile e curato.',
      'price': '35€',
      'duration': '50 min',
      'featured': true,
    },
    {
      'icon': Icons.child_care,
      'title': 'Taglio Bambino',
      'description': 'Stile e divertimento per i più piccoli.',
      'price': '20€',
      'duration': '30 min',
      'featured': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: _currentViewportFraction,
      initialPage: _initialPage,
    );
    _currentPage = _initialPage;
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrWeb = screenWidth > 600;
    final cardWidth = isTabletOrWeb ? 500.0 : 360.0;
    final cardHeight = 340.0;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            // Stop auto-play on interaction
            onPanDown: (_) => _stopAutoPlay(),
            onPanCancel: () => _startAutoPlay(),
            onPanEnd: (_) => _startAutoPlay(),
            child: PageView.builder(
              key: ValueKey(_currentViewportFraction), // Force recreate on viewport change
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _infiniteCount,
              itemBuilder: (context, index) {
                // Modulo for infinite looping
                final serviceIndex = index % _services.length;
                final service = _services[serviceIndex];

                // 3D Depth & Rotation Effect
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 0.0;
                    if (_pageController.hasClients && 
                        _pageController.positions.length == 1 &&
                        _pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                    } else {
                      // Initial state fallback
                      value = (_currentPage - index).toDouble();
                    }

                    // Clamp to handle edge cases
                    final double dist = value.clamp(-1.0, 1.0);
                    
                    // Style Calculations
                    final double scale = 1.0 - (dist.abs() * 0.2);
                    final double opacity = 1.0 - (dist.abs() * 0.4).clamp(0.0, 0.6);
                    final double rotation = dist * 0.5; // Rotate Y

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // Perspective
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
                          icon: service['icon'],
                          title: service['title'],
                          description: service['description'],
                          price: service['price'],
                          duration: service['duration'],
                          featured: service['featured'],
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
        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_services.length, (index) {
            // Calculate active index from infinite scroll
            final activeIndex = _currentPage % _services.length;
            final isActive = activeIndex == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 32 : 8, // Longer active indicator
              height: 4,               // Slimmer
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFFFFFFFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ] : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PremiumServiceCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Definizione colori accent
    final accentColor = featured ? const Color(0xFFE0E0E0) : const Color(0xFFFFFFFF);
    
    return GestureDetector(
      onTap: () => context.push('/booking'),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(featured ? 0.15 : 0.05),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background & Border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: featured
                      ? [
                          const Color(0xFFE0E0E0).withOpacity(0.4), // Silver
                          const Color(0xFF1A1A1A),
                        ]
                      : [
                          const Color(0xFF444444),
                          const Color(0xFF111111),
                        ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.5), // Spessore bordo
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(23),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: featured
                          ? [
                              const Color(0xFF2C2C2C),
                              const Color(0xFF151515),
                            ]
                          : [
                              const Color(0xFF252525),
                              const Color(0xFF111111),
                            ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.all(compact ? 10 : 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withOpacity(0.1),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                  )
                                ],
                              ),
                              child: Icon(
                                icon,
                                color: accentColor,
                                size: compact ? 22 : 26,
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),

                        // Title
                        Text(
                          title.toUpperCase(),
                          style: GoogleFonts.cinzel(
                            fontSize: compact ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          description,
                          style: GoogleFonts.montserrat(
                            fontSize: compact ? 11 : 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),

                        // Divider
                        Container(
                          width: double.infinity,
                          height: 1,
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
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
                                  price,
                                  style: GoogleFonts.cinzel(
                                    fontSize: compact ? 18 : 22,
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
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38)
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      duration,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // "Prenota" Button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.4),
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
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // "Featured" Badge Top-Right
            if (featured)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(-2, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'CONSIGLIATO',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            size: 14,
          ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String day;
  final String hours;

  const _HoursRow({
    required this.day,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: GoogleFonts.montserrat(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Text(
          hours,
          style: GoogleFonts.montserrat(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String url;

  const _SocialButton({
    required this.icon,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        debugPrint('SocialButton tapped: $url');
        try {
          // Force launch, catch error if it fails.
          // This bypasses potential false negatives from canLaunchUrl
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Error launching URL: $e');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 20,
        ),
      ),
    );
  }
}

class _AnnouncementBanner extends ConsumerWidget {
  const _AnnouncementBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(shopSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        if (!settings.isAnnouncementActive || settings.announcement.isEmpty) {
          return const SizedBox.shrink();
        }

        return FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: Center(
            child: Padding( // Removed ConstrainedBox to let it fill width
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Reduced vertical padding
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF151515) 
                        : Colors.white,
                    Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF1E1E1E) 
                        : const Color(0xFFF5F5F5),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15), // Gold glow
                    blurRadius: 20,
                    offset: const Offset(0, 0), // Centered glow
                    spreadRadius: 1,
                  ),
                ],
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Centered
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // Centered
                  children: [
                    Icon(
                      Icons.campaign_rounded, 
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AVVISO',
                      style: GoogleFonts.cinzel(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  settings.announcement,
                  textAlign: TextAlign.center, // Centered text
                  style: GoogleFonts.montserrat(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
