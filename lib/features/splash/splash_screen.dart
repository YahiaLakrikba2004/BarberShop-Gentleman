import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  
  // Animation Phases
  late Animation<double> _lineDrawAnimation;
  late Animation<double> _lineSplitAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textSpacingAnimation;

  final List<AmbientParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initParticles();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Faster animation
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _lineDrawAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.25, curve: Curves.easeInOut),
      ),
    );

    _lineSplitAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.35, 0.5, curve: Curves.easeIn),
      ),
    );

    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.8, curve: Curves.easeIn),
      ),
    );

    _textSpacingAnimation = Tween<double>(begin: 2.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );

    // CRITICAL FIX: Do not rely on Future.delayed in initState.
    // Wait for the first frame to be rendered, THEN start the timer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSequence();
    });
  }
  // ...
  void _initParticles() {
    // Reduced particle count for performance (Tablet Optimization)
    for (int i = 0; i < 15; i++) {
      _particles.add(AmbientParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2.0 + 0.5,
        speedX: (_random.nextDouble() - 0.5) * 0.03, // Slower movement
        speedY: (_random.nextDouble() - 0.5) * 0.03,
        opacity: _random.nextDouble() * 0.4 + 0.1,
      ));
    }
  }

  Future<void> _startSequence() async {
    // Double safety: Wait a moment for any heavy initialization (Firebase) to settle
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;

    // Reset just in case
    _mainController.reset();
    await _mainController.forward();
    
    if (mounted) {
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // OPTIMIZATION: Decode image before animation starts to prevent jank
    precacheImage(const AssetImage('assets/images/icon_premium.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    // OPTIMIZATION: Create Shader once
    final Shader goldGradient = const LinearGradient(
      colors: <Color>[
        Color(0xFFBF953F), // Dark Gold
        Color(0xFFFCF6BA), // Light Gold
        Color(0xFFB38728), // Dark Gold
        Color(0xFFFBF5B7), // Light Gold
        Color(0xFFAA771C), // Dark Gold
      ],
      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Static Background (Cheap)
          const DecoratedBox(
             decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.6,
                colors: [
                  Color(0xFF151515), 
                  Colors.black,      
                ],
              ),
            ),
            child: SizedBox.expand(),
          ),
          
          // 2. Particles
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: AmbientParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // 3. Main Content
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Line
                    RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(200, 300),
                        painter: GlowingLinePainter(
                          drawProgress: _lineDrawAnimation.value,
                          splitProgress: _lineSplitAnimation.value,
                        ),
                      ),
                    ),

                    // Logo
                    Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Container(
                           decoration: const BoxDecoration( // Made const
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x1AFFFFFF), 
                                blurRadius: 20, 
                                spreadRadius: 5,
                              )
                            ]
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.asset(
                              'assets/images/icon_premium.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Text
                    Positioned(
                      top: MediaQuery.of(context).size.height / 2 + 80,
                      child: Opacity(
                        opacity: _textOpacityAnimation.value,
                        child: Column(
                          children: [
                            // OPTIMIZATION: Replaced ShaderMask (expensive saveLayer) with TextStyle foreground (cheap)
                            Text(
                              'THE GENTLEMAN',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: _textSpacingAnimation.value,
                                foreground: Paint()..shader = goldGradient, // Direct Shader
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'BARBER STUDIO',
                              style: GoogleFonts.lato(
                                color: const Color(0xFF666666), 
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- OPTIMIZED PAINTERS ---

class GlowingLinePainter extends CustomPainter {
  final double drawProgress;
  final double splitProgress;

  GlowingLinePainter({required this.drawProgress, required this.splitProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (drawProgress == 0) return;

    final Paint linePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.height/2 - 100),
        Offset(0, size.height/2 + 100),
        [
          Colors.transparent,
          const Color(0xFFD4AF37), // Gold
          Colors.white,            // Hot center
          const Color(0xFFD4AF37), // Gold
          Colors.transparent,
        ],
        [0.0, 0.2, 0.5, 0.8, 1.0],
      )
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // OPTIMIZATION: Fake Glow using a wider transparent stroke instead of MaskFilter.blur
    final Paint glowPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.2 * (1 - splitProgress))
      ..strokeWidth = 8.0 // Wide loose stroke to simulate glow
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final maxLineHeight = 160.0;

    // Draw Line
    if (splitProgress == 0) {
      final currentHeight = maxLineHeight * drawProgress;
      final start = Offset(center.dx, center.dy - currentHeight / 2);
      final end = Offset(center.dx, center.dy + currentHeight / 2);
      
      canvas.drawLine(start, end, glowPaint); // Fake Glow
      canvas.drawLine(start, end, linePaint);
    } else {
      // Split
      final offset = 120.0 * splitProgress;
      final opacity = (1.0 - splitProgress).clamp(0.0, 1.0);
      
      linePaint.color = linePaint.color.withOpacity(opacity);
      glowPaint.color = glowPaint.color.withOpacity(opacity * 0.2); // Fade glow faster
      
      if (opacity > 0.05) {
          // Top Split
          canvas.drawLine(
            Offset(center.dx, center.dy - maxLineHeight/2 - offset),
            Offset(center.dx, center.dy - offset),
            linePaint,
          );
          // Bottom Split
          canvas.drawLine(
            Offset(center.dx, center.dy + offset),
            Offset(center.dx, center.dy + maxLineHeight/2 + offset),
            linePaint,
          );
      }
    }
  }

  @override
  bool shouldRepaint(covariant GlowingLinePainter oldDelegate) {
     return oldDelegate.drawProgress != drawProgress || 
            oldDelegate.splitProgress != splitProgress;
  }
}

class AmbientParticle {
  double x;
  double y;
  double size;
  double speedX;
  double speedY;
  double opacity;

  AmbientParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });
}

class AmbientParticlePainter extends CustomPainter {
  final List<AmbientParticle> particles;
  final double progress; 

  AmbientParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Optimization: Draw circles with simple Paint (no shaders)
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      p.x += p.speedX * 0.01;
      p.y += p.speedY * 0.01;

      if (p.x < 0) p.x = 1.0;
      if (p.x > 1) p.x = 0.0;
      if (p.y < 0) p.y = 1.0;
      if (p.y > 1) p.y = 0.0;

      paint.color = const Color(0xFFD4AF37).withOpacity(p.opacity * 0.3);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AmbientParticlePainter oldDelegate) {
    return true; 
  }
}
