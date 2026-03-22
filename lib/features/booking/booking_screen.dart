import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/user_model.dart';
import '../../models/barber_model.dart';
import '../../models/service_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/slot_service.dart';
import 'booking_widgets.dart';
import 'steps/customer_selection_step.dart';
import 'steps/barber_selection_step.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  UserModel? _selectedCustomer;
  bool _isGuestBooking = false;
  String _guestName = '';
  String _guestPhone = '';
  final TextEditingController _guestNameController = TextEditingController();
  final TextEditingController _guestPhoneController = TextEditingController();
  String _searchQuery = '';
  BarberModel? _selectedBarber;
  ServiceModel? _selectedService;
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedSlot;
  bool _bookingSuccess = false;
  bool _bookingBlocked = false;
  bool _isBooking = false;
  final _slotsScrollController = ScrollController();

  @override
  void dispose() {
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _slotsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;
    final isPrivileged = user?.role == UserRole.admin || user?.role == UserRole.barber;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    // Show blocked screen if booking was blocked
    if (_bookingBlocked) {
      return _buildBlockedScreen();
    }
    
    // Show success screen if booking was successful
    if (_bookingSuccess) {
      return _buildSuccessScreen();
    }
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _stepTitle(isPrivileged),
            key: ValueKey(_stepTitle(isPrivileged)),
            style: GoogleFonts.cinzel(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: isDesktop ? 20 : null,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
          child: Column(
            children: [
              // Progress Indicator
              _buildProgressIndicator(isPrivileged),
              Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),

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
        ),
      ),
    );
  }

  Widget _buildBlockedScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Blocked icon with continuous rotation
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: RotationTransition(
                turns: const AlwaysStoppedAnimation(0.0),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, child) {
                    return Transform.rotate(
                      angle: value * 6.28, // Full rotation
                      child: child,
                    );
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.red,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.block,
                      size: 60,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Blocked message
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 600),
              child: Text(
                'LIMITE RAGGIUNTO',
                style: GoogleFonts.cinzel(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            
            // Explanation
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Hai già un appuntamento attivo questa settimana.\n\nPer modificarlo o ricevere assistenza, contatta direttamente il negozio.',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Contact shop button
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 600),
              child: FilledButton.icon(
                onPressed: () async {
                  // ← Aggiorna il numero WhatsApp del negozio qui sotto
                  const shopWhatsApp = '393514823048';
                  final uri = Uri.parse('https://wa.me/$shopWhatsApp');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  'CONTATTA IL NEGOZIO',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Return button
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 600),
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _bookingBlocked = false;
                    _currentStep = 0;
                    _selectedService = null;
                    _selectedSlot = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(
                  'TORNA INDIETRO',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final customerName = _isGuestBooking
        ? _guestName
        : (_selectedCustomer?.name ??
            ref.read(currentUserProfileProvider).value?.name ??
            'Cliente');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
  
                // Animated check mark
              FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 600),
                child: Column(
                  children: [
                    Text(
                      'PRENOTAZIONE',
                      style: GoogleFonts.cinzel(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'CONFERMATA',
                      style: GoogleFonts.cinzel(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                delay: const Duration(milliseconds: 380),
                duration: const Duration(milliseconds: 600),
                child: Text(
                  'Ci vediamo presto!',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Details card
              FadeInUp(
                delay: const Duration(milliseconds: 450),
                duration: const Duration(milliseconds: 600),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.22),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSuccessRow(
                          Icons.person_outline, 'Cliente', customerName),
                      _buildSuccessDivider(),
                      _buildSuccessRow(Icons.content_cut, 'Barbiere',
                          _selectedBarber!.name),
                      _buildSuccessDivider(),
                      _buildSuccessRow(Icons.spa_outlined, 'Servizio',
                          _selectedService!.name),
                      _buildSuccessDivider(),
                      _buildSuccessRow(
                        Icons.calendar_today_outlined,
                        'Data',
                        DateFormat('EEEE d MMMM yyyy', 'it')
                            .format(_selectedSlot!),
                      ),
                      _buildSuccessDivider(),
                      _buildSuccessRow(
                        Icons.access_time_outlined,
                        'Orario',
                        '${DateFormat('HH:mm').format(_selectedSlot!)}  ·  ${_selectedService!.durationMinutes} min',
                      ),
                      _buildSuccessDivider(),
                      _buildSuccessRow(
                        Icons.euro_outlined,
                        'Prezzo',
                        '€${_selectedService!.price.toStringAsFixed(2)}',
                        valueColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Home button
              FadeInUp(
                delay: const Duration(milliseconds: 550),
                duration: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.home_outlined),
                    label: Text(
                      'TORNA ALLA HOME',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
            ),
        ),
      ),
      ),
    );
  }

  Widget _buildSuccessRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 9,
                    color: Colors.white30,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessDivider() {
    return Divider(height: 1, color: Colors.white.withValues(alpha: 0.07));
  }

  Widget _buildProgressIndicator(bool isPrivileged) {
    final steps = isPrivileged 
        ? ['Cliente', 'Barbiere', 'Servizio', 'Orario', 'Conferma']
        : ['Barbiere', 'Servizio', 'Orario', 'Conferma'];

    return Container(
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), // Adjusted padding
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
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
  final isDone = _currentStep > step;
  
  return Expanded(
    child: Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect for current/active step
            if (isCurrent)
              FadeIn(
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 34 : 26,
              height: isCurrent ? 34 : 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone 
                    ? Theme.of(context).colorScheme.primary 
                    : isCurrent 
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                border: Border.all(
                  color: isActive 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: isCurrent ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                  )
                ] : null,
              ),
              child: Center(
                child: isDone
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : Text(
                        '${step + 1}',
                        style: GoogleFonts.montserrat(
                          color: isActive 
                              ? (isCurrent ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface)
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          fontSize: isCurrent ? 14 : 11,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: GoogleFonts.cinzel(
            fontSize: 9, 
            color: isCurrent 
                ? Theme.of(context).colorScheme.primary 
                : isActive 
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
            letterSpacing: 1.2,
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildProgressLine(int step) {
  final isActive = _currentStep > step;
  return Expanded(
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: 1.5,
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isActive 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).dividerColor.withValues(alpha: 0.15),
        gradient: isActive ? LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ],
        ) : null,
      ),
    ),
  );
}

  Widget _buildStepContent(bool isPrivileged) {
    // Privileged: 0:Customer, 1:Barber, 2:Service, 3:Time, 4:Confirm
    // Client:     0:Barber,   1:Service, 2:Time,   3:Confirm
    if (!isPrivileged) {
      switch (_currentStep) {
        case 0: return _buildBarberStep();
        case 1: return _buildServiceSelection();
        case 2: return _buildTimeSelection();
        case 3: return _buildConfirmation(isPrivileged);
        default: return const SizedBox();
      }
    } else {
      switch (_currentStep) {
        case 0: return _buildCustomerStep();
        case 1: return _buildBarberStep();
        case 2: return _buildServiceSelection();
        case 3: return _buildTimeSelection();
        case 4: return _buildConfirmation(isPrivileged);
        default: return const SizedBox();
      }
    }
  }

  Widget _buildCustomerStep() {
    return CustomerSelectionStep(
      isGuestBooking: _isGuestBooking,
      selectedCustomer: _selectedCustomer,
      guestName: _guestName,
      guestPhone: _guestPhone,
      guestNameController: _guestNameController,
      guestPhoneController: _guestPhoneController,
      searchQuery: _searchQuery,
      onCustomerSelected: (user) => setState(() => _selectedCustomer = user),
      onNewGuestTapped: () {
        _guestNameController.clear();
        _guestPhoneController.clear();
        setState(() {
          _isGuestBooking = true;
          _guestName = '';
          _guestPhone = '';
          _selectedCustomer = null;
        });
      },
      onExistingGuestTapped: (name, phone) {
        _guestNameController.text = name;
        _guestPhoneController.text = phone;
        setState(() {
          _isGuestBooking = true;
          _guestName = name;
          _guestPhone = phone;
          _selectedCustomer = null;
        });
      },
      onGuestModeDisabled: () {
        _guestNameController.clear();
        _guestPhoneController.clear();
        setState(() {
          _isGuestBooking = false;
          _guestName = '';
          _guestPhone = '';
        });
      },
      onGuestNameChanged: (v) => setState(() => _guestName = v),
      onGuestPhoneChanged: (v) => setState(() => _guestPhone = v),
      onSearchChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  Widget _buildBarberStep() {
    return BarberSelectionStep(
      selectedBarber: _selectedBarber,
      onBarberSelected: (barber, date) => setState(() {
        _selectedBarber = barber;
        _selectedDate = date;
        _selectedSlot = null;
      }),
    );
  }

  Widget _buildServiceSelection() {
    final servicesAsync = ref.watch(serviceListProvider);
    
    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) return Center(child: Text('Nessun servizio disponibile', style: GoogleFonts.montserrat(color: Colors.white)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            final isSelected = _selectedService?.id == service.id;
            
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              duration: const Duration(milliseconds: 500),
              child: PremiumServiceCard(
                service: service,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedService = service),
              ),
            );
          },
        );
      },
      loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      error: (e, _) => Center(child: Text('Errore: $e', style: const TextStyle(color: Colors.red))),
    );
  }



  Widget _buildTimeSelection() {
    if (_selectedBarber == null || _selectedService == null) {
      return Center(
        child: Text('Seleziona prima un barbiere e un servizio.',
            style: GoogleFonts.montserrat(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      );
    }

    final shopSettings = ref.watch(shopSettingsProvider).valueOrNull;
    final slotSvc = ref.read(slotServiceProvider);
    final barber = _selectedBarber!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = today.add(const Duration(days: 30));
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    bool isDayUnavailable(DateTime day) {
      final d = DateTime(day.year, day.month, day.day);
      if (d.isBefore(today) || d.isAfter(lastDay)) return true;
      if (day.weekday == DateTime.sunday) return true;
      if (barber.availabilityStatus != BarberAvailability.available) return true;
      if (barber.daysOff.contains(day.weekday)) return true;
      if (barber.unavailableDates.any(
          (u) => u.year == day.year && u.month == day.month && u.day == day.day)) {
        return true;
      }
      if (shopSettings != null) {
        if (shopSettings.isShopClosedManually) return true;
        if (shopSettings.closures.any(
            (c) => c.year == day.year && c.month == day.month && c.day == day.day)) {
          return true;
        }
        final shopDay = shopSettings.weeklySchedule[day.weekday];
        if (shopDay != null && shopDay.isClosed) return true;
      }
      return false;
    }

    // Calcola il numero di slot liberi per un giorno (usa solo dati già in memoria)
    // Restituisce null se non si può sapere (appointments non ancora caricati)
    final appointmentsAsync =
        ref.watch(barberAppointmentsProvider((barberId: barber.id, date: _selectedDate)));
    final selectedDayAppointments = appointmentsAsync.valueOrNull ?? [];

    return SingleChildScrollView(
      controller: _slotsScrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SELEZIONA DATA',
              style: GoogleFonts.cinzel(
                  fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
          const SizedBox(height: 16),
          Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: (event) {
            if (!_slotsScrollController.hasClients) return;
            final dy = event.delta.dy;
            if (dy.abs() > event.delta.dx.abs()) {
              final pos = _slotsScrollController.position;
              final next = (pos.pixels - dy).clamp(0.0, pos.maxScrollExtent);
              _slotsScrollController.jumpTo(next);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF111111)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TableCalendar(
              locale: 'it_IT',
              firstDay: today,
              lastDay: lastDay,
              focusedDay: _selectedDate,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
              enabledDayPredicate: (day) => !isDayUnavailable(day),
              onDaySelected: (selected, focused) {
                if (!isDayUnavailable(selected)) {
                  setState(() {
                    _selectedDate = selected;
                    _selectedSlot = null;
                  });
                }
              },
              onPageChanged: (_) {},
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.cinzel(
                    color: onSurface, fontWeight: FontWeight.bold, fontSize: 15),
                leftChevronIcon: Icon(Icons.chevron_left, color: primary),
                rightChevronIcon: Icon(Icons.chevron_right, color: primary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.montserrat(
                    color: onSurface.withValues(alpha: 0.5), fontSize: 11),
                weekendStyle: GoogleFonts.montserrat(
                    color: onSurface.withValues(alpha: 0.3), fontSize: 11),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: GoogleFonts.montserrat(color: onSurface, fontSize: 13),
                weekendTextStyle:
                    GoogleFonts.montserrat(color: onSurface.withValues(alpha: 0.4), fontSize: 13),
                disabledTextStyle:
                    GoogleFonts.montserrat(color: onSurface.withValues(alpha: 0.18), fontSize: 13),
                todayDecoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: GoogleFonts.montserrat(
                    color: primary, fontWeight: FontWeight.bold, fontSize: 13),
                selectedDecoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                selectedTextStyle: GoogleFonts.montserrat(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              calendarBuilders: CalendarBuilders(
                // Dot sotto i giorni disponibili per indicare presenza di slot
                markerBuilder: (ctx, day, events) {
                  if (isDayUnavailable(day)) return const SizedBox.shrink();
                  // Mostra un pallino verde sotto il giorno selezionato se ha slot
                  if (isSameDay(day, _selectedDate) && shopSettings != null) {
                    final slots = slotSvc.getAvailableSlots(
                      barber: barber,
                      date: day,
                      serviceDurationMinutes: _selectedService!.durationMinutes,
                      existingAppointments: selectedDayAppointments,
                      shopSettings: shopSettings,
                    );
                    if (slots.isEmpty) {
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
        ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.access_time, color: onSurface, size: 20),
              const SizedBox(width: 8),
              Text('ORARI DISPONIBILI',
                  style: GoogleFonts.cinzel(
                      fontSize: 18, fontWeight: FontWeight.bold, color: onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          SlotsGrid(
            barber: barber,
            service: _selectedService!,
            date: _selectedDate,
            selectedSlot: _selectedSlot,
            onSlotSelected: (slot) => setState(() => _selectedSlot = slot),
            onDateChangeRequested: (nextDate) => setState(() {
              _selectedDate = nextDate;
              _selectedSlot = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(bool isPrivileged) {
    if (_selectedBarber == null || _selectedService == null || _selectedSlot == null) {
      return Center(child: Text('Informazioni mancanti.', style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RIEPILOGO',
            style: GoogleFonts.cinzel(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Controlla i dettagli prima di confermare.',
            style: GoogleFonts.montserrat(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 32),
          
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'THE GENTLEMEN',
                        style: GoogleFonts.cinzel(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'BARBER STUDIO',
                        style: GoogleFonts.montserrat(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 10,
                          letterSpacing: 4.0,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (isPrivileged)
                        _buildSummaryRow('Cliente', _isGuestBooking ? '$_guestName (Guest)' : _selectedCustomer!.name),
                      _buildSummaryRow('Barbiere', _selectedBarber!.name),
                      _buildSummaryRow('Servizio', _selectedService!.name),
                      _buildSummaryRow('Data', DateFormat('d MMMM yyyy', 'it').format(_selectedSlot!)),
                      _buildSummaryRow('Orario', DateFormat('HH:mm').format(_selectedSlot!)),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTALE',
                            style: GoogleFonts.cinzel(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '€${_selectedService!.price.toStringAsFixed(2)}',
                            style: GoogleFonts.montserrat(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_filled, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ti preghiamo di arrivare 5 minuti prima dell\'orario prenotato.',
                    style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isPrivileged) {
  final maxSteps = isPrivileged ? 4 : 3;
  final canProceed = _canProceed(isPrivileged);

  return Container(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).padding.bottom,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, -5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _currentStep--;
                  _resetFromStep(_currentStep, isPrivileged);
                }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'INDIETRO', 
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  )
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: canProceed ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ] : null,
              ),
              child: FilledButton(
                onPressed: canProceed && !_isBooking ? () => _onNext(maxSteps) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  disabledBackgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isBooking
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        _currentStep == maxSteps ? 'CONFERMA' : 'AVANTI',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  // Resetta le selezioni a cascata quando si torna indietro.
  // stepNow = step su cui si è appena arrivati (dopo il --)
  void _resetFromStep(int stepNow, bool isPrivileged) {
    // Indici degli step per i non-privileged: 0=Barbiere 1=Servizio 2=Orario 3=Conferma
    // Per i privileged:                       0=Cliente  1=Barbiere 2=Servizio 3=Orario 4=Conferma
    final barberStep = isPrivileged ? 1 : 0;
    final serviceStep = isPrivileged ? 2 : 1;

    if (stepNow <= barberStep) {
      // Torno al barbiere → azzero servizio e slot
      _selectedService = null;
      _selectedSlot = null;
    } else if (stepNow <= serviceStep) {
      // Torno al servizio → azzero solo lo slot
      _selectedSlot = null;
    }
  }

  String _stepTitle(bool isPrivileged) {
    if (!isPrivileged) {
      const titles = ['SCEGLI BARBIERE', 'SCEGLI SERVIZIO', 'SCEGLI ORARIO', 'RIEPILOGO'];
      return _currentStep < titles.length ? titles[_currentStep] : 'PRENOTA';
    } else {
      const titles = ['SELEZIONA CLIENTE', 'SCEGLI BARBIERE', 'SCEGLI SERVIZIO', 'SCEGLI ORARIO', 'RIEPILOGO'];
      return _currentStep < titles.length ? titles[_currentStep] : 'PRENOTA';
    }
  }

  bool _canProceed(bool isPrivileged) {
    if (isPrivileged) {
      switch (_currentStep) {
        case 0: return _isGuestBooking ? (_guestName.isNotEmpty && _guestPhone.isNotEmpty) : _selectedCustomer != null;
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
    if (_currentStep == 0 && _isGuestBooking) {
      if (_guestName.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inserisci il nome del cliente'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_guestPhone.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inserisci il numero di telefono'), backgroundColor: Colors.red),
        );
        return;
      }
      if (_guestPhone.trim().length < 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Il numero di telefono deve avere almeno 9 cifre'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (_currentStep < maxSteps) {
      setState(() => _currentStep++);
    } else {
      _confirmBooking();
    }
  }

  Future<void> _confirmBooking() async {
    // the method is asynchronous and the widget may disappear while the
    // futures are resolving.  check `mounted` after every `await` and
    // never call `ScaffoldMessenger.of(context)` on a deactivated state.

    if (_isBooking) return;
    if (!mounted) return;
    setState(() => _isBooking = true);
    final messenger = ScaffoldMessenger.of(context); // resolve once while mounted

    final currentUser = ref.read(currentUserProfileProvider).value;
    if (currentUser == null) {
      messenger.showSnackBar(
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

    // --- CHECK WEEKLY LIMIT (only for clients booking for themselves) ---
    bool canCreateAppointment = true; // Flag to prevent booking if limit reached

    final isPrivileged = currentUser.role == UserRole.admin || currentUser.role == UserRole.barber;
    if (!_isGuestBooking && !isPrivileged) {
      try {
        // Fetch all appointments for this user and filter locally to avoid index requirement
        final allUserAppointments = await ref.read(firestoreServiceProvider).getAllAppointmentsForCustomer(customerId).first.timeout(const Duration(seconds: 10));

        // Calculate week boundaries
        final int daysToSubtract = _selectedSlot!.weekday - 1;
        final DateTime startOfWeek = DateTime(_selectedSlot!.year, _selectedSlot!.month, _selectedSlot!.day).subtract(Duration(days: daysToSubtract));
        final DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

        // Count non-cancelled appointments in this week (past or future).
        // One slot per week regardless of whether it already happened.
        int weeklyCount = 0;
        for (var apt in allUserAppointments) {
          if (apt.status != AppointmentStatus.cancelled &&
              apt.date.isAfter(startOfWeek) &&
              apt.date.isBefore(endOfWeek)) {
            weeklyCount++;
          }
        }

        if (!mounted) return;
        if (weeklyCount >= 1) {
          canCreateAppointment = false;
          setState(() {
            _bookingBlocked = true;
            _isBooking = false;
          });
          return;
        }
      } catch (_) {
        // Se non è possibile controllare il limite, procede comunque
      }
    }

    if (!canCreateAppointment) return;
    
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

      // Save guest client for future lookups
      if (_isGuestBooking && _guestPhone.isNotEmpty) {
        await ref.read(firestoreServiceProvider).saveGuestClient(_guestName, _guestPhone);
      }

      // Trigger immediate local notification
      ref.read(notificationServiceProvider).showImmediateNotification(
        title: 'Prenotazione Confermata',
        body: '${_selectedService!.name} il ${DateFormat("dd/MM 'alle' HH:mm").format(_selectedSlot!)} — ci vediamo!',
        payload: isPrivileged ? '/calendar' : '/profile',
      );


      if (!mounted) return;

      setState(() => _bookingSuccess = true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Errore durante la prenotazione: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }
}
