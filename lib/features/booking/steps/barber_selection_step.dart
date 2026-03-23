import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/barber_model.dart';
import '../../../models/shop_settings_model.dart';
import '../../../services/firestore_service.dart';
import '../booking_widgets.dart';

class BarberSelectionStep extends ConsumerWidget {
  final BarberModel? selectedBarber;
  final void Function(BarberModel barber, DateTime initialDate) onBarberSelected;

  const BarberSelectionStep({
    super.key,
    required this.selectedBarber,
    required this.onBarberSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final barbers = ref.watch(barberListProvider).maybeWhen(
          data: (list) => list,
          orElse: () => <BarberModel>[],
        );
    final bookable = barbers.where((b) => b.isBookable).toList();

    if (bookable.isEmpty) {
      return Center(
        child: Text('Nessun barbiere disponibile.',
            style: GoogleFonts.montserrat(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final cols = w > 1100 ? 4 : (w > 700 ? 3 : 2);
      return GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: w > 700 ? 40 : 20, vertical: 24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: 0.66,
          crossAxisSpacing: w > 700 ? 20 : 14,
          mainAxisSpacing: w > 700 ? 20 : 14,
        ),
        itemCount: bookable.length,
        itemBuilder: (context, i) => _BarberCard(
          barber: bookable[i],
          isSelected: selectedBarber?.id == bookable[i].id,
          onTap: () {
            final barber = bookable[i];
            final shopSettings = ref.read(shopSettingsProvider).valueOrNull;
            DateTime date = DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            );
            int tries = 0;
            while (tries < 60) {
              final isWeekend = date.weekday == DateTime.sunday;
              final isBarberDayOff = barber.daysOff.contains(date.weekday);
              final isShopClosed = shopSettings != null &&
                  (shopSettings.isShopClosedManually ||
                      shopSettings.closures.any((c) =>
                          c.year == date.year &&
                          c.month == date.month &&
                          c.day == date.day) ||
                      (shopSettings.weeklySchedule[date.weekday]?.isClosed ?? false));
              if (!isWeekend && !isBarberDayOff && !isShopClosed) break;
              date = date.add(const Duration(days: 1));
              tries++;
            }
            onBarberSelected(barber, date);
          },
        ),
      );
    });
  }
}

// ─── Barber card ──────────────────────────────────────────────────────────────

class _BarberCard extends StatelessWidget {
  final BarberModel barber;
  final bool isSelected;
  final VoidCallback? onTap;

  const _BarberCard(
      {required this.barber, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAvailable = barber.availabilityStatus == BarberAvailability.available;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? primary.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.07),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primary.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: isSelected ? 28 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Photo (top 63%) ────────────────────────────────────
              Expanded(
                flex: 63,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _BarberPhoto(barber: barber),

                    // Fade into info panel
                    const Positioned(
                      bottom: 0, left: 0, right: 0,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xFF131313),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Unavailable overlay
                    if (!isAvailable) _UnavailableOverlay(barber: barber),

                    // Selected checkmark
                    if (isSelected)
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(Icons.check,
                              size: 12,
                              color: Theme.of(context).colorScheme.onPrimary),
                        ),
                      ),

                    // Status badge (not available, not selected)
                    if (!isAvailable && !isSelected)
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: barberStatusColor(barber.availabilityStatus)
                                .withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            barberStatusLabel(barber.availabilityStatus),
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Info panel (bottom 37%) ────────────────────────────
              Expanded(
                flex: 37,
                child: _BarberInfoPanel(barber: barber, isSelected: isSelected),
              ),

              // ── Selection accent line at very bottom ───────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: isSelected ? 3 : 0,
                color: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Photo widget ─────────────────────────────────────────────────────────────

class _BarberPhoto extends StatelessWidget {
  final BarberModel barber;

  const _BarberPhoto({required this.barber});

  @override
  Widget build(BuildContext context) {
    String url = barber.imageUrl;
    if (url.isEmpty) {
      if (barber.name.toLowerCase().contains('omar')) {
        url = 'assets/images/barber_marco.png';
      } else if (barber.name.toLowerCase().contains('brombei')) {
        url = 'assets/images/barber_giuseppe.png';
      }
    }

    if (url.isNotEmpty) {
      if (url.startsWith('assets/')) {
        return Image.asset(url, fit: BoxFit.cover, gaplessPlayback: true);
      } else if (url.startsWith('http')) {
        return Image.network(url, fit: BoxFit.cover, gaplessPlayback: true);
      } else {
        try {
          return Image.memory(
              base64Decode(url), fit: BoxFit.cover, gaplessPlayback: true);
        } catch (_) {}
      }
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1E1E), Color(0xFF131313)],
        ),
      ),
      child: Center(
        child: Text(
          barber.name.isNotEmpty ? barber.name[0].toUpperCase() : '?',
          style: GoogleFonts.cinzel(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.07),
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

// ─── Info panel ───────────────────────────────────────────────────────────────

class _BarberInfoPanel extends ConsumerWidget {
  final BarberModel barber;
  final bool isSelected;

  const _BarberInfoPanel({required this.barber, required this.isSelected});

  String _effectiveHours(ShopDaySchedule? shopDay) {
    final today = DateTime.now().weekday;
    final dayStart = barber.startHourFor(today);
    final dayEnd = barber.endHourFor(today);
    final effStart = shopDay != null && !shopDay.isClosed
        ? dayStart.clamp(shopDay.openHour, shopDay.closeHour)
        : dayStart;
    final effEnd = shopDay != null && !shopDay.isClosed
        ? dayEnd.clamp(shopDay.openHour, shopDay.closeHour)
        : dayEnd;
    String h(int v) => '${v.toString().padLeft(2, '0')}:00';
    String hm(int v, int m) => '${v.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    if (barber.hasDoubleShift) {
      final refDay = barber.hasBreakOn(today) ? today
          : (barber.doubleShiftDays.isNotEmpty ? barber.doubleShiftDays.first : today);
      final br = barber.breakForDay(refDay);
      return '${h(effStart)}–${hm(br[0], br[1])} | ${hm(br[2], br[3])}–${h(effEnd)}';
    }
    return '${h(effStart)} – ${h(effEnd)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final shopSettings = ref.watch(shopSettingsProvider).valueOrNull;
    final todaySchedule = shopSettings?.weeklySchedule[DateTime.now().weekday];

    return Container(
      color: const Color(0xFF131313),
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Name
          Text(
            barber.name.toUpperCase(),
            style: GoogleFonts.cinzel(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Specialty
          if (barber.specialties.isNotEmpty)
          Text(
            barber.specialties.take(2).join(' · ').toUpperCase(),
            style: GoogleFonts.montserrat(
              color: primary.withValues(alpha: 0.9),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Hours
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: 10,
                  color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _effectiveHours(todaySchedule),
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Unavailable overlay ──────────────────────────────────────────────────────

class _UnavailableOverlay extends StatelessWidget {
  final BarberModel barber;

  const _UnavailableOverlay({required this.barber});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                barberStatusIcon(barber.availabilityStatus),
                color: barberStatusColor(barber.availabilityStatus),
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                barberStatusLabel(barber.availabilityStatus),
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
