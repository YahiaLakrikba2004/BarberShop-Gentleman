import 'dart:convert';
import 'dart:ui';

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
        padding: EdgeInsets.symmetric(horizontal: w > 700 ? 32 : 16, vertical: 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: 0.72,
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

// ─── Barber card ─────────────────────────────────────────────────────────────

class _BarberCard extends StatelessWidget {
  final BarberModel barber;
  final bool isSelected;
  final VoidCallback? onTap;

  const _BarberCard(
      {required this.barber, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAvailable = barber.availabilityStatus == BarberAvailability.available;

    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.4 : 0.2),
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
              _BarberImage(barber: barber, isSelected: isSelected),
              _GradientOverlay(context: context),
              _GlassOverlay(),
              if (isSelected) _SelectionBorder(context: context),
              if (!isAvailable) _UnavailableOverlay(barber: barber),
              _BarberInfo(barber: barber, outerContext: context),
              if (!isAvailable) _StatusBadge(barber: barber),
              if (isSelected) _SelectionBadge(context: context),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarberImage extends StatelessWidget {
  final BarberModel barber;
  final bool isSelected;

  const _BarberImage({required this.barber, required this.isSelected});

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

    Widget img;
    if (url.isNotEmpty) {
      if (url.startsWith('assets/')) {
        img = Image.asset(url, fit: BoxFit.cover, gaplessPlayback: true);
      } else if (url.startsWith('http')) {
        img = Image.network(url, fit: BoxFit.cover, gaplessPlayback: true);
      } else {
        try {
          img = Image.memory(base64Decode(url), fit: BoxFit.cover, gaplessPlayback: true);
        } catch (_) {
          img = Container(color: const Color(0xFF222222));
        }
      }
    } else {
      img = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
          ),
        ),
        child: Center(
          child: Text(
            barber.name.isNotEmpty ? barber.name[0].toUpperCase() : '?',
            style: GoogleFonts.cinzel(
                fontSize: 64, fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.08), letterSpacing: 4),
          ),
        ),
      );
    }

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected
            ? Colors.transparent
            : (Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.2)),
        BlendMode.darken,
      ),
      child: img,
    );
  }
}

class _GradientOverlay extends StatelessWidget {
  final BuildContext context;
  const _GradientOverlay({required this.context});

  @override
  Widget build(BuildContext _) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.black : Colors.white;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            base.withValues(alpha: 0.2),
            base.withValues(alpha: 0.8),
            base.withValues(alpha: 0.95),
          ],
          stops: const [0.4, 0.6, 0.85, 1.0],
        ),
      ),
    );
  }
}

class _GlassOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 85,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionBorder extends StatelessWidget {
  final BuildContext context;
  const _SelectionBorder({required this.context});

  @override
  Widget build(BuildContext _) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8), width: 2),
      ),
    );
  }
}

class _UnavailableOverlay extends StatelessWidget {
  final BarberModel barber;
  const _UnavailableOverlay({required this.barber});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(barberStatusIcon(barber.availabilityStatus),
                  color: barberStatusColor(barber.availabilityStatus).withValues(alpha: 0.8),
                  size: 32),
              const SizedBox(height: 8),
              Text(barberStatusLabel(barber.availabilityStatus),
                  style: GoogleFonts.montserrat(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarberInfo extends ConsumerWidget {
  final BarberModel barber;
  final BuildContext outerContext;
  const _BarberInfo({required this.barber, required this.outerContext});

  String _effectiveHours(ShopDaySchedule? shopDay) {
    final today = DateTime.now().weekday;
    final dayStart = barber.startHourFor(today);
    final dayEnd   = barber.endHourFor(today);
    final effStart = shopDay != null && !shopDay.isClosed
        ? dayStart.clamp(shopDay.openHour, shopDay.closeHour)
        : dayStart;
    final effEnd = shopDay != null && !shopDay.isClosed
        ? dayEnd.clamp(shopDay.openHour, shopDay.closeHour)
        : dayEnd;

    String h(int v) => '${v.toString().padLeft(2, '0')}:00';

    if (barber.hasBreakOn(today)) {
      return '${h(effStart)}–${h(barber.breakStartHour)} | ${h(barber.breakEndHour)}–${h(effEnd)}';
    }
    return '${h(effStart)} – ${h(effEnd)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(outerContext).brightness == Brightness.dark;
    final timeColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7);
    final timeBg = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1);

    final shopSettings = ref.watch(shopSettingsProvider).valueOrNull;
    final todaySchedule = shopSettings?.weeklySchedule[DateTime.now().weekday];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(barber.name.toUpperCase(),
              style: GoogleFonts.cinzel(
                  fontSize: 17, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 1.2,
                  shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 10)]),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            barber.specialties.isNotEmpty
                ? barber.specialties.join(' • ').toUpperCase()
                : 'SPECIALISTA TAGLIO & BARBA',
            style: GoogleFonts.montserrat(
                color: Theme.of(outerContext).colorScheme.primary,
                fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: timeBg, borderRadius: BorderRadius.circular(4)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, color: timeColor, size: 10),
                const SizedBox(width: 4),
                Text(
                  _effectiveHours(todaySchedule),
                  style: GoogleFonts.montserrat(
                      color: timeColor, fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final BarberModel barber;
  const _StatusBadge({required this.barber});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12, right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: barberStatusColor(barber.availabilityStatus).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4)),
        child: Text(barberStatusLabel(barber.availabilityStatus),
            style: GoogleFonts.montserrat(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
      ),
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  final BuildContext context;
  const _SelectionBadge({required this.context});

  @override
  Widget build(BuildContext _) {
    return Positioned(
      top: 12, right: 12,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)],
        ),
        child: Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}
