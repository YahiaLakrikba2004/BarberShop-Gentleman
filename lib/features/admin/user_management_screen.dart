import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
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
      appBar: AppBar(
        title: Text(
          'GESTIONE UTENTI',
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Cerca utente per nome o email...',
                hintStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
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
                            color: const Color(0xFFFFFFFF).withOpacity(0.3),
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
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
                        style: GoogleFonts.cinzel(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: GoogleFonts.montserrat(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
            Divider(color: const Color(0xFFFFFFFF).withOpacity(0.2), height: 1),
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
                    color: Colors.redAccent,
                    isSelected: user.role == UserRole.admin,
                    onTap: () => _updateRole(ref, user.id, UserRole.admin, context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: const Color(0xFFFFFFFF).withOpacity(0.2), height: 1),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteDialog(context, ref, user),
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                label: const Text(
                  'ELIMINA UTENTE',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
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
            backgroundColor: const Color(0xFFFFFFFF),
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
        return Colors.redAccent;
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

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref, UserModel user) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.red.withOpacity(0.3)),
        ),
        title: Text(
          'Elimina Utente', 
          style: GoogleFonts.cinzel(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Sei sicuro di voler eliminare l\'utente ${user.name}? Questa azione è irreversibile.',
          style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(firestoreServiceProvider).deleteUser(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Utente eliminato con successo'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: isSelected ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : (isDark ? Colors.black.withOpacity(0.2) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : color.withOpacity(0.5),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: isSelected ? color : color.withOpacity(0.5),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
