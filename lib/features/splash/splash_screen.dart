import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  late AnimationController _pulseController;
  late Animation<double> _drawAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _pulseAnimation;

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

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
    _pulseController.dispose();
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
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Color(0xFF222222), // Slightly lighter center for spotlight
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
                  color: const Color(0xFFFFFFFF), // White particles
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
                              color: const Color(0xFFFFFFFF), // White Hexagon
                            ),
                            size: const Size(180, 180),
                          );
                        },
                      ),
                      
                      // Icon with Pulse
                      AnimatedBuilder(
                        animation: Listenable.merge([_mainController, _pulseController]),
                        builder: (context, child) {
                          // Only pulse when scale is near 1.0 (fully visible)
                          final pulseScale = _scaleAnimation.value > 0.9 ? _pulseAnimation.value : 1.0;
                          
                          return Transform.scale(
                            scale: _scaleAnimation.value * pulseScale,
                            child: Transform.rotate(
                              angle: _rotateAnimation.value * math.pi,
                              child: Container(
                                padding: const EdgeInsets.all(25),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFFFFF).withOpacity(0.2 * _scaleAnimation.value),
                                      blurRadius: 30 * pulseScale,
                                      spreadRadius: 5 * pulseScale,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFFFFFFFF).withOpacity(0.5),
                                    width: 1,
                                  ),
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
                        baseColor: const Color(0xFFFFFFFF),
                        highlightColor: const Color(0xFFF5F5F5),
                        period: const Duration(seconds: 2),
                        child: const Text(
                          'THE GENTLEMAN',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Refined Subtitle with Decorative Lines
                      SizedBox(
                        width: 250,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFFFFFFFF).withOpacity(0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: const Text(
                                'BARBER STYLE',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFFFFFFF),
                                  letterSpacing: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
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
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFFFFF).withOpacity(0.5),
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
