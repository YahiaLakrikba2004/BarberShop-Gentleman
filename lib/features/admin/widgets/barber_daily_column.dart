import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../../models/barber_model.dart';
import '../../../models/appointment_model.dart';

class BarberDailyColumn extends StatelessWidget {
  final BarberModel barber;
  final DateTime date;
  final List<AppointmentModel> appointments;
  final Function(AppointmentModel) onAppointmentTap;
  final double hourHeight; // Height for each hour slot
  final int startHour; // Shop opening hour
  final int endHour; // Shop closing hour

  // Fixed header height used to align the time column in TeamAgendaScreen.
  // Keep in sync with the actual header content below.
  static const double headerHeight = 150.0;
  static const double headerGap = 10.0;

  const BarberDailyColumn({
    super.key,
    required this.barber,
    required this.date,
    required this.appointments,
    required this.onAppointmentTap,
    this.hourHeight = 60.0,
    this.startHour = 9,
    this.endHour = 20,
  });

  @override
  Widget build(BuildContext context) {
    // Check if barber is working today
    // Note: checking generic availability. specific date checks should be done in parent or here.
    // simpler to just render the column and show "OFF" if needed overlay
    
    // Filter appointments for this barber and exclude cancelled/no-shows
    final myAppointments = appointments.where((a) =>
      a.barberId == barber.id &&
      a.status != AppointmentStatus.cancelled &&
      a.status != AppointmentStatus.noShow
    ).toList();

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFF1E1E1E), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (Barber Info) — fixed height to align with time column
          SizedBox(
            height: headerHeight,
            child: Builder(builder: (context) {
              final info = _getUnavailableInfo(date);
              final image = _getBarberImage(barber.name, barber.imageUrl);
              return ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Photo background
                    image != null
                        ? (info != null
                            ? ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0.2126, 0.7152, 0.0722, 0, 0,
                                  0,      0,      0,      0.5, 0,
                                ]),
                                child: Image(image: image, fit: BoxFit.cover),
                              )
                            : Image(image: image, fit: BoxFit.cover))
                        : Container(
                            color: const Color(0xFF1A1A1A),
                            child: Center(
                              child: Text(
                                barber.name.isNotEmpty ? barber.name[0].toUpperCase() : '?',
                                style: GoogleFonts.cinzel(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                          ),

                    // Top vignette
                    const Positioned(
                      top: 0, left: 0, right: 0, height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xAA0A0A0A), Colors.transparent],
                          ),
                        ),
                      ),
                    ),

                    // Bottom gradient — name area
                    const Positioned(
                      bottom: 0, left: 0, right: 0, height: 90,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xF00A0A0A)],
                          ),
                        ),
                      ),
                    ),

                    // Unavailability overlay (rendered before name so name stays on top)
                    if (info != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.72),
                          child: Align(
                            alignment: const Alignment(0, -0.2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: info.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: info.color.withValues(alpha: 0.5),
                                  width: 0.8,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(info.icon, color: info.color, size: 18),
                                  const SizedBox(height: 4),
                                  Text(
                                    info.label,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w800,
                                      color: info.color,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Name at bottom — always on top so visible even when unavailable
                    Positioned(
                      bottom: 11, left: 6, right: 6,
                      child: Text(
                        barber.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: info != null
                              ? Colors.white.withValues(alpha: 0.55)
                              : Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.9),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: headerGap),

          // Timeline
          SizedBox(
             height: (endHour - startHour) * hourHeight, // Fixed total height
             child: Stack(
                children: [
                  // Grid Lines (Hours)
                  Column(
                    children: List.generate(endHour - startHour, (index) {
                      return Container(
                        height: hourHeight,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFF282828),
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  // Break / Pausa overlay — solo se il barbiere è disponibile
                  Builder(builder: (context) {
                    if (_getUnavailableInfo(date) != null) return const SizedBox.shrink();
                    if (!barber.hasBreakOn(date.weekday)) return const SizedBox.shrink();
                    final br = barber.breakForDay(date.weekday);
                    final top = ((br[0] * 60 + br[1]) - startHour * 60) / 60 * hourHeight;
                    final height = ((br[2] * 60 + br[3]) - (br[0] * 60 + br[1])) / 60 * hourHeight;
                    return Positioned(
                      top: top, left: 0, right: 0, height: height,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border(
                            left: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 2),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.coffee_rounded,
                                size: 11,
                                color: Colors.white.withValues(alpha: 0.30)),
                              const SizedBox(width: 5),
                              Text('PAUSA',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withValues(alpha: 0.30),
                                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Unavailability overlay — tinta appena percettibile, info già nell'header
                  if (_getUnavailableInfo(date) != null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.02),
                      ),
                    ),

                  // Appointments Overlay
                  if (myAppointments.isEmpty)
                    // "No Appointments" watermark?
                    const SizedBox()
                  else
                  ...myAppointments.map((apt) {
                    // Calculate offset from startHour
                    final startOfDay = DateTime(apt.date.year, apt.date.month, apt.date.day, startHour);
                    final durationSinceStart = apt.date.difference(startOfDay).inMinutes;

                    // Skip if before shop opening
                    if (durationSinceStart < 0) return const SizedBox(); 

                    final topOffset = (durationSinceStart / 60) * hourHeight;
                    final durationMinutes = apt.durationMinutes > 0 ? apt.durationMinutes : 30; 
                    final height = (durationMinutes / 60) * hourHeight;
                    
                    // Prevent overflow if goes beyond endHour
                    final maxMinutes = (endHour - startHour) * 60;
                    if (topOffset >= maxMinutes * hourHeight) return const SizedBox();

                    final statusColor = _getStatusColor(apt.status);

                    return Positioned(
                      top: topOffset,
                      left: 4,
                      right: 4,
                      height: height > 0 ? height : 30, // Safety height
                      child: GestureDetector(
                        onTap: () => onAppointmentTap(apt),
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 4, 
                            vertical: height <= 40 ? 0.25 : 1.0,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                statusColor.withValues(alpha: 0.9),
                                statusColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(height <= 40 ? 8 : 12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: height <= 40 ? 2 : 6,
                                offset: Offset(0, height <= 40 ? 1 : 3),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 0.8,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(height <= 40 ? 8 : 12),
                            child: Stack(
                              children: [
                                // Hide shine on very short slots to save rendering complexity
                                if (height > 40)
                                  Positioned(
                                    top: -20,
                                    right: -20,
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.05),
                                      ),
                                    ),
                                  ),
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Nome + forbici
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              apt.customerName,
                                              style: GoogleFonts.montserrat(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.content_cut, size: 9,
                                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85)),
                                          ],
                                        ),
                                        // Servizio
                                        Text(
                                          apt.serviceName.toUpperCase(),
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        if (height > 70) ...[
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              "${apt.durationMinutes} MIN",
                                              style: GoogleFonts.montserrat(
                                                fontSize: 8,
                                                color: Colors.white.withValues(alpha: 0.8),
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
          ),
        ],
      ),
    );
  }

  /// Returns (label, color, icon) if barber is unavailable on [date], else null.
  ({String label, Color color, IconData icon})? _getUnavailableInfo(DateTime date) {
    // 1. Specific unavailable date
    final isUnavailableDate = barber.unavailableDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
    if (isUnavailableDate) {
      return (label: 'NON DISPONIBILE', color: const Color(0xFF757575), icon: Icons.event_busy_outlined);
    }
    // 2. Day off (weekly rest)
    if (barber.daysOff.contains(date.weekday)) {
      return (label: 'RIPOSO', color: const Color(0xFF757575), icon: Icons.bed_outlined);
    }
    // 3. Availability status
    switch (barber.availabilityStatus) {
      case BarberAvailability.sick:
        return (label: 'MALATTIA', color: const Color(0xFFE53935), icon: Icons.medical_services_outlined);
      case BarberAvailability.vacation:
        return (label: 'IN FERIE', color: const Color(0xFF1565C0), icon: Icons.beach_access_outlined);
      case BarberAvailability.dayOff:
        return (label: 'RIPOSO', color: const Color(0xFF757575), icon: Icons.bed_outlined);
      case BarberAvailability.absence:
        return (label: 'ASSENZA', color: const Color(0xFFE65100), icon: Icons.person_off_outlined);
      case BarberAvailability.available:
        return null;
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return const Color(0xFF1A6B40); // Vibrant Emerald
      case AppointmentStatus.pending:
        return const Color(0xFF9E6B08); // Golden Ochre
      case AppointmentStatus.completed:
        return const Color(0xFF2B2B2B); // Rich Graphite
      case AppointmentStatus.cancelled:
        return const Color(0xFF7A0909); // Deep Crimson
      case AppointmentStatus.noShow:
        return const Color(0xFF4A0A4A); // Deep Purple
    }
  }

  ImageProvider? _getBarberImage(String name, String imageUrl) {
    // 1. Check for specific hardcoded names (Only for ones we KNOW exist locally)
    final lowerName = name.toLowerCase();
    
    // Only map these two if we know the assets actually exist
    if (lowerName.contains('omar') || lowerName.contains('marco')) {
       return const AssetImage('assets/images/barber_marco.png');
    } else if (lowerName.contains('brombei') || lowerName.contains('giuseppe')) {
       return const AssetImage('assets/images/barber_giuseppe.png');
    }

    // 2. Check content of URL
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return NetworkImage(imageUrl);
      } else if (imageUrl.startsWith('assets/')) {
        return AssetImage(imageUrl);
      } else {
        // Try Base64
        try {
          // Check if it looks like base64 (no spaces, length multiple of 4 roughly)
           if (imageUrl.length > 100) {
             return MemoryImage(base64Decode(imageUrl));
           }
        } catch (_) {
          // ignore error
        }
      }
    }
   
    // 3. No image
    return null;
  }
}
