import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Added Google Fonts
import 'package:uuid/uuid.dart';
import 'package:carousel_slider/carousel_slider.dart' hide CarouselController;
import '../../models/user_model.dart';
import '../../models/barber_model.dart';
import '../../models/service_model.dart';
import '../../models/appointment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
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
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'PRENOTA APPUNTAMENTO',
          style: GoogleFonts.cinzel(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(isPrivileged),
          Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.1)),
          
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
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), // Adjusted padding
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
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
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                border: Border.all(
                  color: isActive 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).dividerColor.withOpacity(0.3),
                  width: 1.2,
                ),
                boxShadow: isCurrent ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.8)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
            : Theme.of(context).dividerColor.withOpacity(0.15),
        gradient: isActive ? LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ],
        ) : null,
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
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_add, color: Theme.of(context).colorScheme.onSurface, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'CLIENTE OCCASIONALE',
                        style: GoogleFonts.cinzel(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildPremiumTextField(
                    label: 'Nome e Cognome *',
                    icon: Icons.person,
                    onChanged: (value) => setState(() => _guestName = value),
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumTextField(
                    label: 'Telefono *',
                    icon: Icons.phone,
                    inputType: TextInputType.phone,
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
              icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 20),
              label: Text('Torna alla lista clienti', style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            ),
          ],
        ),
      );
    }

    final usersAsync = ref.watch(allUsersProvider);
    
    return usersAsync.when(
      data: (users) {
        final filteredUsers = users.where((user) {
          if (user.role != UserRole.client) return false;
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
                  _buildPremiumTextField(
                    label: 'Cerca cliente...',
                    icon: Icons.search,
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _isGuestBooking = true;
                      _selectedCustomer = null;
                    }),
                    icon: const Icon(Icons.person_add, size: 20),
                    label: Text('PRENOTA PER CLIENTE OCCASIONALE', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
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
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.1),
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
                                Text(
                                  user.name,
                                  style: GoogleFonts.cinzel(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: GoogleFonts.montserrat(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20),
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
      loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      error: (e, _) => Center(child: Text('Errore: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  // Helper for Premium TextFields
  Widget _buildPremiumTextField({
    required String label, 
    required IconData icon, 
    required Function(String) onChanged,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface),
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 20),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildBarberSelection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barbers = ref.watch(barberListProvider).maybeWhen(
      data: (list) => list,
      orElse: () => [],
    );
    
    final allBarbers = barbers.where((b) {
      // Hide if not bookable OR if it's the specific Shop account name (Failsafe)
      final isShop = b.name.toUpperCase() == 'NEGOZIO' || b.name.toUpperCase().contains('GENTLEMAN SHOP');
      return b.isBookable && !isShop;
    }).toList();

    if (allBarbers.isEmpty) {
      return Center(
        child: Text(
          'Nessun barbiere disponibile.',
          style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
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
        
        return GestureDetector(
          onTap: isAvailable ? () {
            setState(() {
              _selectedBarber = barber;
              DateTime date = DateTime.now();
              int attempts = 0;
              while (barber.daysOff.contains(date.weekday) && attempts < 30) {
                date = date.add(const Duration(days: 1));
                attempts++;
              }
              _selectedDate = date;
              _selectedSlot = null;
            });
          } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.5) 
                    : Theme.of(context).dividerColor.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.4 : 0.2),
                  blurRadius: isSelected ? 20 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Image
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

                      Widget imageWidget;
                      if (imageUrl.isNotEmpty) {
                         if (imageUrl.startsWith('assets/')) {
                           imageWidget = Image.asset(imageUrl, fit: BoxFit.cover, gaplessPlayback: true);
                         } else if (imageUrl.startsWith('http')) {
                           imageWidget = Image.network(imageUrl, fit: BoxFit.cover, gaplessPlayback: true);
                         } else {
                           try {
                             imageWidget = Image.memory(base64Decode(imageUrl), fit: BoxFit.cover, gaplessPlayback: true);
                           } catch (e) {
                             imageWidget = Container(color: const Color(0xFF222222));
                           }
                         }
                      } else {
                        imageWidget = Container(color: const Color(0xFF222222));
                      }
                      
                      return ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          isSelected ? Colors.transparent : (Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2)), 
                          BlendMode.darken
                        ),
                        child: imageWidget,
                      );
                    }
                  ),

                  // 2. Pro Grade Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white).withOpacity(0.2), // Mid-transition
                          (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white).withOpacity(0.8), // Text legibility
                          (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white).withOpacity(0.95), // Bottom anchor
                        ],
                        stops: const [0.4, 0.6, 0.85, 1.0],
                      ),
                    ),
                  ),

                  // 3. Glass Overlay for Content Area
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 85,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            border: Border(
                              top: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 4. Selection Border Overlay (Internal)
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          width: 2,
                        ),
                      ),
                    ),

                  // 5. Unavailable Overlay
                  if (!isAvailable)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                           child: Column(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(
                                 _getStatusIcon(barber.availabilityStatus), 
                                 color: _getStatusColor(barber.availabilityStatus).withOpacity(0.8), 
                                 size: 32
                               ),
                               const SizedBox(height: 8),
                               Text(
                                 _getStatusLabel(barber.availabilityStatus),
                                 style: GoogleFonts.montserrat(
                                    color: Colors.white.withOpacity(0.9), 
                                    fontSize: 12, 
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                 ),
                               ),
                             ],
                           ),
                        ),
                      ),
                    ),

                  // 6. Content Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barber Name
                        Text(
                          barber.name.toUpperCase(),
                          style: GoogleFonts.cinzel(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 10),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Specialties (New!)
                        if (barber.specialties.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            barber.specialties.join(' • ').toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: Theme.of(context).colorScheme.primary, // Silver/White accent
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                           const SizedBox(height: 4),
                           Text(
                            'SPECIALISTA TAGLIO & BARBA', // Default fallback
                            style: GoogleFonts.montserrat(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],

                        const SizedBox(height: 8),
                        
                        // Hours & Info Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.7), size: 10),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${barber.startHour}:00 - ${barber.endHour}:00',
                                    style: GoogleFonts.montserrat(
                                      color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(barber.availabilityStatus).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getStatusLabel(barber.availabilityStatus),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    
                  // 6. Selection Indicator (Animated)
                  if (isSelected)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            )
                          ]
                        ),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: Theme.of(context).colorScheme.onPrimary,
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
              child: _PremiumServiceCard(
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


  Color _getStatusColor(BarberAvailability status) {
    switch (status) {
      case BarberAvailability.sick:
        return const Color(0xFFDC143C); // Crimson
      case BarberAvailability.vacation:
        return Colors.blue.shade600;
      case BarberAvailability.absence:
        return Colors.grey.shade700;
      default:
        return const Color(0xFFDC143C);
    }
  }

  String _getStatusLabel(BarberAvailability status) {
    switch (status) {
      case BarberAvailability.sick:
        return 'MALATTIA';
      case BarberAvailability.vacation:
        return 'IN FERIE';
      case BarberAvailability.absence:
        return 'ASSENTE';
      default:
        return 'NON DISPONIBILE';
    }
  }

  IconData _getStatusIcon(BarberAvailability status) {
     switch (status) {
      case BarberAvailability.sick:
        return Icons.local_hospital;
      case BarberAvailability.vacation:
        return Icons.beach_access;
      case BarberAvailability.absence:
        return Icons.person_off;
      default:
        return Icons.block;
    }
  }

  Widget _buildTimeSelection() {
    if (_selectedBarber == null || _selectedService == null) {
      return Center(
        child: Text('Seleziona prima un barbiere e un servizio.', style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELEZIONA DATA',
            style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            padding: const EdgeInsets.all(8),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Theme.of(context).colorScheme.primary,
                  brightness: Theme.of(context).brightness,
                  primary: Theme.of(context).colorScheme.primary,
                  onPrimary: Theme.of(context).colorScheme.onPrimary,
                  surface: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white,
                  onSurface: Theme.of(context).colorScheme.onSurface,
                ),
                textTheme: TextTheme(
                  bodyLarge: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface),
                  bodyMedium: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface),
                  titleMedium: GoogleFonts.cinzel(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
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
              Icon(Icons.access_time, color: Theme.of(context).colorScheme.onSurface, size: 20),
              const SizedBox(width: 8),
              Text(
                'ORARI DISPONIBILI',
                style: GoogleFonts.cinzel(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
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
      return Center(child: Text('Informazioni mancanti.', style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))));
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
            style: GoogleFonts.montserrat(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 32),
          
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
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
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time_filled, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ti preghiamo di arrivare 5 minuti prima dell\'orario prenotato.',
                    style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
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
            style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
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
      bottom: MediaQuery.of(context).padding.bottom > 0 ? 0 : 16,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
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
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.15)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'INDIETRO', 
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ] : null,
              ),
              child: FilledButton(
                onPressed: canProceed ? () => _onNext(maxSteps) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  disabledBackgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                  disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
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
      
      // Trigger immediate local notification
      ref.read(notificationServiceProvider).showImmediateNotification(
        title: 'Prenotazione Confermata',
        body: 'Il tuo appuntamento per ${_selectedService!.name} è stato registrato per il ${DateFormat('dd/MM HH:mm').format(_selectedSlot!)}',
        payload: '/calendar',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prenotazione confermata per $customerName!', style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onPrimary)),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating, // Premium feel
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            action: SnackBarAction(label: 'OK', textColor: Theme.of(context).colorScheme.onPrimary, onPressed: () {}),
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
    final settingsAsync = ref.watch(shopSettingsProvider);

    return settingsAsync.when(
      data: (settings) => appointmentsAsync.when(
        data: (appointments) {
          final slots = ref.read(slotServiceProvider).getAvailableSlots(
                barber: barber,
                date: date,
                serviceDurationMinutes: service.durationMinutes,
                existingAppointments: appointments,
                shopSettings: settings,
              );

          if (slots.isEmpty) {
            // Determine reason for unavailability
            String title = 'NESSUNO SLOT';
            String message = 'Prova a selezionare un\'altra data';
            IconData icon = Icons.event_busy;
            
            if (settings.isShopClosedManually) {
              title = 'CHIUSO';
              message = 'Il salone è temporaneamente chiuso.';
              icon = Icons.door_front_door_outlined;
            } else if (settings.closures.any((c) => c.year == date.year && c.month == date.month && c.day == date.day)) {
              title = 'GIORNO FESTIVO';
              message = 'Il salone è chiuso per festività in questa data.';
              icon = Icons.celebration;
            } else if (barber.availabilityStatus == BarberAvailability.sick) {
            title = 'MALATTIA';
            message = '${barber.name} non è disponibile.';
            icon = Icons.local_hospital;
          } else if (barber.availabilityStatus == BarberAvailability.vacation || 
                     barber.unavailableDates.any((d) => d.year == date.year && d.month == date.month && d.day == date.day)) {
            title = 'IN FERIE';
            message = '${barber.name} è in ferie in questa data.';
            icon = Icons.beach_access;
          } else if (barber.daysOff.contains(date.weekday)) {
            title = 'GIORNO DI RIPOSO';
            message = '${barber.name} non lavora di ${DateFormat('EEEE', 'it').format(date)}.';
            icon = Icons.weekend;
          } else if (barber.availabilityStatus == BarberAvailability.dayOff) {
             title = 'NON DISPONIBILE';
             message = '${barber.name} non è disponibile in questa data.';
             icon = Icons.event_busy;
          }

          return Center(
            child: FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: GoogleFonts.cinzel(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  DateFormat('HH:mm').format(slot),
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
        error: (e, _) => Center(
          child: Text(
            'Errore appuntamenti: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      error: (e, _) => Center(
        child: Text(
          'Errore impostazioni: $e',
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
        return ClipOval(child: Image.asset(imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___)=>_buildInitials()));
      } else if (_decodedBytes != null) {
        return ClipOval(child: Image.memory(_decodedBytes!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___)=>_buildInitials()));
      } else if (imageUrl.startsWith('http')) {
        return ClipOval(child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___)=>_buildInitials()));
      }
    }
    
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      width: 50, height: 50, alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        color: widget.isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.1)
      ),
      child: Text(
        widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?', 
        style: GoogleFonts.cinzel(
          color: widget.isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface, 
          fontWeight: FontWeight.bold, 
          fontSize: 20
        )
      ),
    );
  }
}

class _PremiumServiceCard extends StatefulWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const _PremiumServiceCard({
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white,
            border: Border.all(
              color: widget.isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Selection highlight
                if (widget.isSelected)
                  Positioned.fill(
                    child: Container(color: Theme.of(context).colorScheme.primary.withOpacity(0.05)),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        ),
                        child: Center(
                          child: Icon(Icons.content_cut, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), size: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.service.name.toUpperCase(),
                              style: GoogleFonts.cinzel(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.service.durationMinutes} min',
                              style: GoogleFonts.montserrat(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '€${widget.service.price.toInt()}',
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (widget.isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 12, color: Theme.of(context).colorScheme.onPrimary),
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
