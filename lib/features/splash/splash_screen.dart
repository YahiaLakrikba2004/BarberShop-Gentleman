import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _mainController;
  late Animation<double> _mainFade;
  late Animation<double> _mainScale;

  late AnimationController _fadeOutController;
  late Animation<double> _screenOpacity;

  // Rotating arc around logo
  late AnimationController _ringController;
 
  // Ambient dust/particles
  late AnimationController _particleController;
 
  // Pulsing glow on logo
  late AnimationController _glowController;
  late Animation<double> _glowRadius;

  @override
  void initState() {
    super.initState();

    // Main scene: fade in + imperceptible scale-down (1.03 → 1.0)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _mainFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _mainScale = Tween<double>(begin: 1.03, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOut),
    );

    // Fade out
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _screenOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );

    // Rotating arc — very slow continuous rotation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Pulsing glow — breathes in and out
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _glowRadius = Tween<double>(begin: 28.0, end: 52.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
 
    // Particles movement
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _runSequence());
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    await _mainController.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    await _fadeOutController.forward();
    if (!mounted) return;

    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _fadeOutController.dispose();
    _ringController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _fadeOutController,
          builder: (context, child) => Opacity(
            opacity: _screenOpacity.value,
            child: child,
          ),
          child: Stack(
            children: [
              // --- RADIAL GRADIENT BACKGROUND ---
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        Color(0xFF1C1C1C), // near-black warm center
                        Color(0xFF000000), // pure black edges
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),
  
              // --- ATMOSPHERIC PARTICLES ---
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, _) => CustomPaint(
                    painter: _ParticlePainter(
                      progress: _particleController.value,
                    ),
                  ),
                ),
              ),
  
              // --- MAIN CONTENT ---
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) => FadeTransition(
                    opacity: _mainFade,
                    child: ScaleTransition(
                      scale: _mainScale,
                      child: child,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    // Top spacer — Increased for Dynamic Island safety (~28% from top)
                    SizedBox(height: size.height * 0.28),

                    // --- LOGO with pulsing glow + rotating arc ---
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating arc
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _ringController,
                              builder: (context, _) => CustomPaint(
                                painter: _ArcPainter(
                                  progress: _ringController.value,
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                            ),
                          ),
                          // Logo with pulsing glow
                          AnimatedBuilder(
                            animation: _glowController,
                            builder: (context, child) => Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.10),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.07),
                                    blurRadius: _glowRadius.value,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/icon_premium_v2.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),
 
                    // --- TITLE ---
                    Text(
                      'THE GENTLEMEN',
                      style: GoogleFonts.cinzel(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 5,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // --- SUBTITLE ---
                    Text(
                      'BARBERSTYLE',
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 7,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const Spacer(),

                    // --- EST. TAGLINE at bottom ---
                    Text(
                      'EST. MMXXVI',
                      style: GoogleFonts.cinzel(
                        color: Colors.white.withOpacity(0.18),
                        fontSize: 9,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
 
  _ParticlePainter({required this.progress});
 
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
 
    for (int i = 0; i < 30; i++) {
      // Deterministic "pseudorandom" based on index
      double xBase = ((i * 13.7) % 1.0) * size.width;
      double yBase = ((i * 7.3) % 1.0) * size.height;
      
      // Floating movement upwards and slightly sideways
      double x = xBase + (size.width * 0.1 * (progress + (i / 30.0) % 1.0));
      double y = yBase - (size.height * 0.2 * (progress + (i / 30.0) % 1.0));
 
      // Loop y and x coordinates within bounds
      if (y < 0) y += size.height;
      if (x > size.width) x -= size.width;
 
      double pSize = (i % 3) + 0.6;
      double pOpacity = 0.04 + (0.08 * ((i % 5) / 5.0));
 
      canvas.drawCircle(
        Offset(x, y), 
        pSize, 
        paint..color = Colors.white.withOpacity(pOpacity),
      );
    }
  }
 
  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
 
class _Particle {
  // Logic placeholder if needed for more complex particles
}

class _ArcPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 full rotation
  final Color color;

  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Arc spans ~240°, leaving a 120° gap
    const double arcSweep = 4.19; // ~240° in radians
    final double startAngle = progress * 6.283; // full rotation offset

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + arcSweep,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.22),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      arcSweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}
