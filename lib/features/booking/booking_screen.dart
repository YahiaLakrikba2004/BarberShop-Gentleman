import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:carousel_slider/carousel_slider.dart' hide CarouselController;
import '../../models/user_model.dart';
import '../../models/barber_model.dart';
import '../../models/service_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/slot_service.dart';
import '../../services/auth_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui'; // For BackdropFilter

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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
    
    return Expanded(
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCurrent ? 40 : 32,
            height: isCurrent ? 40 : 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive 
                  ? const Color(0xFFD4AF37) 
                  : const Color(0xFF2C2C2C),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
              border: isCurrent 
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Center(
              child: isActive
                  ? Icon(
                      Icons.check,
                      size: isCurrent ? 20 : 16,
                      color: Colors.black,
                    )
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: isCurrent ? 16 : 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 10,
              color: isActive ? const Color(0xFFD4AF37) : Colors.white24,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 0.5,
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
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isActive 
              ? const Color(0xFFD4AF37) 
              : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(2),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.5),
                    blurRadius: 4,
                  )
                ]
              : [],
        ),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add, color: Color(0xFFD4AF37), size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Cliente Occasionale',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nome e Cognome *',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
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
                    onChanged: (value) => setState(() => _guestName = value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Telefono *',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                      prefixIcon: const Icon(Icons.phone, color: Color(0xFFD4AF37)),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
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
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => setState(() => _guestPhone = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() {
                _isGuestBooking = false;
                _guestName = '';
                _guestPhone = '';
              }),
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: const Text('Torna alla lista clienti', style: TextStyle(color: Colors.white70)),
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
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cerca cliente...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
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
                      foregroundColor: const Color(0xFFD4AF37),
                      side: const BorderSide(color: Color(0xFFD4AF37)),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCustomer = user),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFFD4AF37) 
                                  : const Color(0xFF2C2C2C),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: ClipOval(
                              child: UserAvatar(
                                user: user,
                                isSelected: isSelected,
                              ),
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      error: (e, _) => Center(child: Text('Errore: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildInitials(UserModel user, bool isSelected) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFFD4AF37) 
            : const Color(0xFF2C2C2C),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildBarberSelection() {
    final barbers = ref.watch(barberListProvider).maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );
    
    final allBarbers = barbers;

    if (allBarbers.isEmpty) {
      return const Center(
        child: Text(
          'Nessun barbiere disponibile.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7, // Taller for full body/portrait look
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: allBarbers.length,
      itemBuilder: (context, index) {
        final barber = allBarbers[index];
        final isSelected = _selectedBarber?.id == barber.id;
        final isAvailable = barber.availabilityStatus == BarberAvailability.available;
        
        // Days off text removed as per request

        return GestureDetector(
          onTap: isAvailable ? () => setState(() => _selectedBarber = barber) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: isSelected 
                  ? Border.all(color: const Color(0xFFD4AF37), width: 3) 
                  : Border.all(color: Colors.transparent, width: 0),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Background Image (Full Card)
                  Builder(
                    builder: (context) {
                      String imageUrl = barber.imageUrl;
                      if (imageUrl.isEmpty) {
                        if (barber.name.toLowerCase().contains('omar')) {
                          imageUrl = 'assets/images/barber_marco.png';
                        } else if (barber.name.toLowerCase().contains('brombei')) {
                          imageUrl = 'assets/images/barber_giuseppe.png';
                        }
                      }

                      if (imageUrl.isNotEmpty) {
                        return imageUrl.startsWith('assets/')
                            ? Image.asset(imageUrl, fit: BoxFit.cover)
                            : Image.network(imageUrl, fit: BoxFit.cover);
                      }
                      return Container(color: const Color(0xFF2A2A2A));
                    }
                  ),

                  // 2. Gradient Overlay for Text Readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.95),
                        ],
                        stops: const [0.4, 0.6, 0.85, 1.0],
                      ),
                    ),
                  ),

                  // 3. Unavailable Overlay (Darken if not available)
                  if (!isAvailable)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                    ),

                  // 4. Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          barber.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          barber.specialties.take(2).join(' • '),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Info Row: Hours & Days Off
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: const Color(0xFFD4AF37),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${barber.startHour}-${barber.endHour}',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                  ),

                  // 5. Status Badge (Top Right)
                  if (!isAvailable)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: barber.availabilityStatus == BarberAvailability.sick 
                              ? Colors.red 
                              : barber.availabilityStatus == BarberAvailability.vacation 
                                  ? Colors.orange 
                                  : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          barber.availabilityStatus == BarberAvailability.sick 
                              ? 'MALATTIA' 
                              : barber.availabilityStatus == BarberAvailability.vacation 
                                  ? 'FERIE' 
                                  : 'NON DISPONIBILE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    
                  // 6. Selection Checkmark (Top Right - if available and selected)
                  if (isSelected)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4AF37),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceSelection() {
    final servicesAsync = ref.watch(serviceListProvider);
    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) {
          return const Center(
            child: Text('Nessun servizio disponibile. Contatta l\'amministratore.', style: TextStyle(color: Colors.white70)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            final isSelected = _selectedService?.id == service.id;
            
            return FadeInUp(
              delay: Duration(milliseconds: index * 100),
              duration: const Duration(milliseconds: 500),
              child: _PremiumServiceCard(
                service: service,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedService = service),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      error: (e, _) => Center(child: Text('Errore: $e', style: const TextStyle(color: Colors.red))),
    );
  }


  Widget _buildTimeSelection() {
    if (_selectedBarber == null || _selectedService == null) {
      return const Center(
        child: Text('Seleziona prima un barbiere e un servizio.', style: TextStyle(color: Colors.white70)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleziona la data',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.all(8),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFFD4AF37),
                  onPrimary: Colors.black,
                  surface: Color(0xFF1A1A1A),
                  onSurface: Colors.white,
                ),
              ),
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
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFFD4AF37)),
              const SizedBox(width: 12),
              Text(
                'Orari per ${DateFormat('d MMMM', 'it').format(_selectedDate)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
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
      return const Center(child: Text('Informazioni mancanti.', style: TextStyle(color: Colors.white70)));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riepilogo',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Controlla i dettagli prima di confermare.',
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
          const SizedBox(height: 32),
          
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(bottom: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.2))),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFFD4AF37), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Gentleman Barber Shop',
                        style: TextStyle(
                          color: const Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontFamily: 'PlayfairDisplay',
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
                        _buildSummaryRow('Cliente', _isGuestBooking ? '$_guestName (Occasionale)' : _selectedCustomer!.name),
                      _buildSummaryRow('Barbiere', _selectedBarber!.name),
                      _buildSummaryRow('Servizio', _selectedService!.name),
                      _buildSummaryRow('Data', DateFormat('d MMMM yyyy', 'it').format(_selectedSlot!)),
                      _buildSummaryRow('Orario', DateFormat('HH:mm').format(_selectedSlot!)),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.white10),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Totale',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '€${_selectedService!.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
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
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ti preghiamo di arrivare 5 minuti prima dell\'orario prenotato.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
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
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isPrivileged) {
    final maxSteps = isPrivileged ? 4 : 3;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Indietro'),
                  ),
                ),
              if (_currentStep > 0) const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _canProceed(isPrivileged) ? () => _onNext(maxSteps) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xFFD4AF37).withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentStep == maxSteps ? 'Conferma' : 'Avanti',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
          // Determine reason for unavailability
          String title = 'Nessuno slot disponibile';
          String message = 'Prova a selezionare un\'altra data';
          IconData icon = Icons.event_busy;
          Color color = Colors.grey;

          if (barber.availabilityStatus == BarberAvailability.sick) {
            title = '${barber.name} è in Malattia';
            message = 'Ci scusiamo per il disagio. Riprova più avanti.';
            icon = Icons.local_hospital;
            color = Colors.red;
          } else if (barber.availabilityStatus == BarberAvailability.vacation) {
            title = '${barber.name} è in Ferie';
            message = 'Tornerà presto operativo!';
            icon = Icons.flight_takeoff;
            color = Colors.orange;
          } else if (barber.daysOff.contains(date.weekday)) {
            title = 'Giorno di Riposo';
            message = '${barber.name} non lavora ${DateFormat('EEEE', 'it').format(date)}.';
            icon = Icons.weekend;
            color = Colors.blueGrey;
          } else if (barber.availabilityStatus == BarberAvailability.dayOff) {
             title = 'Non Disponibile';
             message = '${barber.name} non è disponibile in questa data.';
             icon = Icons.event_busy;
             color = Colors.grey;
          }

          return Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 48,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
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

