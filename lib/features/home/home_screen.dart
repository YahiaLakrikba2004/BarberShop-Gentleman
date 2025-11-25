import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/auth_service.dart';
import '../../services/seed_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                ref.read(authServiceProvider).signOut();
              },
            )
          else
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
                            
                            // Icon with glow effect
                            SlideInDown(
                              duration: const Duration(milliseconds: 400),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color(0xFFD4AF37),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFD4AF37).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.content_cut,
                                  size: 60,
                                  color: Color(0xFFD4AF37),
                                ),
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

            // Info Section
            Container(
              color: Color(0xFF0A0A0A),
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  FadeInLeft(
                    delay: const Duration(milliseconds: 200),
                    child: _LuxuryInfoCard(
                      icon: Icons.access_time,
                      title: 'Orari di Apertura',
                      content: 'Lun-Sab: 9:00 - 20:00\nDomenica: Chiuso',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInRight(
                    delay: const Duration(milliseconds: 400),
                    child: _LuxuryInfoCard(
                      icon: Icons.location_on,
                      title: 'Dove Siamo',
                      content: 'Via della Barberia, 123\nCentro Città',
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInLeft(
                    delay: const Duration(milliseconds: 600),
                    child: _LuxuryInfoCard(
                      icon: Icons.phone,
                      title: 'Contatti',
                      content: '+39 123 456 7890\ninfo@gentleman.it',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

class _LuxuryInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _LuxuryInfoCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border.all(
          color: Color(0xFFD4AF37).withOpacity(0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFD4AF37).withOpacity(0.1),
              border: Border.all(color: Color(0xFFD4AF37), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 32,
              color: Color(0xFFD4AF37),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD4AF37),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
