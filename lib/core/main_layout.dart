import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border(
            top: BorderSide(
              color: const Color(0xFFFFFFFF).withOpacity(0.3),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFFFFF).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home,
                  label: 'Home',
                  onTap: () => context.go('/'),
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today,
                  label: 'Prenota',
                  onTap: () => context.go('/booking'),
                ),
                // Only show Agenda for Staff (Barbers/Admins), NOT for null (loading/guest)
                if (user != null && user.role != UserRole.client)
                  _buildNavItem(
                    index: 2,
                    icon: Icons.event_note_outlined,
                    selectedIcon: Icons.event_note,
                    label: 'Agenda',
                    onTap: () => context.go('/calendar'),
                  ),
                
                // Show Profile for Clients OR if user is null (to allow logout/fixing)
                if (user == null || user.role == UserRole.client)
                  _buildNavItem(
                    index: 2, // Keep index 2 for Client layout
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profilo',
                    onTap: () => context.go('/profile'),
                  ),

                if (user?.role == UserRole.barber)
                  _buildNavItem(
                    index: 3,
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profilo',
                    onTap: () => context.go('/profile'),
                  ),
                if (user?.role == UserRole.admin)
                  _buildNavItem(
                    index: 3,
                    icon: Icons.admin_panel_settings_outlined,
                    selectedIcon: Icons.admin_panel_settings,
                    label: 'Admin',
                    onTap: () => context.go('/admin'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = widget.currentIndex == index;
    final goldColor = const Color(0xFFD4AF37); // Classic Gold

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Icon Container
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // No background - just pure icon
              color: Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: goldColor.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: -2,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? goldColor : Colors.white24, // High contrast
              size: 26,
            ),
          ),
          
          if (isSelected) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.montserrat( // Elegant font
                color: goldColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ] else ...[
             // Placeholder to prevent jumpy layout, or just remove if we want it compact.
             // Keeping it compact for unselected.
             const SizedBox(height: 4),
             const SizedBox(height: 12), // Height of text approx
          ],
        ],
      ),
    );
  }
}
