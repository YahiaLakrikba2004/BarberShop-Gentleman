import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart' hide CarouselController;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/seed_service.dart';
import '../../core/ui/hexagon_painter.dart';
import 'dart:ui';

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
      backgroundColor: const Color(0xFF0A0A0A),
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
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 60), // Adjusted top padding since AppBar is gone
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A), // Deepest Black
                  // Code-generated Vignette (No missing assets)
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.3, // Slightly tighter spotlight
                    colors: [
                      Color(0xFF1F1F1F), // Dark Grey Center
                      Color(0xFF0A0A0A), // Pure Black Corners
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
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
                          color: const Color(0xFFFFFFFF).withOpacity(0.02), // Very subtle
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFFFFF).withOpacity(0.03),
                              blurRadius: 80,
                              spreadRadius: 10,
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
                              color: const Color(0xFF333333),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.8), // Stronger shadow for depth
                                blurRadius: 30,
                                offset: const Offset(0, 10),
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
                          'THE GENTLEMAN',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            fontSize: 32, 
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFECECEC),
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
                            color: const Color(0xFF888888),
                            letterSpacing: 8,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // 4. Divider Line (Silver)
                        Container(
                          width: 40,
                          height: 1,
                          color: const Color(0xFFE0E0E0).withOpacity(0.6),
                        ),

                        const SizedBox(height: 32), // Reduced from 36

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
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
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
                        const SizedBox(height: 16),
                        Text(
                          'Trattamenti Premium per il Gentleman Moderno',
                          style: GoogleFonts.montserrat(
                            // Consistent font
                            fontSize: 14,
                            color: Colors.white60,
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
              color: const Color(0xFF0A0A0A),
              padding: const EdgeInsets.all(24),
              child: FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1A1A),
                        const Color(0xFF0A0A0A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFFFFFFF).withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFFFFF).withOpacity(0.1),
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
                              color: const Color(0xFFFFFFFF).withOpacity(0.2),
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
                                    Border.all(color: const Color(0xFFFFFFFF)),
                                color: const Color(0xFFFFFFFF).withOpacity(0.1),
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
                                  'THE GENTLEMAN',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFAFAFA),
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'BARBERSTYLE',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    color: Colors.white60,
                                    letterSpacing: 4,
                                  ),
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
                                  url: 'https://wa.me/393331234567',
                                ),
                                const SizedBox(width: 20),
                                _SocialButton(
                                  icon: FontAwesomeIcons.facebook,
                                  url: 'https://facebook.com',
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
  int _currentCarouselIndex = 0;

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 16),
                Text(
                  'Esempi di Tagli e Acconciature',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.white60,
                    letterSpacing: 1,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          RepaintBoundary(
            child: CarouselSlider(
              options: CarouselOptions(
                height: 400,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                enlargeCenterPage: true,
                viewportFraction: 0.8,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
              ),
              items: galleryImages.map((imagePath) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFFFFF).withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFFFFF).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              cacheWidth: 800, // Optimize memory usage
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF1A1A1A),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Color(0x80FFFFFF),
                                        size: 48,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Immagine non disponibile',
                                        style: TextStyle(
                                          color: Color(0x80FFFFFF),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // Gradient Overlay for Premium Feel
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Animated Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: galleryImages.asMap().entries.map((entry) {
              return GestureDetector(
                onTap: () {}, // Carousel controller could be added here
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentCarouselIndex == entry.key ? 24.0 : 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentCarouselIndex == entry.key
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFFFFFFFF).withOpacity(0.2),
                    boxShadow: _currentCarouselIndex == entry.key
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFFFFF).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
                            color: const Color(0xFFFAFAFA),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Description
                        Text(
                          description,
                          style: GoogleFonts.montserrat(
                            fontSize: compact ? 11 : 12,
                            color: Colors.white70,
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
                          color: Colors.white.withOpacity(0.1),
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
                                      color: Colors.white38
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      duration,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: Colors.white38,
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
                    color: const Color(0xFFD4AF37),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
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
              color: const Color(0xFFFFFFFF).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFFFFF).withOpacity(0.1),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFFFFFF),
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
                    color: const Color(0xFFFAFAFA),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color: const Color(0xFFFFFFFF).withOpacity(0.3),
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
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          hours,
          style: GoogleFonts.montserrat(
            color: const Color(0xFFFFFFFF),
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
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFFFFF).withOpacity(0.05),
          border: Border.all(
            color: const Color(0xFFFFFFFF).withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: const Color(0xFFFFFFFF),
          size: 20,
        ),
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
  const _ServicesCarousel();

  @override
  State<_ServicesCarousel> createState() => _ServicesCarouselState();
}

class _ServicesCarouselState extends State<_ServicesCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  double _currentViewportFraction = 0.75;

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
    _pageController = PageController(viewportFraction: _currentViewportFraction);
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
      oldController.dispose();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrWeb = screenWidth > 600;
    final cardWidth = isTabletOrWeb ? 500.0 : 360.0;

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              
              // Animated Scale Effect
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  } else {
                    value = index == _currentPage ? 1.0 : 0.8;
                  }
                  
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 340,
                      width: Curves.easeOut.transform(value) * cardWidth,
                      child: child,
                    ),
                  );
                },
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
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_services.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFFFFFFFF)
                    : const Color(0xFFFFFFFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
