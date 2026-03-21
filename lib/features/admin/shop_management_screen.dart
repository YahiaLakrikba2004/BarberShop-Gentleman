import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/shop_settings_model.dart';
import 'package:animate_do/animate_do.dart';
import 'package:table_calendar/table_calendar.dart';

class ShopManagementScreen extends ConsumerStatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  ConsumerState<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends ConsumerState<ShopManagementScreen> {
  final TextEditingController _announcementController = TextEditingController();
  bool _isAnnouncementActive = false;
  bool _isShopClosedManually = false;
  List<DateTime> _closures = [];
  List<String> _galleryImages = [];
  bool _isLoaded = false;
  bool _isUploadingGallery = false;
  DateTime _focusedDay = DateTime.now();
  Map<int, ShopDaySchedule> _weeklySchedule = {};

  @override
  void dispose() {
    _announcementController.dispose();
    super.dispose();
  }

  static const List<String> _defaultAssetImages = [
    'assets/images/gallery/gallery_user_1.jpg',
    'assets/images/gallery/gallery_user_2.jpg',
    'assets/images/gallery/gallery_user_3.jpg',
    'assets/images/gallery/gallery_user_4.jpg',
    'assets/images/gallery/gallery_user_5.jpg',
    'assets/images/gallery/gallery_user_6.jpg',
    'assets/images/gallery/gallery_user_7.jpg',
  ];

