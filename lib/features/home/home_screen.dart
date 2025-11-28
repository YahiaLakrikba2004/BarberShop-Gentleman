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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'The Gentleman Barberstyle',
            style: GoogleFonts.greatVibes(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
              color: const Color(0xFFFAFAFA),
              shadows: [
                Shadow(
                  color: const Color(0xFFFFFFFF).withOpacity(0.3),
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
                  Color(0xFFFFFFFF), // Luxury Gold
                  Colors.transparent,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        actions: [
          if (user == null)
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
                              Color(0xFFFFFFFF),
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
                                color: Color(0xFFFFFFFF),
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
                                          color: const Color(0xFFFFFFFF),
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
                                            color: const Color(0xFFFFFFFF).withOpacity(0.1),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'assets/images/icon_premium.png',
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
                                baseColor: const Color(0xFFFFFFFF),
                                highlightColor: const Color(0xFFE0E0E0), // Softer highlight
                                period: const Duration(milliseconds: 2500), // Slower shimmer
                                child: Text(
                                  'THE GENTLEMAN',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cinzel( // Changed to Cinzel
                                    fontSize: 42, // Slightly smaller to fit better
                                    fontWeight: FontWeight.w700, // Bold but elegant
                                    letterSpacing: 4, // Reduced spacing for cohesion
                                    color: const Color(0xFFFAFAFA),
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFFFFFFFF).withOpacity(0.5),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Subtitle
                            FadeInUp(
                              delay: const Duration(milliseconds: 300),
                              child: Text(
                                'BARBERSTYLE',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat( // Changed to Montserrat
                                  fontSize: 16,
                                  color: const Color(0xFFB0B0B0), // Silver/Grey
                                  letterSpacing: 8,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // CTA Button
                            BounceInUp(
                              delay: const Duration(milliseconds: 500),
                              child: _PremiumAnimatedButton(
                                onPressed: () => context.push('/booking'),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Decorative bottom line
                            FadeInUp(
                              delay: const Duration(milliseconds: 1000),
                              child: Container(
                                width: 60,
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFFFFFFFF).withOpacity(0.5),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
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
                          style: GoogleFonts.cinzel( // Consistent font
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
                          style: GoogleFonts.montserrat( // Consistent font
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: FadeInLeft(
                                delay: const Duration(milliseconds: 300),
                                child: const _PremiumServiceCard(
                                  icon: Icons.content_cut,
                                  title: 'Taglio Capelli',
                                  description: 'Taglio classico o moderno',
                                  price: '25€',
                                  duration: '30 min',
                                  compact: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FadeInUp(
                                delay: const Duration(milliseconds: 400),
                                child: const _PremiumServiceCard(
                                  icon: Icons.face,
                                  title: 'Regolazione Barba',
                                  description: 'Modellatura e rifinitura',
                                  price: '15€',
                                  duration: '20 min',
                                  compact: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                                border: Border.all(color: const Color(0xFFFFFFFF)),
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
                                    style: GoogleFonts.montserrat(
                                      color: const Color(0xFFFAFAFA),
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
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF1A1A1A),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_not_supported_outlined,
                                      color: const Color(0xFFFFFFFF).withOpacity(0.5),
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
    return Container(
      width: compact ? null : 320, // Flexible width if compact
      height: compact ? 200 : 240, // Reduced height for compact
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: featured 
                ? const Color(0xFFFFFFFF).withOpacity(0.2) 
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
                        const Color(0xFFFFFFFF),
                        const Color(0xFFE0E0E0),
                        const Color(0xFFBDBDBD),
                      ]
                    : [
                        const Color(0xFF424242),
                        const Color(0xFF212121),
                      ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.0), // Border width
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  color: const Color(0xFF1A1A1A),
                ),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.all(compact ? 8 : 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: const Color(0xFFFFFFFF),
                              size: compact ? 20 : 24,
                            ),
                          ),
                          if (featured)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'PREMIUM',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      
                      // Title
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.cinzel(
                          fontSize: compact ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFAFAFA),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        description,
                        style: GoogleFonts.montserrat(
                          fontSize: compact ? 10 : 12,
                          color: Colors.white60,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      
                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PREZZO',
                                style: GoogleFonts.montserrat(
                                  fontSize: compact ? 8 : 10,
                                  color: Colors.white38,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                price,
                                style: GoogleFonts.montserrat(
                                  fontSize: compact ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.white10,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'DURATA',
                                style: GoogleFonts.montserrat(
                                  fontSize: compact ? 8 : 10,
                                  color: Colors.white38,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                duration,
                                style: GoogleFonts.montserrat(
                                  fontSize: compact ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFFFFF),
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
                  Color(0xFFBDBDBD), // Dark Gold
                  Color(0xFFF5F5F5), // Light Gold
                  Color(0xFFFFFFFF), // Standard Gold
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFFFFF).withOpacity(0.2 + (0.3 * _glowAnimation.value)),
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
