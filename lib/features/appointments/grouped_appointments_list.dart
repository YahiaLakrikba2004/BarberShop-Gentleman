import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/appointment_model.dart';

class GroupedAppointmentsList extends StatefulWidget {
  final List<AppointmentModel> appointments;
  final Function(AppointmentModel) onAppointmentTap;
  final Function(AppointmentModel)? onAppointmentCancel;
  final bool showBarber;
  final bool initiallyExpanded;
  /// Number of day-groups shown per page. Defaults to 10.
  final int pageSize;

  const GroupedAppointmentsList({
    super.key,
    required this.appointments,
    required this.onAppointmentTap,
    this.onAppointmentCancel,
    this.showBarber = false,
    this.initiallyExpanded = false,
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
              initiallyExpanded: widget.initiallyExpanded,
              tilePadding: const EdgeInsets.all(16),
              childrenPadding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              title: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('d').format(date),
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('MMM', 'it').format(date).toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Status accent bar
                          Container(
                            width: 4,
                            color: _statusColor(apt.status),
                          ),
                          // Card content
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => widget.onAppointmentTap(apt),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Time
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('HH:mm').format(apt.date),
                                            style: GoogleFonts.cinzel(
                                              color: Colors.white,
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${apt.durationMinutes} min',
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white.withValues(alpha: 0.4),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),
                                      Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
                                      const SizedBox(width: 14),
                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  widget.showBarber ? Icons.content_cut : Icons.person_outline,
                                                  size: 12,
                                                  color: _statusColor(apt.status).withValues(alpha: 0.8),
                                                ),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    widget.showBarber ? apt.barberName : apt.customerName,
                                                    style: GoogleFonts.cinzel(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    apt.serviceName,
                                                    style: GoogleFonts.montserrat(
                                                      color: Colors.white.withValues(alpha: 0.55),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                if (apt.source == 'web')
                                                  Container(
                                                    margin: const EdgeInsets.only(right: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blueAccent.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                                                    ),
                                                    child: Text('WEB', style: GoogleFonts.montserrat(fontSize: 9, color: Colors.blueAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                                  ),
                                                _StatusBadge(apt.status),
                                              ],
                                            ),
                                            if (!widget.showBarber && apt.customerPhoneNumber != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.phone_android, size: 11, color: Colors.white.withValues(alpha: 0.3)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    apt.customerPhoneNumber!,
                                                    style: GoogleFonts.montserrat(
                                                      color: Colors.white.withValues(alpha: 0.3),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      // Cancel button
                                      if (widget.onAppointmentCancel != null)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: InkWell(
                                            onTap: () => widget.onAppointmentCancel!(apt),
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent.withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(Icons.close, color: Colors.redAccent.withValues(alpha: 0.8), size: 16),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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


Color _statusColor(AppointmentStatus status) => switch (status) {
  AppointmentStatus.pending   => const Color(0xFFFFB300),
  AppointmentStatus.confirmed => const Color(0xFF4CAF50),
  AppointmentStatus.completed => const Color(0xFF9E9E9E),
  AppointmentStatus.cancelled => const Color(0xFFDC143C),
  AppointmentStatus.noShow    => Colors.purpleAccent,
};

class _StatusBadge extends StatelessWidget {
  final AppointmentStatus status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      AppointmentStatus.pending    => ('IN ATTESA',       const Color(0xFF2A1F00), const Color(0xFFFFB300)),
      AppointmentStatus.confirmed  => ('CONFERMATO',      const Color(0xFF0A2A1A), const Color(0xFF4CAF50)),
      AppointmentStatus.completed  => ('COMPLETATO',      const Color(0xFF1A1A1A), const Color(0xFF9E9E9E)),
      AppointmentStatus.cancelled  => ('ANNULLATO',       const Color(0xFF2A0A0A), const Color(0xFFDC143C)),
      AppointmentStatus.noShow     => ('NON PRESENTATO',  const Color(0xFF1A0A2A), Colors.purpleAccent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg.withValues(alpha: 0.9),
          letterSpacing: 0.5,
        ),
      ),
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
