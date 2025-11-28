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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _drawAnimation;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _drawAnimation = CurvedAnimation(parent: _logoController, curve: Curves.easeInOut);
    
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        leading: FadeInLeft(
          duration: const Duration(milliseconds: 800),
          child: Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
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
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'The Gentleman Barberstyle',
            style: GoogleFonts.greatVibes(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
              color: const Color(0xFFD4AF37),
              shadows: [
                Shadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFD4AF37), // Luxury Gold
                  Colors.transparent,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        actions: [
          if (user != null && user.role.name != 'client')
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authServiceProvider).signOut();
              },
            )
          else if (user == null)
            TextButton(
              onPressed: () => context.push('/auth'),
              child: const Text('Login'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section with Luxury Design
            FadeIn(
              duration: const Duration(milliseconds: 500),
              child: Container(
                // Removed fixed height to prevent overflow
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0A0A0A),
                      Color(0xFF1A1A1A),
                      Color(0xFF0A0A0A),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative gold lines
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFFD4AF37),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Decorative top line
                            FadeInDown(
                              delay: const Duration(milliseconds: 200),
                              child: Container(
                                width: 80, // Reduced width
                                height: 1,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                            const SizedBox(height: 16), // Reduced spacing
                            
                            // Animated Logo
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Drawing Border
                                  AnimatedBuilder(
                                    animation: _drawAnimation,
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: HexagonPainter(
                                          progress: _drawAnimation.value,
                                          color: const Color(0xFFD4AF37),
                                        ),
                                        size: const Size(120, 120),
                                      );
                                    },
                                  ),
                                  
                                  // Central Icon
                                  FadeIn(
                                    delay: const Duration(milliseconds: 1000),
                                    duration: const Duration(milliseconds: 800),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/icon_premium.png', // Reverted to existing asset
                                          fit: BoxFit.cover,
                                          width: 80,
                                          height: 80,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Main title with shimmer
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: Shimmer.fromColors(
                                baseColor: Color(0xFFD4AF37),
                                highlightColor: Color(0xFFFFF8DC),
                                period: const Duration(milliseconds: 1500),
                                child: Text(
                                  'THE GENTLEMAN',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 8,
                                    color: Color(0xFFD4AF37),
                                    shadows: [
                                      Shadow(
                                        color: Color(0xFFB8860B),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Subtitle
                            FadeInUp(
                              delay: const Duration(milliseconds: 300),
                              child: Text(
                                'BARBERSTYLE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFFB8860B),
                                  letterSpacing: 12,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // CTA Button
                            BounceInUp(
                              delay: const Duration(milliseconds: 500),
                              child: _PremiumAnimatedButton(
                                onPressed: () => context.push('/booking'),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Decorative bottom line
                            FadeInUp(
                              delay: const Duration(milliseconds: 1000),
                              child: Container(
                                width: 100,
                                height: 1,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Image Carousel Section
            _buildImageCarousel(),

            // Services Section
            Container(
              color: Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
              child: Column(
                children: [
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        Text(
                          'I NOSTRI SERVIZI',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
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
                                Color(0xFFD4AF37),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Trattamenti Premium per il Gentleman Moderno',
                          style: TextStyle(
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
                  
                  // Service Cards Grid
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      FadeInLeft(
                        delay: const Duration(milliseconds: 300),
                        child: const _PremiumServiceCard(
                          icon: Icons.content_cut,
                          title: 'Taglio Capelli',
                          description: 'Taglio classico o moderno con lavaggio e styling professionale',
                          price: '25€',
                          duration: '30 min',
                        ),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: const _PremiumServiceCard(
                          icon: Icons.face,
                          title: 'Regolazione Barba',
                          description: 'Modellatura e rifinitura barba con panno caldo e oli essenziali',
                          price: '15€',
                          duration: '20 min',
                        ),
                      ),
                      FadeInRight(
                        delay: const Duration(milliseconds: 500),
                        child: const _PremiumServiceCard(
                          icon: Icons.auto_awesome,
                          title: 'Taglio + Barba',
                          description: 'Pacchetto completo per un look impeccabile e curato',
                          price: '35€',
                          duration: '50 min',
                          featured: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Premium Digital Business Card Section
            Container(
              color: Color(0xFF0A0A0A),
              padding: const EdgeInsets.all(24),
              child: FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1A1A1A),
                        Color(0xFF0A0A0A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Color(0xFFD4AF37).withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFD4AF37).withOpacity(0.1),
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
                              color: Color(0xFFD4AF37).withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Color(0xFFD4AF37)),
                                color: Color(0xFFD4AF37).withOpacity(0.1),
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.scissors,
                                color: Color(0xFFD4AF37),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'THE GENTLEMAN',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD4AF37),
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'BARBERSTYLE',
                                  style: TextStyle(
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
                                final uri = Uri.parse('https://maps.google.com/?q=Via+Borgo+Eniano+50+Montagnana+PD');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                                    style: TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _HoursRow(day: 'Lun - Gio', hours: '10:00-12:30 | 14:30-20:00'),
                                  const SizedBox(height: 8),
                                  _HoursRow(day: 'Venerdì', hours: '10:00-12:30 | 14:00-20:30'),
                                  const SizedBox(height: 8),
                                  _HoursRow(day: 'Sabato', hours: '09:00 - 20:00'),
                                  const SizedBox(height: 8),
                                  _HoursRow(day: 'Domenica', hours: '10:00 - 18:00'),
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
                                  url: 'https://www.instagram.com/the_gentlemen_barberstyle/',
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

  Widget _buildImageCarousel() {
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
                    color: const Color(0xFFD4AF37),
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
                        Color(0xFFD4AF37),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Esempi di Tagli e Acconciature',
                  style: TextStyle(
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
          CarouselSlider(
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
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.2),
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
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF1A1A1A),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Immagine non disponibile',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
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
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFFD4AF37).withOpacity(0.2),
                    boxShadow: _currentCarouselIndex == entry.key
                        ? [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.5),
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

  const _PremiumServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 240, // Increased height to prevent overflow
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: featured 
                ? const Color(0xFFD4AF37).withOpacity(0.2) 
                : Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient Border Container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: featured
                    ? [
                        const Color(0xFFD4AF37),
                        const Color(0xFFF7E7CE),
                        const Color(0xFFD4AF37),
                      ]
                    : [
                        const Color(0xFFD4AF37).withOpacity(0.5),
                        Colors.transparent,
                        const Color(0xFFD4AF37).withOpacity(0.2),
                      ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.5), // Border width
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1A1A),
                      const Color(0xFF0A0A0A),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(23),
                  child: Stack(
                    children: [
                      // Background Watermark Icon
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          icon,
                          size: 150,
                          color: const Color(0xFFD4AF37).withOpacity(0.03),
                        ),
                      ),
                      
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Header: Icon and Duration
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 24,
                                    color: const Color(0xFFD4AF37),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        duration,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Title and Description
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.toUpperCase(),
                                  style: GoogleFonts.cinzel(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD4AF37),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Footer: Price and "Book" hint
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PREZZO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: const Color(0xFFD4AF37).withOpacity(0.6),
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      price,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                if (featured)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFD4AF37),
                                          Color(0xFFB8860B),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37).withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'BEST SELLER',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        letterSpacing: 1,
                                      ),
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
              ),
            ),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color(0xFFD4AF37).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Color(0xFFD4AF37), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 14),
          ],
        ),
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String day;
  final String hours;
  final bool isClosed;

  const _HoursRow({
    required this.day,
    required this.hours,
    this.isClosed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          hours,
          style: TextStyle(
            color: isClosed ? Colors.red[300] : Colors.white,
            fontWeight: isClosed ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String url;

  const _SocialButton({required this.icon, required this.url});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFD4AF37).withOpacity(0.5)),
          shape: BoxShape.circle,
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Color(0xFFD4AF37).withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FaIcon(icon, color: Color(0xFFD4AF37), size: 20),
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

class _PremiumAnimatedButtonState extends State<_PremiumAnimatedButton> with TickerProviderStateMixin {
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
                  Color(0xFFB8860B), // Dark Gold
                  Color(0xFFF7E7CE), // Light Gold
                  Color(0xFFD4AF37), // Standard Gold
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.2 + (0.3 * _glowAnimation.value)),
                  blurRadius: 15 + (10 * _glowAnimation.value),
                  spreadRadius: 1 + (1 * _glowAnimation.value),
                  offset: const Offset(0, 0),
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
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFFD4AF37),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'PRENOTA ORA',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: const Color(0xFFD4AF37),
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
