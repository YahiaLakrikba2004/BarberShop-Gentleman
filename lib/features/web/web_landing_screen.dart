import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../booking/booking_screen.dart';

class WebLandingScreen extends StatelessWidget {
  const WebLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Logo
                  FadeInDown(
                    duration: const Duration(milliseconds: 700),
                    child: Image.asset(
                      'assets/images/icon_premium_v2.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Title
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    duration: const Duration(milliseconds: 700),
                    child: Column(
                      children: [
                        Text(
                          'THE GENTLEMAN',
                          style: GoogleFonts.cinzel(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD4AF37),
                            letterSpacing: 5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'BARBERSHOP',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Colors.white38,
                            letterSpacing: 6,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Divider
                  FadeIn(
                    delay: const Duration(milliseconds: 400),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: const Color(0xFFD4AF37).withValues(alpha: 0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.content_cut, size: 14, color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                        ),
                        Expanded(child: Divider(color: const Color(0xFFD4AF37).withValues(alpha: 0.3))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Subtitle
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    duration: const Duration(milliseconds: 600),
                    child: Text(
                      'Prenota il tuo appuntamento\nin pochi secondi',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: Colors.white60,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // CTA Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 700),
                    duration: const Duration(milliseconds: 600),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BookingScreen(isWebMode: true),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'PRENOTA ORA',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Footer
                  FadeIn(
                    delay: const Duration(milliseconds: 900),
                    child: Text(
                      'Per cancellare chiama il negozio',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.white24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
