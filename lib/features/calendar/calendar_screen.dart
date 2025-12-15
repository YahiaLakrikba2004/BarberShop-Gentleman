import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart'; // Added
import '../../models/appointment_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

enum CalendarViewType { day, week, month }

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final EventController _eventController = EventController();
  final GlobalKey<WeekViewState> _weekViewKey = GlobalKey<WeekViewState>();
  final GlobalKey<DayViewState> _dayViewKey = GlobalKey<DayViewState>();
  final GlobalKey<MonthViewState> _monthViewKey = GlobalKey<MonthViewState>();
  CalendarViewType _currentView = CalendarViewType.week;
  DateTime _focusedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      // Custom body with gradient background
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1F1F1F),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'I MIEI APPUNTAMENTI',
                  style: GoogleFonts.cinzel(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              Expanded(
                child: userAsync.when(
                  data: (user) {
                    if (user == null) {
                      return Center(
                        child: Text(
                          'Effettua il login per vedere gli appuntamenti',
                          style: GoogleFonts.montserrat(color: Colors.white70),
                        ),
                      );
                    }
                    return _buildCalendarView(user);
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Errore: $err',
                      style: const TextStyle(color: Colors.red),
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

  Widget _buildCalendarView(UserModel user) {
    final allAppointmentsAsync = user.role == UserRole.client
        ? ref.watch(userAppointmentsProvider(user.id))
        : user.role == UserRole.admin
            ? ref.watch(allAppointmentsProvider)
            : ref.watch(allBarberAppointmentsProvider(user.id));

    return allAppointmentsAsync.when(
      data: (allAppointments) {
        // Convert to CalendarEventData
        final events = allAppointments
            .where((apt) => apt.status != AppointmentStatus.cancelled)
            .map((apt) {
          return CalendarEventData<AppointmentModel>(
            title: apt.customerName,
            description: '${apt.serviceName}\n${apt.customerPhoneNumber ?? ""}',
            date: apt.date,
            startTime: apt.date,
            endTime: apt.endTime,
            color: const Color(0xFFFFFFFF),
            event: apt,
          );
        }).toList();

        // Add events to controller
        _eventController.removeWhere((event) => true);
        _eventController.addAll(events);

        return FadeInUp( // Add Animation
          duration: const Duration(milliseconds: 600),
          child: CalendarControllerProvider(
            controller: _eventController,
            child: Column(
              children: [
                // View selector buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _ViewSelectorButton(
                            title: 'Giorno',
                            icon: Icons.view_day_outlined,
                            isSelected: _currentView == CalendarViewType.day,
                            onTap: () => setState(() => _currentView = CalendarViewType.day),
                          ),
                        ),
                        Expanded(
                          child: _ViewSelectorButton(
                            title: 'Settimana',
                            icon: Icons.calendar_view_week_outlined,
                            isSelected: _currentView == CalendarViewType.week,
                            onTap: () => setState(() => _currentView = CalendarViewType.week),
                          ),
                        ),
                        Expanded(
                          child: _ViewSelectorButton(
                            title: 'Mese',
                            icon: Icons.calendar_month_outlined,
                            isSelected: _currentView == CalendarViewType.month,
                            onTap: () => setState(() => _currentView = CalendarViewType.month),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _currentView == CalendarViewType.day
                      ? DayView(
                          key: _dayViewKey,
                          controller: _eventController,
                          initialDay: _focusedDate,
                          onPageChange: (date, page) => _focusedDate = date,
                          backgroundColor: const Color(0xFF0A0A0A),
                          headerStyle: HeaderStyle(
                            decoration: const BoxDecoration(
                              color: Color(0xFF0A0A0A),
                            ),
                            headerTextStyle: GoogleFonts.cinzel(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          dateStringBuilder: (date, {secondaryDate}) {
                            return DateFormat('d MMMM yyyy', 'it').format(date).toUpperCase();
                          },
                          dayTitleBuilder: (date) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              color: const Color(0xFF0A0A0A),
                              child: Center(
                                child: Text(
                                  DateFormat('EEEE d', 'it')
                                      .format(date)
                                      .toUpperCase(),
                                  style: GoogleFonts.cinzel(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            );
                          },
                          timeLineBuilder: (date) {
                            return Container(
                              padding: const EdgeInsets.only(right: 12),
                              alignment: Alignment.centerRight,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Hour label
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        DateFormat('HH:mm').format(date),
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Half-hour label (manually added)
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        DateFormat('HH:mm').format(date.add(
                                            const Duration(minutes: 30))),
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          minuteSlotSize: MinuteSlotSize.minutes30,
                          heightPerMinute: 2.0,
                          hourIndicatorSettings: HourIndicatorSettings(
                            color: Colors.white.withOpacity(0.1),
                            height: 1,
                            offset: 0,
                          ),
                          liveTimeIndicatorSettings:
                              const LiveTimeIndicatorSettings(
                            color: Colors.white,
                            height: 2,
                            showTime: false,
                            showBullet: true,
                          ),
                          onEventTap: (events, date) {
                            if (events.isNotEmpty) {
                              _showAppointmentDetails(context, events.first);
                            }
                          },
                          eventTileBuilder:
                              (date, events, boundary, start, end) {
                            if (events.isEmpty) return const SizedBox();
                            final event = events.first;
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 2, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  if (constraints.maxHeight < 20) {
                                    return const SizedBox();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Title
                                        Text(
                                          event.title.toUpperCase(),
                                          style: GoogleFonts.cinzel(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        // Show time if height allows (> 40)
                                        if (constraints.maxHeight > 40)
                                          Text(
                                            '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
                                            style: GoogleFonts.montserrat(
                                              color: Colors.black54,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        // Show description if height allows (> 50)
                                        if (constraints.maxHeight > 50)
                                          Expanded(
                                            child: Text(
                                              event.description
                                                      ?.split('\n')
                                                      .first ??
                                                  '',
                                              style: GoogleFonts.montserrat(
                                                color: Colors.black87,
                                                fontSize: 10,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          startHour: 8,
                          endHour: 22,
                          showLiveTimeLineInAllDays: true,
                        )
                      : _currentView == CalendarViewType.month
                          ? MonthView(
                              key: _monthViewKey,
                              controller: _eventController,
                              initialMonth: _focusedDate,
                              borderColor: Colors.white.withOpacity(0.05),
                              headerStyle: HeaderStyle(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0A0A0A),
                                ),
                                headerTextStyle: GoogleFonts.cinzel(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              headerBuilder: (date) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 24),
                                  color: const Color(0xFF0A0A0A),
                                  child: Row(
                                    children: [
                                      Text(
                                        DateFormat('MMMM yyyy', 'it')
                                            .format(date)
                                            .toUpperCase(),
                                        style: GoogleFonts.cinzel(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left,
                                            color: Colors.white),
                                        onPressed: () => _monthViewKey
                                            .currentState
                                            ?.previousPage(),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right,
                                            color: Colors.white),
                                        onPressed: () => _monthViewKey
                                            .currentState
                                            ?.nextPage(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              weekDayBuilder: (day) {
                                return Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  color: const Color(0xFF0A0A0A),
                                  child: Center(
                                    child: Text(
                                      [
                                        'LUN',
                                        'MAR',
                                        'MER',
                                        'GIO',
                                        'VEN',
                                        'SAB',
                                        'DOM'
                                      ][day],
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              cellBuilder: (date, events, isToday, isInMonth,
                                  hideDaysNotInMonth) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _currentView = CalendarViewType.day;
                                      _focusedDate = date;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A0A0A),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          alignment: Alignment.topCenter,
                                          child: Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: isToday
                                                  ? const Color(0xFFFFFFFF)
                                                  : Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${date.day}',
                                              style: GoogleFonts.montserrat(
                                                color: isToday
                                                    ? Colors.black
                                                    : (isInMonth
                                                        ? Colors.white
                                                        : Colors.white24),
                                                fontWeight: isToday
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (events.isNotEmpty)
                                          Expanded(
                                            child: Center(
                                              child: Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                alignment: WrapAlignment.center,
                                                children:
                                                    events.take(4).map((event) {
                                                  return Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0xFFFFFFFF),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              onPageChange: (date, pageIndex) =>
                                  _focusedDate = date,
                              onEventTap: (event, date) {
                                _showAppointmentDetails(context, event);
                              },
                            )
                          : WeekView(
                              key: _weekViewKey,
                              controller: _eventController,
                              initialDay: _focusedDate,
                              onPageChange: (date, page) => _focusedDate = date,
                              backgroundColor: const Color(0xFF0A0A0A),
                              headerStyle: HeaderStyle(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0A0A0A),
                                ),
                                headerTextStyle: GoogleFonts.cinzel(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              weekTitleHeight: 70,
                              weekPageHeaderBuilder: (startDate, endDate) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 24),
                                  color: const Color(0xFF0A0A0A),
                                  child: Row(
                                    children: [
                                      Text(
                                        DateFormat('MMMM yyyy', 'it')
                                            .format(startDate)
                                            .toUpperCase(),
                                        style: GoogleFonts.cinzel(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left,
                                            color: Colors.white),
                                        onPressed: () => _weekViewKey
                                            .currentState
                                            ?.previousPage(),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right,
                                            color: Colors.white),
                                        onPressed: () => _weekViewKey
                                            .currentState
                                            ?.nextPage(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              weekDayBuilder: (date) {
                                final isToday =
                                    date.day == DateTime.now().day &&
                                        date.month == DateTime.now().month &&
                                        date.year == DateTime.now().year;

                                return Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A0A0A),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('EEE', 'it')
                                            .format(date)
                                            .toUpperCase(),
                                        style: GoogleFonts.montserrat(
                                          color: isToday
                                              ? const Color(0xFFFFFFFF)
                                              : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? const Color(0xFFFFFFFF)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${date.day}',
                                          style: GoogleFonts.montserrat(
                                            color: isToday
                                                ? Colors.black
                                                : Colors.white,
                                            fontSize: 22,
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              timeLineBuilder: (date) {
                                return Container(
                                  padding: const EdgeInsets.only(right: 12),
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    DateFormat('H a').format(date),
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                              hourIndicatorSettings: HourIndicatorSettings(
                                color: Colors.white.withOpacity(0.1),
                                height: 1,
                                offset: 0,
                              ),
                              liveTimeIndicatorSettings:
                                  const LiveTimeIndicatorSettings(
                                color: Colors.white,
                                height: 2,
                                showTime: false,
                                showBullet: true,
                              ),
                              onEventTap: (events, date) {
                                if (events.isNotEmpty) {
                                  _showAppointmentDetails(
                                      context, events.first);
                                }
                              },
                              eventTileBuilder:
                                  (date, events, boundary, start, end) {
                                if (events.isEmpty) return const SizedBox();

                                final event = events.first;

                                // Handle very small events
                                if (boundary.height < 15) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 2, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 1),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          event.title.toUpperCase(),
                                          style: GoogleFonts.cinzel(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (boundary.height > 22)
                                          Text(
                                            '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
                                            style: GoogleFonts.montserrat(
                                              color: Colors.black87,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              heightPerMinute: 1.5,
                              startHour: 8,
                              endHour: 22,
                              showLiveTimeLineInAllDays: true,
                              scrollOffset: 0,
                            ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
        ),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Errore: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, CalendarEventData event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111), // Darker background
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.cinzel(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente',
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.cut_outlined, 'Servizio',
                event.description?.split('\n').first ?? 'N/A'),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.access_time, 'Orario',
                '${DateFormat('HH:mm').format(event.startTime!)} - ${DateFormat('HH:mm').format(event.endTime!)}'),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today_outlined, 'Data',
                DateFormat('EEEE d MMMM yyyy', 'it').format(event.date)),
            if (event.description != null &&
                event.description!.contains('\n')) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                  Icons.phone_outlined, 'Telefono', event.description!.split('\n').last),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCancelDialog(
                          context, event.event as AppointmentModel);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'ANNULLA',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'CHIUDI',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showCancelDialog(
      BuildContext context, AppointmentModel appointment) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: Text(
          'ANNULLA APPUNTAMENTO',
          style: GoogleFonts.cinzel(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Sei sicuro di voler annullare l\'appuntamento di ${appointment.customerName}?\nL\'operazione non può essere annullata.',
          style: GoogleFonts.montserrat(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'NO, MANTIENI',
              style: GoogleFonts.montserrat(
                color: Colors.white38,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(firestoreServiceProvider)
                    .updateAppointmentStatus(
                        appointment.id, AppointmentStatus.cancelled);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Appuntamento annullato con successo')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Errore: $e')),
                  );
                }
              }
            },
            child: Text(
              'SÌ, ANNULLA',
              style: GoogleFonts.montserrat(
                color: Colors.red, // Keep red for destructive action warning
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewSelectorButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewSelectorButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white54,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.montserrat(
                color: isSelected ? Colors.black : Colors.white54,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

