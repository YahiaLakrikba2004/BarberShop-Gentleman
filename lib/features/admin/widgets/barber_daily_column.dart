import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
    
    // Filter appointments for this barber (redundant if parent does it, but safer)
    final myAppointments = appointments.where((a) => a.barberId == barber.id).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.05),
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header (Barber Info)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 30, // Larger size
                    backgroundImage: _getBarberImage(barber.name, barber.imageUrl),
                    onBackgroundImageError: _getBarberImage(barber.name, barber.imageUrl) != null 
                        ? (_, __) {} 
                        : null,
                    backgroundColor: const Color(0xFF1E1E1E),
                    child: barber.imageUrl.isEmpty || _getBarberImage(barber.name, barber.imageUrl) == null
                        ? Text(
                            barber.name.isNotEmpty ? barber.name[0].toUpperCase() : '?',
                            style: GoogleFonts.cinzel(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  barber.name.toUpperCase(),
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "BARBER",
                    style: GoogleFonts.montserrat(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),


          // Timeline
          Container(
             height: (endHour - startHour) * hourHeight, // Fixed total height
             child: Stack(
                children: [
                  // Grid Lines (Hours)
                  Column(
                    children: List.generate(endHour - startHour, (index) {
                      final hour = startHour + index;
                      return Container(
                        height: hourHeight,
                        decoration: BoxDecoration(
                          border: Border(
                             // Use dashed line logic or just very subtle divider
                            top: BorderSide( 
                              color: Theme.of(context).dividerColor.withOpacity(0.08), 
                              width: 1,
                            ),
                          ),
                        ),
                        // Small hour indicator inside the column for reference? 
                        // Maybe too cluttered. Let's stick to clean lines.
                      );
                    }),
                  ),

                  // Appointments Overlay
                  if (myAppointments.isEmpty)
                    // "No Appointments" watermark?
                    const SizedBox()
                  else
                  ...myAppointments.map((apt) {
                    final start = apt.date;
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
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                            // Premium Gradient
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                statusColor,
                                Color.lerp(statusColor, Colors.black, 0.3)!, // Darken slightly at bottom
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Accent Line on left (Gold for aesthetics if desired, but keep simple)
                              // actually, let's make the accent line slightly brighter than the bg
                              Positioned(
                                left: 0, 
                                top: 0, 
                                bottom: 0, 
                                width: 2, 
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                    )
                                  ),
                                )
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0, top: 4.0, right: 4.0, bottom: 2.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      apt.customerName,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 2),
                                        ]
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (height > 35) 
                                      Text(
                                        apt.serviceName,
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white70,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (height > 50)
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.bottomRight,
                                          child: Text(
                                            "${apt.durationMinutes} min",
                                            style: const TextStyle(
                                              fontSize: 8,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
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

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return const Color(0xFF2E5E2F); // Premium Hunter Green
      case AppointmentStatus.pending:
        return const Color(0xFFB8860B); // Dark Goldenrod
      case AppointmentStatus.completed:
        return const Color(0xFF424242); // Graphite
      case AppointmentStatus.cancelled:
        return const Color(0xFF8B0000); // Dark Red
      default:
        return const Color(0xFF1A237E); // Deep Indigo
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
