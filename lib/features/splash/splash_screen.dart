import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _kGold = Color(0xFFD4A853);

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Phase 1 — fade in tutto
  late AnimationController _fadeInCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  // Phase 2 — testo esce, logo si ingrandisce
  late AnimationController _transitionCtrl;
  late Animation<double> _textFade;
  late Animation<double> _logoGrow;

  // Phase 3 — arco oro si riempie, loading text entra
  late AnimationController _goldArcCtrl;
  late AnimationController _loadingTextCtrl;
  late Animation<double> _loadingTextFade;

  // Uscita
  late AnimationController _exitCtrl;
  late Animation<double> _exitOpacity;

  // Effetti ambientali (continui)
  late AnimationController _particleCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _glowRadius;

  @override
  void initState() {
    super.initState();

    _fadeInCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeIn = CurvedAnimation(parent: _fadeInCtrl, curve: const Interval(0.0, 0.75, curve: Curves.easeOut));
    _scaleIn = Tween<double>(begin: 1.04, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeInCtrl, curve: Curves.easeOut));

    _transitionCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textFade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeIn));
    _logoGrow = Tween<double>(begin: 1.0, end: 1.09)
        .animate(CurvedAnimation(parent: _transitionCtrl, curve: Curves.easeOut));

    _goldArcCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _loadingTextCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _loadingTextFade = CurvedAnimation(parent: _loadingTextCtrl, curve: Curves.easeIn);

    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _glowRadius = Tween<double>(begin: 26.0, end: 50.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _runSequence());
  }

  Future<void> _runSequence() async {
    // Fase 1: fade in
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    await _fadeInCtrl.forward();

    // Display statico lussuoso
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;

    // Fase 2: testo esce, logo cresce
    await _transitionCtrl.forward();
    if (!mounted) return;

    // Fase 3: arco oro + loading text
    _loadingTextCtrl.forward();
    await _goldArcCtrl.forward();
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    // Uscita
    await _exitCtrl.forward();
    if (!mounted) return;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _fadeInCtrl.dispose();
    _transitionCtrl.dispose();
    _goldArcCtrl.dispose();
    _loadingTextCtrl.dispose();
    _exitCtrl.dispose();
    _particleCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _exitCtrl,
          builder: (context, child) => Opacity(
            opacity: _exitOpacity.value,
            child: child,
          ),
          child: Stack(
            children: [
              // Sfondo radiale
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [Color(0xFF1C1C1C), Color(0xFF000000)],
                    ),
                  ),
                ),
              ),

              // Particelle ambientali
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _particleCtrl,
                  builder: (context, _) => CustomPaint(
                    painter: _ParticlePainter(progress: _particleCtrl.value),
                  ),
                ),
              ),

              // Contenuto principale
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _fadeInCtrl,
                  builder: (context, child) => FadeTransition(
                    opacity: _fadeIn,
                    child: ScaleTransition(scale: _scaleIn, child: child),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: size.height * 0.28),

                        // Logo con arco oro
                        AnimatedBuilder(
                          animation: Listenable.merge([_glowCtrl, _goldArcCtrl, _transitionCtrl]),
                          builder: (context, child) => ScaleTransition(
                            scale: _logoGrow,
                            child: SizedBox(
                              width: 130,
                              height: 130,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Arco oro (si riempie in Phase 3)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _GoldArcFillPainter(
                                        progress: _goldArcCtrl.value,
                                      ),
                                    ),
                                  ),
                                  // Logo con glow
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.10),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.07),
                                          blurRadius: _glowRadius.value,
                                          spreadRadius: 4,
                                        ),
                                      ],
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
                          ),
                        ),

                        const SizedBox(height: 52),

                        // Area testo: Phase 1 esce, Phase 3 loading text entra — stessa area
                        SizedBox(
                          height: 72,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              // Testo principale (esce in Phase 2)
                              AnimatedBuilder(
                                animation: _transitionCtrl,
                                builder: (context, child) => Opacity(
                                  opacity: _textFade.value,
                                  child: child,
                                ),
                                child: Column(
                                  children: [
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
                                    const SizedBox(height: 9),
                                    Text(
                                      'BARBERSTYLE',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white.withValues(alpha: 0.50),
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 7,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    // Linea argentata sottile
                                    Container(
                                      width: 56,
                                      height: 0.5,
                                      color: Colors.white.withValues(alpha: 0.22),
                                    ),
                                  ],
                                ),
                              ),

                              // Loading text (entra in Phase 3)
                              Positioned(
                                bottom: 0,
                                child: AnimatedBuilder(
                                  animation: _loadingTextFade,
                                  builder: (context, _) => Opacity(
                                    opacity: _loadingTextFade.value,
                                    child: Text(
                                      'IN ATTESA DEI MIGLIORI BARBIERI',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white.withValues(alpha: 0.28),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w300,
                                        letterSpacing: 2.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // EST. in oro
                        Text(
                          'EST. MMXXVI',
                          style: GoogleFonts.cinzel(
                            color: _kGold.withValues(alpha: 0.55),
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

// Arco oro che si riempie progressivamente
class _GoldArcFillPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0

  const _GoldArcFillPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const startAngle = -pi / 2; // parte dall'alto

    // Track di sfondo (appena percettibile)
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    if (progress <= 0) return;

    final sweep = progress * 2 * pi;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweep,
        colors: [
          _kGold.withValues(alpha: 0.5),
          _kGold,
          const Color(0xFFF5D17A),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GoldArcFillPainter old) => old.progress != progress;
}

// Particelle ambientali — movimento verticale con lieve ondeggiamento
class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 32; i++) {
      // Posizione base distribuita su tutto lo schermo
      final xBase = ((i * 17.3) % 1.0) * size.width;
      final yBase = ((i * 11.7) % 1.0) * size.height;

      // Movimento: sale lentamente con oscillazione orizzontale minima
      final phase = (progress + i / 32.0) % 1.0;
      final x = xBase + size.width * 0.015 * sin(phase * 2 * pi + i);
      final y = (yBase - size.height * 0.18 * phase + size.height) % size.height;

      final pSize = 0.7 + (i % 3) * 0.5;
      final pOpacity = 0.03 + 0.06 * ((i % 5) / 5.0);

      canvas.drawCircle(
        Offset(x, y),
        pSize,
        paint..color = Colors.white.withValues(alpha: pOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.progress != progress;
}