class UserAvatar extends StatefulWidget {
  final UserModel user;
  final bool isSelected;

  const UserAvatar({
    super.key,
    required this.user,
    required this.isSelected,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  Uint8List? _decodedBytes;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.imageUrl != widget.user.imageUrl) {
      _decodeImage();
    }
  }

  void _decodeImage() {
    final imageUrl = widget.user.imageUrl ?? '';
    if (imageUrl.length > 100 && !imageUrl.startsWith('http') && !imageUrl.startsWith('assets/')) {
      try {
        _decodedBytes = base64Decode(imageUrl);
      } catch (e) {
        _decodedBytes = null;
      }
    } else {
      _decodedBytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.user.imageUrl ?? '';

    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('assets/')) {
        return Image.asset(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _buildInitials(),
        );
      } else if (_decodedBytes != null) {
        return Image.memory(
          _decodedBytes!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _buildInitials(),
        );
      } else if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitials(),
        );
      }
    }
    
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      width: 50,
      height: 50,
      alignment: Alignment.center,
      child: Text(
        widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: widget.isSelected ? Colors.black : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }
}

class _PremiumServiceCard extends StatefulWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const _PremiumServiceCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_PremiumServiceCard> createState() => _PremiumServiceCardState();
}

class _PremiumServiceCardState extends State<_PremiumServiceCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: widget.isSelected ? const Color(0xFFD4AF37).withOpacity(0.2) : const Color(0xFF1A1A1A),
            border: Border.all(
              color: widget.isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.1),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                if (widget.isSelected)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                
                if (widget.isSelected)
                  Positioned.fill(
                    child: Shimmer.fromColors(
                      baseColor: const Color(0xFFD4AF37).withOpacity(0.1),
                      highlightColor: const Color(0xFFD4AF37).withOpacity(0.4),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFFF7E7CE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Icon(
                            Icons.content_cut,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.service.name,
                              style: const TextStyle(
                                fontFamily: 'PlayfairDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.service.durationMinutes} min',
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '€${widget.service.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
