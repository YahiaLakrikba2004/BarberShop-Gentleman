import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
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
      appBar: AppBar(
        title: const Text('I MIEI APPUNTAMENTI', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'Effettua il login per vedere i tuoi appuntamenti',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return _buildCalendarView(user);
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
        final events = allAppointments.where((apt) => apt.status != AppointmentStatus.cancelled).map((apt) {
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

        return FadeIn(
          child: CalendarControllerProvider(
            controller: _eventController,
            child: Column(
              children: [
                // View selector buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFFFFFFFF).withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ViewSelectorButton(
                        title: 'Giorno',
                        icon: Icons.view_day,
                        isSelected: _currentView == CalendarViewType.day,
                        onTap: () => setState(() => _currentView = CalendarViewType.day),
                      ),
                      _ViewSelectorButton(
                        title: 'Settimana',
                        icon: Icons.view_week,
                        isSelected: _currentView == CalendarViewType.week,
                        onTap: () => setState(() => _currentView = CalendarViewType.week),
                      ),
                      _ViewSelectorButton(
                        title: 'Mese',
                        icon: Icons.calendar_month,
                        isSelected: _currentView == CalendarViewType.month,
                        onTap: () => setState(() => _currentView = CalendarViewType.month),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _currentView == CalendarViewType.day
                      ? DayView(
                          key: _dayViewKey,
                          controller: _eventController,
                          initialDay: _focusedDate,
                          onPageChange: (date, page) => _focusedDate = date,
                          backgroundColor: const Color(0xFF181818),
                          headerStyle: HeaderStyle(
                            decoration: BoxDecoration(
                              color: const Color(0xFF181818),
                            ),
                            headerTextStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          dateStringBuilder: (date, {secondaryDate}) {
                            return DateFormat('d MMMM yyyy', 'it').format(date);
                          },
                          dayTitleBuilder: (date) {
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              color: const Color(0xFF181818),
                              child: Center(
                                child: Text(
                                  DateFormat('EEEE d MMMM', 'it').format(date).toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFFFFFFF),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                          timeLineBuilder: (date) {
                            return Container(
                              padding: const EdgeInsets.only(right: 12),
                              alignment: Alignment.centerRight,
                              child: Text(
                                DateFormat('H a').format(date),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            );
                          },
                          hourIndicatorSettings: HourIndicatorSettings(
                            color: Colors.white.withOpacity(0.1),
                            height: 1,
                            offset: 0,
                          ),
                          liveTimeIndicatorSettings: const LiveTimeIndicatorSettings(
                            color: Color(0xFFEA4335),
                            height: 2,
                            showTime: true,
                            showBullet: true,
                          ),
                          onEventTap: (events, date) {
                            if (events.isNotEmpty) {
                              _showAppointmentDetails(context, events.first);
                            }
                          },
                          eventTileBuilder: (date, events, boundary, start, end) {
                            if (events.isEmpty) return const SizedBox();
                            final event = events.first;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      event.title,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        event.description?.split('\n').first ?? '',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
                        )
                      : _currentView == CalendarViewType.month
                          ? MonthView(
                              key: _monthViewKey,
                              controller: _eventController,
                              initialMonth: _focusedDate,
                              borderColor: Colors.white.withOpacity(0.1),
                              headerStyle: HeaderStyle(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF181818),
                                ),
                                headerTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              headerBuilder: (date) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  color: const Color(0xFF181818),
                                  child: Row(
                                    children: [
                                      Text(
                                        DateFormat('MMMM yyyy', 'it').format(date).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                                        onPressed: () => _monthViewKey.currentState?.previousPage(),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                                        onPressed: () => _monthViewKey.currentState?.nextPage(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              weekDayBuilder: (day) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  color: const Color(0xFF181818),
                                  child: Center(
                                    child: Text(
                                      ['LUN', 'MAR', 'MER', 'GIO', 'VEN', 'SAB', 'DOM'][day],
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _currentView = CalendarViewType.day;
                                      _focusedDate = date;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF181818),
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
                                              color: isToday ? const Color(0xFFFFFFFF) : Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${date.day}',
                                              style: TextStyle(
                                                color: isToday ? Colors.black : (isInMonth ? Colors.white : Colors.white24),
                                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
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
                                                children: events.take(4).map((event) {
                                                  return Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: const BoxDecoration(
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
                              onPageChange: (date, pageIndex) => _focusedDate = date,
                              onEventTap: (event, date) {
                                _showAppointmentDetails(context, event);
                              },
                            )
                          : WeekView(
                              key: _weekViewKey,
                              controller: _eventController,
                              initialDay: _focusedDate,
                              onPageChange: (date, page) => _focusedDate = date,
                              backgroundColor: const Color(0xFF181818),
                              headerStyle: HeaderStyle(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF181818),
                                ),
                                headerTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              weekTitleHeight: 70,
                              weekPageHeaderBuilder: (startDate, endDate) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  color: const Color(0xFF181818),
                                  child: Row(
                                    children: [
                                      Text(
                                        DateFormat('MMMM yyyy', 'it').format(startDate).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_left, color: Colors.white),
                                        onPressed: () => _weekViewKey.currentState?.previousPage(),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                                        onPressed: () => _weekViewKey.currentState?.nextPage(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              weekDayBuilder: (date) {
                                final isToday = date.day == DateTime.now().day &&
                                    date.month == DateTime.now().month &&
                                    date.year == DateTime.now().year;
                                    
                                return Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF181818),
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
                                        DateFormat('EEE', 'it').format(date).toUpperCase(),
                                        style: TextStyle(
                                          color: isToday ? const Color(0xFFFFFFFF) : Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isToday ? const Color(0xFFFFFFFF) : Colors.transparent,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${date.day}',
                                          style: TextStyle(
                                            color: isToday ? Colors.black : Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w400,
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
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                );
                              },
                              hourIndicatorSettings: HourIndicatorSettings(
                                color: Colors.white.withOpacity(0.1),
                                height: 1,
                                offset: 0,
                              ),
                              liveTimeIndicatorSettings: const LiveTimeIndicatorSettings(
                                color: Color(0xFFEA4335),
                                height: 2,
                                showTime: true,
                                showBullet: true,
                              ),
                              onEventTap: (events, date) {
                                if (events.isNotEmpty) {
                                  _showAppointmentDetails(context, events.first);
                                }
                              },
                              eventTileBuilder: (date, events, boundary, start, end) {
                                if (events.isEmpty) return const SizedBox();
                                
                                final event = events.first;
                                
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          event.title,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: const Color(0xFFFFFFFF).withOpacity(0.5),
              width: 1,
            ),
          ),
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
                    color: const Color(0xFFFFFFFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Color(0xFFFFFFFF)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente',
                        style: TextStyle(
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
            _buildDetailRow(Icons.cut, 'Servizio', event.description?.split('\n').first ?? 'N/A'),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.access_time, 'Orario', 
              '${DateFormat('HH:mm').format(event.startTime!)} - ${DateFormat('HH:mm').format(event.endTime!)}'),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.calendar_today, 'Data', 
              DateFormat('EEEE d MMMM yyyy', 'it').format(event.date)),
            if (event.description != null && event.description!.contains('\n')) ...[
              const SizedBox(height: 16),
              _buildDetailRow(Icons.phone, 'Telefono', event.description!.split('\n').last),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCancelDialog(context, event.event as AppointmentModel);
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Annulla',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFFFFF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Chiudi',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
        Icon(icon, color: const Color(0xFFFFFFFF), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showCancelDialog(BuildContext context, AppointmentModel appointment) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.3)),
        ),
        title: const Text('Annulla Appuntamento', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(
          'Sei sicuro di voler annullare l\'appuntamento di ${appointment.customerName}?\nL\'operazione non può essere annullata.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, mantieni', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(firestoreServiceProvider).updateAppointmentStatus(
                  appointment.id, 
                  AppointmentStatus.cancelled
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appuntamento annullato con successo')),
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
            child: const Text('Sì, annulla', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFFFFFFF) 
                : const Color(0xFFFFFFFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFFFFFF).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                color: isSelected ? Colors.black : const Color(0xFFFFFFFF), 
                size: 24
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFFFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
