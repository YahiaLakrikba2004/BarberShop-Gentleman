import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/user_model.dart';
import '../../../services/firestore_service.dart';
import '../booking_widgets.dart';

class CustomerSelectionStep extends ConsumerWidget {
  final bool isGuestBooking;
  final UserModel? selectedCustomer;
  final String guestName;
  final String guestPhone;
  final TextEditingController guestNameController;
  final TextEditingController guestPhoneController;
  final String searchQuery;
  final void Function(UserModel?) onCustomerSelected;
  final VoidCallback onNewGuestTapped;
  final void Function(String name, String phone) onExistingGuestTapped;
  final VoidCallback onGuestModeDisabled;
  final void Function(String) onGuestNameChanged;
  final void Function(String) onGuestPhoneChanged;
  final void Function(String) onSearchChanged;

  const CustomerSelectionStep({
    super.key,
    required this.isGuestBooking,
    required this.selectedCustomer,
    required this.guestName,
    required this.guestPhone,
    required this.guestNameController,
    required this.guestPhoneController,
    required this.searchQuery,
    required this.onCustomerSelected,
    required this.onNewGuestTapped,
    required this.onExistingGuestTapped,
    required this.onGuestModeDisabled,
    required this.onGuestNameChanged,
    required this.onGuestPhoneChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isGuestBooking) return _buildGuestForm(context);

    final usersAsync = ref.watch(allUsersProvider);
    final guestClientsAsync = ref.watch(guestClientsProvider);

    return usersAsync.when(
      data: (users) {
        final filteredUsers = users.where((u) {
          if (u.role != UserRole.client) return false;
          final q = searchQuery.toLowerCase();
          return u.name.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
        }).toList();

        final guests = guestClientsAsync.value ?? [];
        final filteredGuests = searchQuery.isEmpty
            ? guests
            : guests.where((g) {
                final q = searchQuery.toLowerCase();
                return (g['name'] ?? '').toLowerCase().contains(q) ||
                    (g['phone'] ?? '').toLowerCase().contains(q);
              }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: BookingTextField(
                  label: 'Cerca cliente...', icon: Icons.search, onChanged: onSearchChanged),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ...filteredUsers.map((user) => _RegisteredUserTile(
                        user: user,
                        isSelected: selectedCustomer?.id == user.id,
                        onTap: () => onCustomerSelected(user),
                      )),
                  _GuestSection(
                    filteredGuests: filteredGuests,
                    onNewGuestTapped: onNewGuestTapped,
                    onExistingGuestTapped: onExistingGuestTapped,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () =>
          Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      error: (e, _) =>
          Center(child: Text('Errore: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildGuestForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E0E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(color: Colors.white.withValues(alpha: 0.04), blurRadius: 20, spreadRadius: 2)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3, height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CLIENTE OCCASIONALE',
                            style: GoogleFonts.cinzel(
                                fontSize: 14, fontWeight: FontWeight.bold,
                                color: Colors.white, letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text('Non registrato nel sistema',
                            style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white38)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text('GUEST',
                          style: GoogleFonts.montserrat(
                              color: Colors.white, fontSize: 9,
                              fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                const SizedBox(height: 20),
                BookingTextField(
                  label: 'Nome e Cognome *',
                  icon: Icons.person_outline,
                  controller: guestNameController,
                  onChanged: onGuestNameChanged,
                ),
                const SizedBox(height: 14),
                BookingTextField(
                  label: 'Telefono (opzionale)',
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.phone,
                  controller: guestPhoneController,
                  onChanged: onGuestPhoneChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onGuestModeDisabled,
            icon: const Icon(Icons.arrow_back, color: Colors.white24, size: 16),
            label: Text('Torna alla lista clienti',
                style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─── Tile per utente registrato ───────────────────────────────────────────────

class _RegisteredUserTile extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final VoidCallback onTap;

  const _RegisteredUserTile(
      {required this.user, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            UserAvatar(user: user, isSelected: isSelected),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.bold, fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(user.email,
                      style: GoogleFonts.montserrat(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 12)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Sezione clienti occasionali ─────────────────────────────────────────────

class _GuestSection extends ConsumerWidget {
  final List<Map<String, String>> filteredGuests;
  final VoidCallback onNewGuestTapped;
  final void Function(String name, String phone) onExistingGuestTapped;

  const _GuestSection({
    required this.filteredGuests,
    required this.onNewGuestTapped,
    required this.onExistingGuestTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Row(
            children: [
              Text('CLIENTI OCCASIONALI',
                  style: GoogleFonts.montserrat(
                      color: Colors.white.withValues(alpha: 0.35), fontSize: 10,
                      fontWeight: FontWeight.bold, letterSpacing: 2.0)),
              const Spacer(),
              GestureDetector(
                onTap: onNewGuestTapped,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add, size: 13,
                          color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 5),
                      Text('NUOVO',
                          style: GoogleFonts.montserrat(
                              color: Colors.white.withValues(alpha: 0.5), fontSize: 10,
                              fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (filteredGuests.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Nessun cliente occasionale salvato.',
                style: GoogleFonts.montserrat(
                    color: Colors.white.withValues(alpha: 0.2),
                    fontSize: 12, fontStyle: FontStyle.italic)),
          ),
        ...filteredGuests.map((guest) => _GuestTile(
              guest: guest,
              onTap: () => onExistingGuestTapped(
                  guest['name'] ?? '', guest['phone'] ?? ''),
              onDelete: () {
                final id = guest['id'];
                if (id != null && id.isNotEmpty) {
                  ref.read(firestoreServiceProvider).deleteGuestClient(id);
                }
              },
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _GuestTile extends StatelessWidget {
  final Map<String, String> guest;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GuestTile(
      {required this.guest, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(guest['id'] ?? guest['name'] ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text('Rimuovi cliente',
                style: GoogleFonts.cinzel(color: Colors.white)),
            content: Text(
              'Vuoi rimuovere "${guest['name']}" dalla lista dei clienti occasionali?',
              style: GoogleFonts.montserrat(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annulla', style: TextStyle(color: Colors.white38)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Rimuovi', style: TextStyle(color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    (guest['name'] ?? '?').isNotEmpty
                        ? guest['name']![0].toUpperCase() : '?',
                    style: GoogleFonts.cinzel(
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.6)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guest['name'] ?? '',
                        style: GoogleFonts.cinzel(
                            fontWeight: FontWeight.bold, fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.85))),
                    if ((guest['phone'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(guest['phone']!,
                          style: GoogleFonts.montserrat(
                              color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6)),
                child: Text('GUEST',
                    style: GoogleFonts.montserrat(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.swipe_left_outlined, size: 14,
                  color: Colors.white.withValues(alpha: 0.2)),
            ],
          ),
        ),
      ),
    );
  }
}
