import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../models/barber_model.dart';
import '../../models/service_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/slot_service.dart';
import '../../services/auth_service.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  int _currentStep = 0;
  UserModel? _selectedCustomer;
  bool _isGuestBooking = false;
  String _guestName = '';
  String _guestPhone = '';
  String _searchQuery = '';
  BarberModel? _selectedBarber;
  ServiceModel? _selectedService;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;
    final isPrivileged = user?.role == UserRole.admin || user?.role == UserRole.barber;
    
    // If not privileged, ensure selectedCustomer is current user (or null until confirmed)
    // But for logic simplicity, we'll handle the "target user" in _confirmBooking

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prenota Appuntamento'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(isPrivileged),
          const Divider(height: 1),
          
          // Content with Animation
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentStep),
                child: _buildStepContent(isPrivileged),
              ),
            ),
          ),
          
          // Navigation Buttons
          _buildNavigationButtons(isPrivileged),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isPrivileged) {
    final steps = isPrivileged 
        ? ['Cliente', 'Barbiere', 'Servizio', 'Orario', 'Conferma']
        : ['Barbiere', 'Servizio', 'Orario', 'Conferma'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _buildStepCircle(i, steps[i]),
            if (i < steps.length - 1) _buildProgressLine(i),
          ],
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive 
                  ? Theme.of(context).colorScheme.primary 
                  : Colors.grey.shade300,
              border: isCurrent 
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                  : null,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(int step) {
    final isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        color: isActive 
            ? Theme.of(context).colorScheme.primary 
            : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStepContent(bool isPrivileged) {
    int adjustedStep = _currentStep;
    if (!isPrivileged) {
      // If not privileged, step 0 maps to BarberSelection (which is index 1 in privileged flow logic if we were sharing indices, 
      // but here we just shift the logic)
      // Let's map steps based on flow:
      // Privileged: 0:Customer, 1:Barber, 2:Service, 3:Time, 4:Confirm
      // Client:     0:Barber,   1:Service, 2:Time,   3:Confirm
      
      // So if not privileged, we shift the "content" index by 1 to match the "Barber" starting point of privileged flow?
      // No, it's easier to just switch on current step and return appropriate widget.
      
      switch (_currentStep) {
        case 0: return _buildBarberSelection();
        case 1: return _buildServiceSelection();
        case 2: return _buildTimeSelection();
        case 3: return _buildConfirmation(isPrivileged);
        default: return const SizedBox();
      }
    } else {
      switch (_currentStep) {
        case 0: return _buildCustomerSelection();
        case 1: return _buildBarberSelection();
        case 2: return _buildServiceSelection();
        case 3: return _buildTimeSelection();
        case 4: return _buildConfirmation(isPrivileged);
        default: return const SizedBox();
      }
    }
  }

  Widget _buildCustomerSelection() {
    if (_isGuestBooking) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dati Cliente Occasionale',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Nome e Cognome *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() => _guestName = value),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Telefono (opzionale)',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      onChanged: (value) => setState(() => _guestPhone = value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() {
                _isGuestBooking = false;
                _guestName = '';
                _guestPhone = '';
              }),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Torna alla lista clienti'),
            ),
          ],
        ),
      );
    }

    final usersAsync = ref.watch(allUsersProvider);
    
    return usersAsync.when(
      data: (users) {
        final filteredUsers = users.where((user) {
          final query = _searchQuery.toLowerCase();
          return user.name.toLowerCase().contains(query) || 
                 user.email.toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cerca cliente...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _isGuestBooking = true;
                      _selectedCustomer = null;
                    }),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Prenota per Cliente Occasionale'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  final isSelected = _selectedCustomer?.id == user.id;
                  
                  return Card(
                    elevation: isSelected ? 4 : 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => setState(() => _selectedCustomer = user),
                      leading: CircleAvatar(
                        backgroundColor: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.surfaceVariant,
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimary 
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(user.email),
                      trailing: isSelected 
                          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
    );
  }

  Widget _buildBarberSelection() {
    final barbersAsync = ref.watch(barberListProvider);
    return barbersAsync.when(
      data: (barbers) {
        if (barbers.isEmpty) {
          return const Center(
            child: Text('Nessun barbiere disponibile. Contatta l\'amministratore.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: barbers.length,
          itemBuilder: (context, index) {
            final barber = barbers[index];
            final isSelected = _selectedBarber?.id == barber.id;
            
            return AnimatedScale(
              scale: isSelected ? 1.02 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              child: Card(
                elevation: isSelected ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () => setState(() => _selectedBarber = barber),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                barber.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                barber.specialties.join(' • '),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Orario: ${barber.startHour}:00 - ${barber.endHour}:00',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
    );
  }

  Widget _buildServiceSelection() {
    final servicesAsync = ref.watch(serviceListProvider);
    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) {
          return const Center(
            child: Text('Nessun servizio disponibile. Contatta l\'amministratore.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            final isSelected = _selectedService?.id == service.id;
            
            return Card(
              elevation: isSelected ? 4 : 1,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => setState(() => _selectedService = service),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.content_cut,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service.description,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${service.durationMinutes} min',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.euro, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  '${service.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 32,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
    );
  }

  Widget _buildTimeSelection() {
    if (_selectedBarber == null || _selectedService == null) {
      return const Center(
        child: Text('Seleziona prima un barbiere e un servizio.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleziona la data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: CalendarDatePicker(
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              onDateChanged: (date) => setState(() {
                _selectedDate = date;
                _selectedSlot = null;
              }),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Orari disponibili per ${DateFormat('dd MMMM yyyy', 'it').format(_selectedDate)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _SlotsGrid(
            barber: _selectedBarber!,
            service: _selectedService!,
            date: _selectedDate,
            selectedSlot: _selectedSlot,
            onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(bool isPrivileged) {
    if (_selectedBarber == null || _selectedService == null || _selectedSlot == null) {
      return const Center(child: Text('Informazioni mancanti.'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riepilogo Prenotazione',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          if (isPrivileged)
            _buildSummaryCard(
              icon: Icons.person_outline,
              title: 'Cliente',
              content: _isGuestBooking ? '$_guestName (Occasionale)' : _selectedCustomer!.name,
            ),

          _buildSummaryCard(
            icon: Icons.person,
            title: 'Barbiere',
            content: _selectedBarber!.name,
          ),
          
          _buildSummaryCard(
            icon: Icons.content_cut,
            title: 'Servizio',
            content: _selectedService!.name,
          ),
          
          _buildSummaryCard(
            icon: Icons.calendar_today,
            title: 'Data',
            content: DateFormat('dd MMMM yyyy', 'it').format(_selectedSlot!),
          ),
          
          _buildSummaryCard(
            icon: Icons.access_time,
            title: 'Orario',
            content: DateFormat('HH:mm').format(_selectedSlot!),
          ),
          
          _buildSummaryCard(
            icon: Icons.euro,
            title: 'Prezzo',
            content: '€${_selectedService!.price.toStringAsFixed(2)}',
          ),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Riceverai una conferma via email. Ti preghiamo di arrivare 5 minuti prima dell\'orario prenotato.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isPrivileged) {
    final maxSteps = isPrivileged ? 4 : 3;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Indietro'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: _canProceed(isPrivileged) ? () => _onNext(maxSteps) : null,
              child: Text(_currentStep == maxSteps ? 'Conferma Prenotazione' : 'Avanti'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed(bool isPrivileged) {
    if (isPrivileged) {
      switch (_currentStep) {
        case 0: return _isGuestBooking ? _guestName.isNotEmpty : _selectedCustomer != null;
        case 1: return _selectedBarber != null;
        case 2: return _selectedService != null;
        case 3: return _selectedSlot != null;
        case 4: return true;
        default: return false;
      }
    } else {
      switch (_currentStep) {
        case 0: return _selectedBarber != null;
        case 1: return _selectedService != null;
        case 2: return _selectedSlot != null;
        case 3: return true;
        default: return false;
      }
    }
  }

  void _onNext(int maxSteps) {
    if (_currentStep < maxSteps) {
      setState(() => _currentStep++);
    } else {
      _confirmBooking();
    }
  }

  Future<void> _confirmBooking() async {
    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Devi effettuare il login per prenotare.')),
      );
      return;
    }

    String customerId;
    String customerName;
    String? customerPhone;

    if (_isGuestBooking) {
      customerId = 'guest_${const Uuid().v4()}';
      customerName = _guestName;
      customerPhone = _guestPhone.isNotEmpty ? _guestPhone : null;
    } else {
      final targetUser = _selectedCustomer ?? currentUser;
      customerId = targetUser.id;
      customerName = targetUser.name;
      customerPhone = targetUser.phoneNumber;
    }

    final appointment = AppointmentModel(
      id: const Uuid().v4(),
      customerId: customerId,
      customerName: customerName,
      customerPhoneNumber: customerPhone,
      barberId: _selectedBarber!.id,
      barberName: _selectedBarber!.name,
      serviceId: _selectedService!.id,
      serviceName: _selectedService!.name,
      date: _selectedSlot!,
      durationMinutes: _selectedService!.durationMinutes,
      price: _selectedService!.price,
      status: AppointmentStatus.confirmed,
    );

    try {
      await ref.read(firestoreServiceProvider).createAppointment(appointment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prenotazione confermata per $customerName!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante la prenotazione: $e')),
        );
      }
    }
  }
}

class _SlotsGrid extends ConsumerWidget {
  final BarberModel barber;
  final ServiceModel service;
  final DateTime date;
  final DateTime? selectedSlot;
  final Function(DateTime) onSlotSelected;

  const _SlotsGrid({
    required this.barber,
    required this.service,
    required this.date,
    required this.selectedSlot,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(barberAppointmentsProvider((barber.id, date)));

    return appointmentsAsync.when(
      data: (appointments) {
        final slots = ref.read(slotServiceProvider).getAvailableSlots(
              barber: barber,
              date: date,
              serviceDurationMinutes: service.durationMinutes,
              existingAppointments: appointments,
            );

        if (slots.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nessuno slot disponibile per questa data',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prova a selezionare un\'altra data',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: slots.map((slot) {
            final isSelected = selectedSlot == slot;
            return InkWell(
              onTap: () => onSlotSelected(slot),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary 
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  DateFormat('HH:mm').format(slot),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Errore nel caricamento degli slot: $e',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

// Providers needed for this screen
final barberListProvider = StreamProvider<List<BarberModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getBarbers();
});

final serviceListProvider = StreamProvider<List<ServiceModel>>((ref) {
  return ref.watch(firestoreServiceProvider).getServices();
});

final barberAppointmentsProvider = StreamProvider.family<List<AppointmentModel>, (String, DateTime)>((ref, arg) {
  return ref.watch(firestoreServiceProvider).getAppointmentsForBarber(arg.$1, arg.$2);
});
