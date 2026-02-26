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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
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

            // --- CORNER BRACKET ORNAMENTS ---
            ..._buildCornerBrackets(size),

            // --- MAIN CONTENT ---
            AnimatedBuilder(
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
                  children: [
                    // Top spacer — positions logo at ~38% from top
                    SizedBox(height: size.height * 0.22),

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

                    const SizedBox(height: 40),

                    // --- DECORATIVE TOP RULE ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _thinLine(),
                        const SizedBox(width: 12),
                        Text(
                          '✦',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _thinLine(),
                      ],
                    ),

                    const SizedBox(height: 22),

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
          ],
        ),
      ),
    );
  }

  Widget _thinLine() {
    return Container(
      width: 48,
      height: 0.5,
      color: Colors.white.withOpacity(0.25),
    );
  }

  List<Widget> _buildCornerBrackets(Size size) {
    const double margin = 28;
    const double length = 22;
    const double thickness = 1.0;
    final color = Colors.white.withOpacity(0.14);

    Widget bracket({
      required double top,
      required double left,
      required double? right,
      required double? bottom,
      required bool flipH,
      required bool flipV,
    }) {
      return Positioned(
        top: top,
        left: left == -1 ? null : left,
        right: right,
        bottom: bottom,
        child: SizedBox(
          width: length,
          height: length,
          child: CustomPaint(
            painter: _CornerPainter(
              color: color,
              thickness: thickness,
              flipH: flipH,
              flipV: flipV,
            ),
          ),
        ),
      );
    }

    return [
      bracket(top: margin, left: margin, right: null, bottom: null, flipH: false, flipV: false),
      bracket(top: margin, left: -1, right: margin, bottom: null, flipH: true, flipV: false),
      bracket(top: -1, left: margin, right: null, bottom: margin, flipH: false, flipV: true),
      bracket(top: -1, left: -1, right: margin, bottom: margin, flipH: true, flipV: true),
    ];
  }
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

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool flipH;
  final bool flipV;

  const _CornerPainter({
    required this.color,
    required this.thickness,
    required this.flipH,
    required this.flipV,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final double x = flipH ? size.width : 0;
    final double y = flipV ? size.height : 0;
    final double hx = flipH ? -size.width : size.width;
    final double vy = flipV ? -size.height : size.height;

    // Horizontal arm
    canvas.drawLine(Offset(x, y), Offset(x + hx, y), paint);
    // Vertical arm
    canvas.drawLine(Offset(x, y), Offset(x, y + vy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