  void _initSettings(ShopSettingsModel settings) {
    if (!_isLoaded) {
      _announcementController.text = settings.announcement;
      _isAnnouncementActive = settings.isAnnouncementActive;
      _isShopClosedManually = settings.isShopClosedManually;
      _closures = List.from(settings.closures);
      // If no custom images saved yet, show defaults so admin can delete them
      _galleryImages = settings.galleryImages.isNotEmpty
          ? List.from(settings.galleryImages)
          : List.from(_defaultAssetImages);

      // Detect old Firestore data (no hasBreak / no minute precision for Mon)
      // and auto-apply + save the correct real-world schedule.
      final needsMigration = !(settings.weeklySchedule[1]?.hasBreak ?? false);
      if (needsMigration) {
        _weeklySchedule = ShopSettingsModel().weeklySchedule;
        _isLoaded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _saveSettings());
      } else {
        _weeklySchedule = Map.from(settings.weeklySchedule);
        _isLoaded = true;
      }
    }
  }

  Future<void> _addGalleryImage() async {
    if (_galleryImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Massimo 10 foto nella galleria.')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (picked == null) return;
    setState(() => _isUploadingGallery = true);
    try {
      final bytes = await picked.readAsBytes();
      final filename = 'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await ref.read(storageServiceProvider).uploadGalleryImage(filename, bytes);
      final updated = List<String>.from(_galleryImages)..add(url);
      final currentSettings = ref.read(shopSettingsProvider).value ?? ShopSettingsModel();
      await ref.read(firestoreServiceProvider).updateShopSettings(
        currentSettings.copyWith(galleryImages: updated),
      );
      setState(() => _galleryImages = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore upload: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingGallery = false);
    }
  }

  Future<void> _removeGalleryImage(int index) async {
    final imgStr = _galleryImages[index];
    // Se è un URL di Firebase Storage, elimina anche il file
    if (imgStr.startsWith('https://')) {
      ref.read(storageServiceProvider).deleteGalleryImage(imgStr);
    }
    final updated = List<String>.from(_galleryImages)..removeAt(index);
    final currentSettings = ref.read(shopSettingsProvider).value ?? ShopSettingsModel();
    await ref.read(firestoreServiceProvider).updateShopSettings(
      currentSettings.copyWith(galleryImages: updated),
    );
    setState(() => _galleryImages = updated);
  }

  Future<void> _saveSettings() async {
    final newSettings = ShopSettingsModel(
      announcement: _announcementController.text.trim(),
      isAnnouncementActive: _isAnnouncementActive,
      isShopClosedManually: _isShopClosedManually,
      closures: _closures,
      galleryImages: _galleryImages,
      weeklySchedule: _weeklySchedule,
    );

    try {
      await ref.read(firestoreServiceProvider).updateShopSettings(newSettings);
      // If announcement is active, queue push notification to all clients
      if (_isAnnouncementActive && _announcementController.text.trim().isNotEmpty) {
        await ref.read(firestoreServiceProvider).queueAnnouncementToAllClients(
          _announcementController.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impostazioni salvate con successo!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il salvataggio: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(shopSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GESTIONE SALONE',
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: settingsAsync.when(
        data: (settings) {
          _initSettings(settings);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(
                  child: _buildPremiumSection(
                    context,
                    title: 'ANNUNCIO GLOBALE',
                    icon: Icons.campaign_outlined,
                    description: 'Mostra un messaggio importante in cima alla Home Screen.',
                    child: Column(
                      children: [
                        _buildSettingsSwitch(
                          context,
                          title: 'Attiva Annuncio',
                          subtitle: 'Il messaggio sarà visibile a tutti gli utenti',
                          value: _isAnnouncementActive,
                          onChanged: (val) => setState(() => _isAnnouncementActive = val),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _announcementController,
                          style: GoogleFonts.montserrat(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Scrivi qui il tuo messaggio...',
                            hintStyle: GoogleFonts.montserrat(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white.withValues(alpha: 0.05) 
                                : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Theme.of(context).dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                            contentPadding: const EdgeInsets.all(20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: _buildPremiumSection(
                    context,
                    title: 'CHIUSURA MANUALE',
                    icon: Icons.power_settings_new,
                    description: 'Blocca istantaneamente tutte le nuove prenotazioni.',
                    child: _buildSettingsSwitch(
                      context,
                      title: 'Chiusura Forzata',
                      subtitle: 'Disabilita il sistema di prenotazione',
                      value: _isShopClosedManually,
                      onChanged: (val) => setState(() => _isShopClosedManually = val),
                      isDestructive: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInDown(
                  delay: const Duration(milliseconds: 200),
                  child: _buildPremiumSection(
                    context,
                    title: 'CALENDARIO CHIUSURE',
                    icon: Icons.calendar_month_outlined,
                    description: 'Pianifica le ferie o le chiusure straordinarie del salone.',
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white.withValues(alpha: 0.03) 
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                          ),
                          child: TableCalendar(
                            locale: 'it_IT',
                            firstDay: DateTime.now().subtract(const Duration(days: 30)),
                            lastDay: DateTime.now().add(const Duration(days: 365)),
                            focusedDay: _focusedDay,
                            calendarFormat: CalendarFormat.month,
                            availableGestures: AvailableGestures.all,
                            headerStyle: HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: GoogleFonts.cinzel(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: 2,
                              ),
                              leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary),
                              rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                            ),
                            calendarStyle: CalendarStyle(
                              defaultTextStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                              weekendTextStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                              outsideTextStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
                              todayDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                              ),
                              selectedDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              selectedTextStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              markerDecoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            daysOfWeekStyle: DaysOfWeekStyle(
                              weekdayStyle: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 12),
                              weekendStyle: GoogleFonts.montserrat(color: Colors.redAccent.withValues(alpha: 0.5), fontSize: 12),
                            ),
                            selectedDayPredicate: (day) => _closures.any((d) => isSameDay(d, day)),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                                if (_closures.any((d) => isSameDay(d, selectedDay))) {
                                  _closures.removeWhere((d) => isSameDay(d, selectedDay));
                                } else {
                                  _closures.add(selectedDay);
                                }
                              });
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_closures.isNotEmpty) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'DATE SELEZIONATE'.toUpperCase(),
                              style: GoogleFonts.cinzel(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 45,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _closures.map((date) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InputChip(
                                  label: Text(DateFormat('dd MMM', 'it').format(date)),
                                  onDeleted: () => setState(() => _closures.removeWhere((d) => isSameDay(d, date))),
                                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  labelStyle: GoogleFonts.montserrat(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  deleteIconColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInDown(
                  delay: const Duration(milliseconds: 300),
                  child: _buildPremiumSection(
                    context,
                    title: 'GALLERIA HOME',
                    icon: Icons.photo_library_outlined,
                    description: 'Le foto mostrate nel carosello della home screen. Max 10 immagini.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnails row
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _galleryImages.length + 1,
                            itemBuilder: (context, index) {
                              // "+" button at the end
                              if (index == _galleryImages.length) {
                                return GestureDetector(
                                  onTap: _isUploadingGallery ? null : _addGalleryImage,
                                  child: Container(
                                    width: 80,
                                    height: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: _isUploadingGallery
                                        ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white38)))
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_photo_alternate_outlined, color: Colors.white.withValues(alpha: 0.4), size: 28),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_galleryImages.length}/10',
                                                style: GoogleFonts.montserrat(
                                                  color: Colors.white.withValues(alpha: 0.3),
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              }
                              // Thumbnail
                              final imgStr = _galleryImages[index];
                              final ImageProvider imgProvider = imgStr.startsWith('assets/')
                                  ? AssetImage(imgStr) as ImageProvider
                                  : imgStr.startsWith('https://')
                                      ? NetworkImage(imgStr)
                                      : MemoryImage(base64Decode(imgStr));
                              return Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: imgProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => _removeGalleryImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xCC000000),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close, color: Colors.white, size: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _galleryImages.isEmpty
                                ? 'Nessuna foto. Premi + per aggiungerne.'
                                : 'Tieni premuto × per rimuovere. Premi + per aggiungere nuove foto.',
                            style: GoogleFonts.montserrat(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInDown(
                  delay: const Duration(milliseconds: 350),
                  child: _buildPremiumSection(
                    context,
                    title: 'ORARI SETTIMANALI',
                    icon: Icons.schedule_outlined,
                    description: 'Gli slot di prenotazione non potranno mai iniziare prima dell\'apertura o finire dopo la chiusura.',
                    child: _buildWeeklyScheduleWidget(context),
                  ),
                ),
                const SizedBox(height: 48),
                FadeInUp(
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text(
                        'SALVA CONFIGURAZIONE',
                        style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Errore durante il caricamento',
                style: GoogleFonts.montserrat(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const List<String> _dayNames = ['', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

  Widget _buildWeeklyScheduleWidget(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: List.generate(7, (i) {
        final weekday = i + 1;
        final day = _weeklySchedule[weekday] ?? const ShopDaySchedule(openHour: 9, closeHour: 19);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: day.isClosed
                    ? Colors.redAccent.withValues(alpha: 0.3)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        _dayNames[weekday],
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: day.isClosed
                              ? Colors.redAccent.withValues(alpha: 0.6)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Chiuso toggle
                    GestureDetector(
                      onTap: () => setState(() {
                        _weeklySchedule[weekday] = day.copyWith(isClosed: !day.isClosed);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: day.isClosed
                              ? Colors.redAccent.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: day.isClosed
                                ? Colors.redAccent.withValues(alpha: 0.4)
                                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          day.isClosed ? 'Chiuso' : 'Aperto',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: day.isClosed
                                ? Colors.redAccent
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!day.isClosed) ...[
                      _buildTimePicker(
                        context,
                        label: 'Apertura',
                        hour: day.openHour,
                        minute: day.openMinute,
                        onChanged: (h, m) => setState(() {
                          _weeklySchedule[weekday] = day.copyWith(openHour: h, openMinute: m);
                        }),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('–',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.3))),
                      ),
                      _buildTimePicker(
                        context,
                        label: 'Chiusura',
                        hour: day.closeHour,
                        minute: day.closeMinute,
                        onChanged: (h, m) => setState(() {
                          _weeklySchedule[weekday] = day.copyWith(closeHour: h, closeMinute: m);
                        }),
                      ),
                    ],
                  ],
                ),
                if (!day.isClosed) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 44),
                      // Pausa toggle
                      GestureDetector(
                        onTap: () => setState(() {
                          _weeklySchedule[weekday] = day.copyWith(hasBreak: !day.hasBreak);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: day.hasBreak
                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: day.hasBreak
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                                  : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Pausa',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: day.hasBreak
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (day.hasBreak) ...[
                        _buildTimePicker(
                          context,
                          label: 'Inizio',
                          hour: day.breakStartHour,
                          minute: day.breakStartMinute,
                          onChanged: (h, m) => setState(() {
                            _weeklySchedule[weekday] = day.copyWith(breakStartHour: h, breakStartMinute: m);
                          }),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('–',
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.3))),
                        ),
                        _buildTimePicker(
                          context,
                          label: 'Fine',
                          hour: day.breakEndHour,
                          minute: day.breakEndMinute,
                          onChanged: (h, m) => setState(() {
                            _weeklySchedule[weekday] = day.copyWith(breakEndHour: h, breakEndMinute: m);
                          }),
                        ),
                      ] else
                        Text(
                          'Nessuna pausa',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTimePicker(BuildContext context, {required String label, required int hour, required int minute, required void Function(int h, int m) onChanged}) {
    final display = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked.hour, picked.minute);
      },
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 0.5,
              )),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              display,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String description,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cinzel(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.montserrat(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildSettingsSwitch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isDestructive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black.withValues(alpha: 0.2) 
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDestructive && value
              ? Colors.redAccent.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            color: isDestructive && value ? Colors.redAccent : Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.montserrat(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: isDestructive ? Colors.redAccent : Theme.of(context).colorScheme.primary,
        activeTrackColor: (isDestructive ? Colors.redAccent : Theme.of(context).colorScheme.primary).withValues(alpha: 0.2),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
