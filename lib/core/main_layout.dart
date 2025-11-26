import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          border: Border(
            top: BorderSide(
              color: Color(0xFFD4AF37).withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Color(0xFF0A0A0A),
          selectedIndex: widget.currentIndex,
          indicatorColor: Color(0xFFD4AF37).withOpacity(0.2),
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/');
                break;
              case 1:
                context.go('/booking');
                break;
              case 2:
                if (user?.role.name == 'client') {
                  context.go('/profile');
                } else {
                  context.go('/calendar');
                }
                break;
              case 3:
                if (user?.role.name == 'admin') {
                  context.go('/admin');
                }
                break;
            }
          },
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: widget.currentIndex == 0 ? Color(0xFFD4AF37) : Colors.white60,
              ),
              selectedIcon: Icon(Icons.home, color: Color(0xFFD4AF37)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.calendar_today_outlined,
                color: widget.currentIndex == 1 ? Color(0xFFD4AF37) : Colors.white60,
              ),
              selectedIcon: Icon(Icons.calendar_today, color: Color(0xFFD4AF37)),
              label: 'Prenota',
            ),
            // Third Tab: Profile for Clients, Calendar for Staff
            if (user?.role.name == 'client')
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  color: widget.currentIndex == 2 ? Color(0xFFD4AF37) : Colors.white60,
                ),
                selectedIcon: Icon(Icons.person, color: Color(0xFFD4AF37)),
                label: 'Profilo',
              )
            else
              NavigationDestination(
                icon: Icon(
                  Icons.event_note_outlined,
                  color: widget.currentIndex == 2 ? Color(0xFFD4AF37) : Colors.white60,
                ),
                selectedIcon: Icon(Icons.event_note, color: Color(0xFFD4AF37)),
                label: 'Appuntamenti',
              ),
            // Fourth Tab: Admin only
            if (user?.role.name == 'admin')
              NavigationDestination(
                icon: Icon(
                  Icons.admin_panel_settings_outlined,
                  color: widget.currentIndex == 3 ? Color(0xFFD4AF37) : Colors.white60,
                ),
                selectedIcon: Icon(Icons.admin_panel_settings, color: Color(0xFFD4AF37)),
                label: 'Admin',
              ),
          ],
        ),
      ),
    );
  }
}
