import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              ZoomIn(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFFD4AF37),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFD4AF37).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.content_cut,
                    size: 80,
                    color: Color(0xFFD4AF37),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Animated Title
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Shimmer.fromColors(
                  baseColor: Color(0xFFD4AF37),
                  highlightColor: Color(0xFFFFF8DC),
                  period: const Duration(seconds: 2),
                  child: Text(
                    'GENTLEMAN',
                    style: TextStyle(
                      fontSize: 42,
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
                delay: const Duration(milliseconds: 600),
                child: Text(
                  'BARBER SHOP',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFFB8860B),
                    letterSpacing: 8,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Loading Indicator
              FadeIn(
                delay: const Duration(milliseconds: 1000),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFD4AF37),
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
