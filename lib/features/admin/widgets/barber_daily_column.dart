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
  static const double headerHeight = 182.0;

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
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.05),
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (Barber Info) — fixed height to align with time column
          SizedBox(
            height: headerHeight,
            child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: _getBarberImage(barber.name, barber.imageUrl),
                      onBackgroundImageError: _getBarberImage(barber.name, barber.imageUrl) != null 
                          ? (_, __) {} 
                          : null,
                      backgroundColor: const Color(0xFF1A1A1A),
                      child: barber.imageUrl.isEmpty || _getBarberImage(barber.name, barber.imageUrl) == null
                          ? Text(
                              barber.name.isNotEmpty ? barber.name[0].toUpperCase() : '?',
                              style: GoogleFonts.cinzel(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  barber.name.toUpperCase(),
                  style: GoogleFonts.cinzel(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    "BARBER",
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Builder(builder: (context) {
                  final info = _getUnavailableInfo(date);
                  return Visibility(
                    visible: info != null,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: info == null ? const SizedBox(height: 20) : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(info.icon, size: 9, color: info.color),
                        const SizedBox(width: 3),
                        Text(
                          info.label,
                          style: GoogleFonts.montserrat(
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            color: info.color,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          ),

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
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
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
                          color: Colors.white.withValues(alpha: 0.03),
                          border: Border.symmetric(
                            horizontal: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
                          ),
                        ),
                        child: ClipRect(
                          child: CustomPaint(
                            painter: DiagonalStripesPainter(color: Colors.white.withValues(alpha: 0.05)),
                            child: Center(
                              child: Text('PAUSA',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Unavailability overlay — colore + icona + label centrati, niente conflitti
                  Builder(builder: (context) {
                    final info = _getUnavailableInfo(date);
                    if (info == null) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: Container(
                        color: info.color.withValues(alpha: 0.07),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(info.icon, size: 26, color: info.color.withValues(alpha: 0.45)),
                            const SizedBox(height: 10),
                            Text(
                              info.label,
                              style: GoogleFonts.montserrat(
                                color: info.color.withValues(alpha: 0.55),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

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
                      left: 2,
                      right: 2,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                                                color: Colors.white.withValues(alpha: 0.7)),
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
        return const Color(0xFF1B4332); // Deep Emerald
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

class DiagonalStripesPainter extends CustomPainter {
  final Color color;
  final double stripeWidth;
  final double gap;

  DiagonalStripesPainter({
    required this.color,
    this.stripeWidth = 2,
    this.gap = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stripeWidth;

    for (double i = -size.height; i < size.width; i += gap) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
