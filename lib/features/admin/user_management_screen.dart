import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('GESTIONE UTENTI'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cerca utente per nome o email...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // User List
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filteredUsers = users.where((user) {
                  final query = _searchQuery.toLowerCase();
                  return user.name.toLowerCase().contains(query) ||
                         user.email.toLowerCase().contains(query);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: FadeIn(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 80,
                            color: const Color(0xFFD4AF37).withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty 
                                ? 'Nessun utente trovato' 
                                : 'Nessun risultato per "$_searchQuery"',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 50), // Faster animation for list
                      child: _UserCard(user: user),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                ),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Errore: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  final UserModel user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getRoleColor(user.role)),
                  ),
                  child: Icon(
                    _getRoleIcon(user.role),
                    color: _getRoleColor(user.role),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user.role).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getRoleColor(user.role)),
                  ),
                  child: Text(
                    _getRoleText(user.role),
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: const Color(0xFFD4AF37).withOpacity(0.2), height: 1),
            const SizedBox(height: 16),
            const Text(
              'Cambia Ruolo:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RoleButton(
                    label: 'Cliente',
                    icon: Icons.person,
                    color: const Color(0xFF2196F3),
                    isSelected: user.role == UserRole.client,
                    onTap: () => _updateRole(ref, user.id, UserRole.client, context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RoleButton(
                    label: 'Barbiere',
                    icon: Icons.content_cut,
                    color: const Color(0xFF4CAF50),
                    isSelected: user.role == UserRole.barber,
                    onTap: () => _updateRole(ref, user.id, UserRole.barber, context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RoleButton(
                    label: 'Admin',
                    icon: Icons.admin_panel_settings,
                    color: const Color(0xFFFF9800),
                    isSelected: user.role == UserRole.admin,
                    onTap: () => _updateRole(ref, user.id, UserRole.admin, context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateRole(WidgetRef ref, String userId, UserRole newRole, BuildContext context) async {
    try {
      await ref.read(firestoreServiceProvider).updateUserRole(userId, newRole);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ruolo aggiornato a ${_getRoleText(newRole)}'),
            backgroundColor: const Color(0xFFD4AF37),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.client:
        return const Color(0xFF2196F3);
      case UserRole.barber:
        return const Color(0xFF4CAF50);
      case UserRole.admin:
        return const Color(0xFFFF9800);
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.client:
        return Icons.person;
      case UserRole.barber:
        return Icons.content_cut;
      case UserRole.admin:
        return Icons.admin_panel_settings;
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.client:
        return 'CLIENTE';
      case UserRole.barber:
        return 'BARBIERE';
      case UserRole.admin:
        return 'ADMIN';
    }
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isSelected ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
