import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../config/admin_config.dart';

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
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return Scaffold(
        body: Column(
          children: [
            _DesktopTopNav(
              currentIndex: widget.currentIndex,
              user: user,
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Stack(
        children: [
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        if (user != null && user.role != UserRole.client)
                          _buildNavItem(
                            index: 2,
                            icon: Icons.event_note_outlined,
                            selectedIcon: Icons.event_note,
                            label: 'Agenda',
                            onTap: () {
                              context.go('/team-agenda');
                            },
                          ),
                        if (user == null || user.role == UserRole.client)
                          _buildNavItem(
                            index: 2,
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
            ),
          ),
        ],
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
    const goldColor = Color(0xFFD4AF37); // Classic Gold

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
                        color: goldColor.withValues(alpha: 0.3),
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
          
          const SizedBox(height: 4),
          Visibility(
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            visible: isSelected,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: goldColor,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTopNav extends ConsumerWidget {
  final int currentIndex;
  final dynamic user;

  const _DesktopTopNav({required this.currentIndex, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const goldColor = Color(0xFFD4AF37);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                // Logo + brand
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: goldColor.withValues(alpha: 0.6), width: 1),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/icon_premium_v2.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'THE GENTLEMEN',
                      style: GoogleFonts.cinzel(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Nav items
                _desktopNavItem(context, index: 0, icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', onTap: () => context.go('/'), currentIndex: currentIndex),
                const SizedBox(width: 8),
                _desktopNavItem(context, index: 1, icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, label: 'Prenota', onTap: () => context.go('/booking'), currentIndex: currentIndex),
                if (user != null && user.role != UserRole.client) ...[
                  const SizedBox(width: 8),
                  _desktopNavItem(
                    context,
                    index: 2,
                    icon: Icons.event_note_outlined,
                    selectedIcon: Icons.event_note,
                    label: 'Agenda',
                    onTap: () {
                      if (AdminConfig.isShopAccount(user.email)) {
                        context.go('/team-agenda');
                      } else {
                        context.go('/calendar');
                      }
                    },
                    currentIndex: currentIndex,
                  ),
                ],
                if (user == null || user.role == UserRole.client) ...[
                  const SizedBox(width: 8),
                  _desktopNavItem(context, index: 2, icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profilo', onTap: () => context.go('/profile'), currentIndex: currentIndex),
                ],
                if (user?.role == UserRole.barber) ...[
                  const SizedBox(width: 8),
                  _desktopNavItem(context, index: 3, icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profilo', onTap: () => context.go('/profile'), currentIndex: currentIndex),
                ],
                if (user?.role == UserRole.admin) ...[
                  const SizedBox(width: 8),
                  _desktopNavItem(context, index: 3, icon: Icons.admin_panel_settings_outlined, selectedIcon: Icons.admin_panel_settings, label: 'Admin', onTap: () => context.go('/admin'), currentIndex: currentIndex),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required VoidCallback onTap,
    required int currentIndex,
  }) {
    const goldColor = Color(0xFFD4AF37);
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? goldColor.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? goldColor.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? goldColor : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? goldColor : Colors.white54,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
