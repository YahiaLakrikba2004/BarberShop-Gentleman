import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/ui/hexagon_painter.dart';
import '../../core/ui/particle_painter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _drawAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _loadingAnimation;

  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 1. Hexagon Drawing (0% - 40%)
    _drawAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
    );

    // 2. Icon Scale & Rotate (20% - 60%)
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _rotateAnimation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // 3. Text Fade In (50% - 80%)
    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
    );

    // 4. Loading Line (60% - 100%)
    _loadingAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    );

    _initParticles();
    _startSequence();
  }

  void _initParticles() {
    for (int i = 0; i < 50; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * 400, // Will be updated in build
        y: _random.nextDouble() * 800,
        size: _random.nextDouble() * 2 + 0.5,
        opacity: _random.nextDouble() * 0.5 + 0.1,
        speedX: (_random.nextDouble() - 0.5) * 0.5,
        speedY: -_random.nextDouble() * 1.0 - 0.2, // Float upwards
      ));
    }
  }

  void _updateParticles(Size size) {
    for (var particle in _particles) {
      particle.y += particle.speedY;
      particle.x += particle.speedX;
      
      if (particle.y < 0) {
        particle.y = size.height;
        particle.x = _random.nextDouble() * size.width;
      }
    }
  }

  Future<void> _startSequence() async {
    await _mainController.forward();
    HapticFeedback.lightImpact(); // Haptic feedback when sequence completes
    
    if (mounted) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background Gradient (Spotlight Effect)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Color(0xFF1A1A1A),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),
          
          // Particle System
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              _updateParticles(size);
              return CustomPaint(
                painter: ParticlePainter(
                  particles: _particles,
                  color: Color(0xFFD4AF37),
                ),
                size: size,
              );
            },
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo Composition
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hexagon Border
                      AnimatedBuilder(
                        animation: _drawAnimation,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: HexagonPainter(
                              progress: _drawAnimation.value,
                              color: const Color(0xFFD4AF37),
                            ),
                            size: const Size(180, 180),
                          );
                        },
                      ),
                      
                      // Icon
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Transform.rotate(
                              angle: _rotateAnimation.value * math.pi,
                              child: Container(
                                padding: const EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37).withOpacity(0.2 * _scaleAnimation.value),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.scissors,
                                  color: Color(0xFFD4AF37),
                                  size: 60,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // Text Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Shimmer.fromColors(
                        baseColor: const Color(0xFFD4AF37),
                        highlightColor: const Color(0xFFFFF8DC),
                        period: const Duration(seconds: 2),
                        child: const Text(
                          'GENTLEMAN',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'BARBER SHOP',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFFD4AF37).withOpacity(0.8),
                            letterSpacing: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Loading Line at Bottom
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _loadingAnimation,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 2,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: _loadingAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
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
        ],
      ),
    );
  }
}


