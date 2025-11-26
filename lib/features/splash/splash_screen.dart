import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/ui/hexagon_painter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _drawController;
  late AnimationController _iconController;
  late AnimationController _textController;
  
  late Animation<double> _drawAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // 1. Line Drawing Animation (Border)
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _drawAnimation = CurvedAnimation(parent: _drawController, curve: Curves.easeInOut);

    // 2. Icon Scale Animation
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconScaleAnimation = CurvedAnimation(parent: _iconController, curve: Curves.elasticOut);

    // 3. Text Animation
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textFadeAnimation = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _textSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _drawController.forward();
    await _iconController.forward();
    await _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
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
    _drawController.dispose();
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo Container
            SizedBox(
              width: 160,
              height: 160,
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
                        size: const Size(160, 160),
                      );
                    },
                  ),
                  
                  // Central Icon
                  ScaleTransition(
                    scale: _iconScaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
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
                        size: 50,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Text Animations
            FadeTransition(
              opacity: _textFadeAnimation,
              child: SlideTransition(
                position: _textSlideAnimation,
                child: Column(
                  children: [
                    Shimmer.fromColors(
                      baseColor: const Color(0xFFD4AF37),
                      highlightColor: const Color(0xFFF7E7CE),
                      period: const Duration(seconds: 3),
                      child: const Text(
                        'GENTLEMAN',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'BARBER SHOP',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 8,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


