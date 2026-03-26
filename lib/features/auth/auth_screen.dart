import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/firebase_error_handler.dart';

enum _AuthStep { phone, pin, register, email }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();

  // Email Auth (admin fallback)
  final _adminEmailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _rotationController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  _AuthStep _step = _AuthStep.phone;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEmailLoginMode = false;

  String? _existingEmail; // email trovata in Firestore per utente esistente

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 14.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _shakeController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _adminEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Step 1: Controlla numero ────────────────────────────────────────────────

  Future<void> _checkPhone() async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      _showError("Inserisci il numero di telefono");
      return;
    }
    setState(() => _isLoading = true);

    try {
      final phone = raw.startsWith('+') ? raw : '+39$raw';
      final firestore = ref.read(firestoreServiceProvider);
      final user = await firestore.getUserByPhone(phone);

      setState(() {
        if (user != null) {
          _existingEmail = user.email;
          _step = _AuthStep.pin;
        } else {
          _step = _AuthStep.register;
        }
        _isLoading = false;
      });

      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _pinFocusNode.requestFocus();
      });
    } catch (e) {
      _showError(FirebaseErrorHandler.generic(e));
      setState(() => _isLoading = false);
    }
  }

  // ─── Step 2a: Login con PIN ──────────────────────────────────────────────────

  Future<void> _loginWithPin() async {
    if (_isLoading) return;
    final pin = _pinController.text;
    if (pin.length < 6) {
      _showError("Inserisci il PIN a 6 cifre");
      return;
    }
    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).signInWithEmailAndPassword(_existingEmail!, pin);
      if (mounted) context.go('/');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _shakePin();
      _showError(FirebaseErrorHandler.auth(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _shakePin();
      _showError(FirebaseErrorHandler.generic(e));
    }
  }

  void _shakePin() {
    _pinController.clear();
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _pinFocusNode.requestFocus();
    });
    _shakeController.forward(from: 0);
  }

  // ─── PIN dimenticato ─────────────────────────────────────────────────────────

  Future<void> _forgotPin() async {
    if (_existingEmail == null) return;

    // Utenti vecchi con email fake: non possono fare reset autonomamente
    if (_existingEmail!.endsWith('@gentleman.app')) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Reimposta PIN',
            style: GoogleFonts.cinzel(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Il tuo account è stato creato con il vecchio sistema e non supporta il reset autonomo del PIN.\n\nContatta il negozio direttamente per ricevere un nuovo PIN.',
            style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Chiudi', style: GoogleFonts.montserrat(color: Colors.white38)),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                const shopWhatsApp = '393514823048';
                final uri = Uri.parse('https://wa.me/$shopWhatsApp?text=Ciao%2C+ho+bisogno+di+reimpostare+il+mio+PIN');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: Text('WhatsApp', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _existingEmail!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Email inviata a $_existingEmail"),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(FirebaseErrorHandler.auth(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Step 2b: Registrazione ──────────────────────────────────────────────────

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final email = _emailController.text.trim();
    final pin = _pinController.text;

    if (name.isEmpty || surname.isEmpty) {
      _showError("Nome e Cognome sono obbligatori");
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError("Inserisci un'email valida");
      return;
    }
    if (pin.length < 6) {
      _showError("Scegli un PIN a 6 cifre");
      return;
    }
    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      final formatted = phone.startsWith('+') ? phone : '+39$phone';

      await ref.read(authServiceProvider).signUpWithEmailAndPassword(
        email: email,
        password: pin,
        name: '$name $surname',
        phoneNumber: formatted,
      );

      if (mounted) context.go('/');
    } catch (e) {
      _showError(FirebaseErrorHandler.generic(e));
      setState(() => _isLoading = false);
    }
  }

  // ─── Email Auth (Admin fallback) ─────────────────────────────────────────────

  Future<void> _submitEmailAuth() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithEmailAndPassword(
        _adminEmailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) context.go('/');
    } catch (e) {
      _showError(FirebaseErrorHandler.generic(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC143C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetToPhone() {
    setState(() {
      _step = _AuthStep.phone;
      _isLoading = false;
      _existingEmail = null;
      _pinController.clear();
    });
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const inputFill = Color(0xFF1E1E1E);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [Color(0xFF161616), Color(0xFF000000)],
              stops: [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: isDesktop
                ? _buildDesktopLayout(inputFill)
                : _buildMobileLayout(inputFill),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Color inputFill) {
    const goldColor = Color(0xFFD4AF37);
    return Row(
      children: [
        // Left panel — brand
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (_, child) => Transform.rotate(
                      angle: _rotationController.value * 2 * 3.14159,
                      child: child,
                    ),
                    child: Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(color: goldColor.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: goldColor.withValues(alpha: 0.15), blurRadius: 60, spreadRadius: 8),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Image.asset('assets/images/icon_premium_v2.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text('THE GENTLEMEN',
                    style: GoogleFonts.cinzel(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 5)),
                  const SizedBox(height: 10),
                  Text('BARBERSTYLE',
                    style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white38, letterSpacing: 8)),
                  const SizedBox(height: 40),
                  Container(
                    width: 40,
                    height: 1,
                    color: goldColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 24),
                  Text('STILE • ELEGANZA • PRECISIONE',
                    style: GoogleFonts.montserrat(fontSize: 10, color: Colors.white24, letterSpacing: 3)),
                ],
              ),
            ),
          ),
        ),
        // Right panel — form
        SizedBox(
          width: 480,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: _buildFormContent(inputFill),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Color inputFill) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height
              - MediaQuery.of(context).padding.top
              - MediaQuery.of(context).padding.bottom
              - 48,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeInDown(
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
                  boxShadow: [
                    BoxShadow(color: Colors.white.withValues(alpha: 0.08), blurRadius: 40, spreadRadius: 4),
                  ],
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset('assets/images/icon_premium_v2.png', fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text('THE GENTLEMEN', style: GoogleFonts.cinzel(fontSize: 27, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4)),
            const SizedBox(height: 8),
            Text('BARBERSTYLE', style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white38, letterSpacing: 7, fontWeight: FontWeight.w300)),
            const SizedBox(height: 14),
            const ColoredBox(color: Colors.white24, child: SizedBox(width: 40, height: 0.5)),
            const SizedBox(height: 36),
            _buildFormContent(inputFill),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContent(Color inputFill) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
          child: _buildCurrentStep(inputFill),
        ),
        const SizedBox(height: 32),
        if (_step == _AuthStep.phone)
          TextButton(
            onPressed: () => setState(() => _isEmailLoginMode = !_isEmailLoginMode),
            child: Text(
              _isEmailLoginMode ? "Usa Numero di Telefono" : "Usa Email e Password",
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentStep(Color inputFill) {
    if (_isEmailLoginMode && _step == _AuthStep.phone) {
      return _buildEmailAuth(inputFill);
    }
    switch (_step) {
      case _AuthStep.phone:    return _buildPhoneStep(inputFill);
      case _AuthStep.pin:      return _buildPinStep(inputFill);
      case _AuthStep.register: return _buildRegisterStep(inputFill);
      case _AuthStep.email:    return _buildEmailAuth(inputFill);
    }
  }

  // ─── Phone Step ──────────────────────────────────────────────────────────────

  Widget _buildPhoneStep(Color inputFill) {
    return Column(
      children: [
        Text("INSERISCI IL TUO NUMERO",
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Text("Accedi con numero di telefono e PIN",
          style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11),
          textAlign: TextAlign.center),
        const SizedBox(height: 24),
        _buildPhoneField(inputFill),
        const SizedBox(height: 24),
        _primaryButton(label: "AVANTI", onPressed: _checkPhone),
      ],
    );
  }

  Widget _buildPhoneField(Color inputFill) {
    return Container(
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Text('🇮🇹  +39',
              style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: const InputDecoration(
                hintText: '333 1234567',
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PIN Step ────────────────────────────────────────────────────────────────

  Widget _buildPinStep(Color inputFill) {
    final phone = _phoneController.text.trim();
    final display = phone.startsWith('+') ? phone : '+39$phone';
    final isFakeEmail = _existingEmail?.endsWith('@gentleman.app') ?? false;

    return Column(
      children: [
        const Icon(Icons.lock_outline, color: Colors.white54, size: 36),
        const SizedBox(height: 16),
        Text("INSERISCI IL TUO PIN",
          style: GoogleFonts.cinzel(color: Colors.white, fontSize: 15, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(display,
          style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 28),

        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) => Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          ),
          child: GestureDetector(
            onTap: () => _pinFocusNode.requestFocus(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hidden TextField capturing input
                SizedBox(
                  width: 0,
                  height: 0,
                  child: TextField(
                    controller: _pinController,
                    focusNode: _pinFocusNode,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: false,
                    showCursor: false,
                    style: const TextStyle(color: Colors.transparent),
                    decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      if (val.length == 6 && _step == _AuthStep.pin) {
                        _loginWithPin();
                      }
                    },
                  ),
                ),
                // Visual dots — iOS style with glow
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _pinController,
                  builder: (context, value, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) {
                        final filled = i < value.text.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: filled ? 20 : 16,
                          height: filled ? 20 : 16,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.15),
                            boxShadow: filled ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ] : null,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        _primaryButton(label: "ACCEDI", onPressed: _loginWithPin),
        const SizedBox(height: 4),

        TextButton(
          onPressed: _isLoading ? null : _forgotPin,
          child: Text(
            isFakeEmail ? "Non ricordi il PIN? Scopri come reimpostarlo" : "PIN dimenticato?",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : _resetToPhone,
          child: const Text("Cambia numero", style: TextStyle(color: Colors.white38, fontSize: 12)),
        ),
      ],
    );
  }

  // ─── Register Step ───────────────────────────────────────────────────────────

  Widget _buildRegisterStep(Color inputFill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text("NUOVO ACCOUNT",
                style: GoogleFonts.cinzel(color: Colors.white, fontSize: 15, letterSpacing: 2)),
              const SizedBox(height: 6),
              Text("Completa il profilo e scegli un PIN",
                style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Row(children: [
          Expanded(child: _buildTextField(controller: _nameController, label: 'Nome', icon: Icons.person, inputFill: inputFill)),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField(controller: _surnameController, label: 'Cognome', icon: Icons.person_outline, inputFill: inputFill)),
        ]),
        const SizedBox(height: 14),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          inputFill: inputFill,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),

        Center(
          child: Text("SCEGLI UN PIN DI ACCESSO",
            style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pinFocusNode.requestFocus(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 0,
                height: 0,
                child: TextField(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: false,
                  showCursor: false,
                  style: const TextStyle(color: Colors.transparent),
                  decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _pinController,
                builder: (context, value, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (i) {
                      final filled = i < value.text.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        width: filled ? 20 : 16,
                        height: filled ? 20 : 16,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.15),
                          boxShadow: filled ? [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ] : null,
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _primaryButton(label: "REGISTRATI", onPressed: _register),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _resetToPhone,
            child: const Text("Annulla", style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  // ─── Email Auth (Admin) ───────────────────────────────────────────────────────

  Widget _buildEmailAuth(Color inputFill) {
    return Column(
      children: [
        Text("ACCESSO ADMIN",
          style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 13, letterSpacing: 1.5)),
        const SizedBox(height: 24),
        _buildTextField(controller: _adminEmailController, label: 'Email', icon: Icons.email, inputFill: inputFill, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock,
          inputFill: inputFill,
          isPassword: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 24),
        _primaryButton(label: "ACCEDI", onPressed: _submitEmailAuth),
      ],
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────────

  Widget _primaryButton({required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
          : Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 13)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color inputFill,
    bool isPassword = false,
    bool enabled = true,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(color: enabled ? Colors.white : Colors.white38),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white12),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.8)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white54)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
