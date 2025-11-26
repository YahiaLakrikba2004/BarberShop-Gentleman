import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:carousel_slider/carousel_slider.dart' hide CarouselController;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        title: const Text('GENTLEMAN BARBER SHOP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Carica Dati Demo',
            onPressed: () async {
              await ref.read(seedServiceProvider).seedData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Dati demo caricati con successo!'),
                    backgroundColor: const Color(0xFFD4AF37),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.instagram),
            tooltip: 'Instagram',
            onPressed: () async {
              final uri = Uri.parse('https://www.instagram.com/the_gentlemen_barberstyle/');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          // Profile/Logout logic moved to Bottom Navigation for Clients
          // For Barbers/Admins, we might still want a logout button here since they don't have a profile tab
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
                height: 450,
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
                                width: 100,
                                height: 1,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
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
                                      padding: const EdgeInsets.all(15),
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
                                      child: const FaIcon(
                                        FontAwesomeIcons.scissors,
                                        color: Color(0xFFD4AF37),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Main title with shimmer
                            FadeInUp(
                              delay: const Duration(milliseconds: 200),
                              child: Shimmer.fromColors(
                                baseColor: Color(0xFFD4AF37),
                                highlightColor: Color(0xFFFFF8DC),
                                period: const Duration(milliseconds: 1500),
                                child: Text(
                                  'GENTLEMAN',
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
                                'BARBER SHOP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Color(0xFFB8860B),
                                  letterSpacing: 12,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            

                            
                            // CTA Button
                            BounceInUp(
                              delay: const Duration(milliseconds: 500),
                              child: Container(
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFD4AF37).withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: FilledButton.icon(
                                  onPressed: () => context.push('/booking'),
                                  icon: const Icon(Icons.calendar_today, size: 20),
                                  label: const Text('PRENOTA ORA'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 48,
                                      vertical: 20,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ),
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
                        child: _PremiumServiceCard(
                          icon: Icons.content_cut,
                          title: 'Taglio Capelli',
                          description: 'Taglio classico o moderno con lavaggio e styling professionale',
                          price: '25€',
                          duration: '30 min',
                        ),
                      ),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: _PremiumServiceCard(
                          icon: Icons.face,
                          title: 'Regolazione Barba',
                          description: 'Modellatura e rifinitura barba con panno caldo e oli essenziali',
                          price: '15€',
                          duration: '20 min',
                        ),
                      ),
                      FadeInRight(
                        delay: const Duration(milliseconds: 500),
                        child: _PremiumServiceCard(
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
                                  'GENTLEMAN',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD4AF37),
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'BARBER SHOP',
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
                              title: 'Via della Barberia, 123',
                              subtitle: 'Centro Città, Roma',
                              onTap: () async {
                                final uri = Uri.parse('https://maps.google.com/?q=Via+della+Barberia+123+Roma');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Phone
                            _ContactRow(
                              icon: Icons.phone,
                              title: '+39 333 123 4567',
                              subtitle: 'Chiamaci per info',
                              onTap: () async {
                                final uri = Uri.parse('tel:+393331234567');
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
                                  _HoursRow(day: 'Lun - Ven', hours: '09:00 - 20:00'),
                                  const SizedBox(height: 8),
                                  _HoursRow(day: 'Sabato', hours: '09:00 - 18:00'),
                                  const SizedBox(height: 8),
                                  _HoursRow(day: 'Domenica', hours: 'Chiuso', isClosed: true),
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
                        color: Color(0xFFD4AF37).withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFD4AF37).withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
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
      decoration: BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border.all(
          color: featured ? Color(0xFFD4AF37) : Color(0xFFD4AF37).withOpacity(0.3),
          width: featured ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: featured
            ? [
                BoxShadow(
                  color: Color(0xFFD4AF37).withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          if (featured)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'POPOLARE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A0A0A),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Color(0xFFD4AF37).withOpacity(0.1),
                    border: Border.all(color: Color(0xFFD4AF37), width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Divider(color: Color(0xFFD4AF37).withOpacity(0.2), height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prezzo',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white60,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        border: Border.all(color: Color(0xFFD4AF37).withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 13, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 5),
                          Text(
                            duration,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return ZoomIn(
      delay: Duration(milliseconds: delay),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF0A0A0A),
          border: Border.all(color: Color(0xFFD4AF37).withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: Color(0xFFD4AF37),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFD4AF37),
                letterSpacing: 1,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white60,
                letterSpacing: 0.5,
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
