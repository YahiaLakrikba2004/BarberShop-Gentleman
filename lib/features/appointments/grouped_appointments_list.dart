import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/appointment_model.dart';

class GroupedAppointmentsList extends StatefulWidget {
  final List<AppointmentModel> appointments;
  final Function(AppointmentModel) onAppointmentTap;
  final Function(AppointmentModel)? onAppointmentCancel;
  final bool showBarber;
  /// Number of day-groups shown per page. Defaults to 10.
  final int pageSize;

  const GroupedAppointmentsList({
    super.key,
    required this.appointments,
    required this.onAppointmentTap,
    this.onAppointmentCancel,
    this.showBarber = false,
    this.pageSize = 10,
  });

  @override
  State<GroupedAppointmentsList> createState() =>
      _GroupedAppointmentsListState();
}

class _GroupedAppointmentsListState extends State<GroupedAppointmentsList> {
  int _visibleGroups = 0;

  @override
  void initState() {
    super.initState();
    _visibleGroups = widget.pageSize;
  }

  @override
  void didUpdateWidget(GroupedAppointmentsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset pagination when the list changes (e.g. filter change)
    if (oldWidget.appointments != widget.appointments) {
      _visibleGroups = widget.pageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group by date
    final Map<DateTime, List<AppointmentModel>> grouped = {};
    for (var apt in widget.appointments) {
      final date = DateTime(apt.date.year, apt.date.month, apt.date.day);
      grouped.putIfAbsent(date, () => []).add(apt);
    }

    final sortedDates = grouped.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return const Center(
        child: Text(
          'Nessun appuntamento trovato',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final visibleDates = sortedDates.take(_visibleGroups).toList();
    final remaining = sortedDates.length - visibleDates.length;
    final hasMore = remaining > 0;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visibleDates.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == visibleDates.length) {
          return _LoadMoreButton(
            remaining: remaining,
            pageSize: widget.pageSize,
            onTap: () => setState(() => _visibleGroups += widget.pageSize),
          );
        }

        final date = visibleDates[index];
        final dayAppointments = grouped[date]!;
        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday
                  ? const Color(0xFFFFFFFF)
                  : Colors.white.withValues(alpha: 0.1),
              width: isToday ? 1 : 0.5,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.all(16),
              childrenPadding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              title: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('d').format(date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM', 'it').format(date).toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE', 'it').format(date).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dayAppointments.length} appuntament${dayAppointments.length == 1 ? "o" : "i"}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              children: dayAppointments.map((apt) {
                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onAppointmentTap(apt),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Time Column (Left Side)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(apt.date),
                                  style: GoogleFonts.cinzel(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${apt.durationMinutes} min',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),

                            // Divider
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            const SizedBox(width: 16),

                            // 2. Main Info (Center)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        widget.showBarber
                                            ? Icons.content_cut
                                            : Icons.person_outline,
                                        size: 14,
                                        color:
                                            Colors.white.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          widget.showBarber
                                              ? apt.barberName
                                              : apt.customerName,
                                          style: GoogleFonts.cinzel(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    apt.serviceName,
                                    style: GoogleFonts.montserrat(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (apt.customerPhoneNumber != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_android,
                                            size: 12,
                                            color: Colors.white
                                                .withValues(alpha: 0.4)),
                                        const SizedBox(width: 4),
                                        Text(
                                          apt.customerPhoneNumber!,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white
                                                .withValues(alpha: 0.4),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // 3. Actions (Right Side)
                            if (widget.onAppointmentCancel != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: InkWell(
                                  onTap: () =>
                                      widget.onAppointmentCancel!(apt),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.redAccent
                                          .withValues(alpha: 0.8),
                                      size: 18,
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
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final int remaining;
  final int pageSize;
  final VoidCallback onTap;

  const _LoadMoreButton({
    required this.remaining,
    required this.pageSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final toLoad = remaining.clamp(0, pageSize);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.expand_more,
                  size: 18, color: Colors.white.withValues(alpha: 0.5)),
              const SizedBox(width: 8),
              Text(
                'Carica altri $toLoad giorni  ($remaining rimanenti)',
                style: GoogleFonts.montserrat(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
