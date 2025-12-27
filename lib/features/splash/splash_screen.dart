import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slow, elegant 2s fade
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn, // Gentle entrance
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSequence();
    });
  }

  Future<void> _startSequence() async {
    // Slight pause before starting to let the eye settle on black
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    await _controller.forward();
    
    // Hold the established brand presence
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure Pitch Black
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO ---
              // Fixed size, no movement, no scale
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1), // Very subtle upscale detail
                    width: 1,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/icon_premium_v2.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // --- TITLE ---
              Text(
                'THE GENTLEMEN',
                style: GoogleFonts.cinzel(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4, // Static, confident spacing
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // --- SUBTITLE ---
              Text(
                'BARBERSTYLE',
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF888888), // Professional Grey
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
