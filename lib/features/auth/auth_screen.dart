import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

enum _AuthStep { phone, otp, register, email }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  // Phone Auth
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // Registration
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _profileEmailController = TextEditingController();

  // Email Auth (fallback admin)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _rotationController;

  _AuthStep _step = _AuthStep.phone;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEmailLoginMode = false; // toggle for admin email fallback

  // OTP state
  String? _verificationId;
  int? _resendToken;
  User? _firebaseUser; // signed-in user after OTP, before profile save

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    _nameController.dispose();
    _surnameController.dispose();
    _profileEmailController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Step 1: Send OTP ───────────────────────────────────────────────────────

  Future<void> _sendOtp({bool isResend = false}) async {
    final raw = _phoneController.text.trim();
    if (raw.isEmpty) {
      _showError("Inserisci il numero di telefono");
      return;
    }
    final phone = raw.startsWith('+') ? raw : '+39$raw';

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: isResend ? _resendToken : null,
        verificationCompleted: (credential) async {
          // Auto-verification (Android only): sign in immediately
          await _signInWithCredential(credential);
        },
        verificationFailed: (e) {
          _showError(_mapFirebaseError(e));
          setState(() => _isLoading = false);
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _step = _AuthStep.otp;
            _isLoading = false;
          });
          // Focus first OTP field
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted) _otpFocusNodes[0].requestFocus();
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showError("Errore: $e");
      setState(() => _isLoading = false);
    }
  }

  // ─── Step 2: Verify OTP ─────────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      _showError("Inserisci il codice a 6 cifre");
      return;
    }
    if (_verificationId == null) {
      _showError("Sessione scaduta. Riprova.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _showError(_mapFirebaseError(e));
      setState(() => _isLoading = false);
    } catch (e) {
      _showError("Errore verifica: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithCredential(AuthCredential credential) async {
    final authService = ref.read(authServiceProvider);
    await authService.signInWithCredential(credential);

    final user = authService.currentUser;
    if (user == null) {
      _showError("Autenticazione fallita");
      setState(() => _isLoading = false);
      return;
    }

    // Check if profile exists in Firestore
    final firestore = ref.read(firestoreServiceProvider);
    final profile = await firestore.getUser(user.uid);

    if (profile != null) {
      // Existing user → go home
      if (mounted) context.go('/');
    } else {
      // New user → show registration form
      _firebaseUser = user;
      setState(() {
        _step = _AuthStep.register;
        _isLoading = false;
      });
    }
  }

  // ─── Step 3: Complete Registration ──────────────────────────────────────────

  Future<void> _completeRegistration() async {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    if (name.isEmpty || surname.isEmpty) {
      _showError("Nome e Cognome sono obbligatori");
      return;
    }

    final user = _firebaseUser ?? ref.read(authServiceProvider).currentUser;
    if (user == null) {
      _showError("Sessione scaduta. Riprova dall'inizio.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = ref.read(firestoreServiceProvider);
      final phone = _phoneController.text.trim();
      final formatted = phone.startsWith('+') ? phone : '+39$phone';
      final email = _profileEmailController.text.trim();

      final newUser = UserModel(
        id: user.uid,
        email: email,
        name: '$name $surname',
        role: UserRole.client,
        phoneNumber: formatted,
      );
      await firestore.createUser(newUser);

      if (mounted) context.go('/');
    } catch (e) {
      _showError("Errore registrazione: $e");
      setState(() => _isLoading = false);
    }
  }

  // ─── Email Auth (Admin fallback) ────────────────────────────────────────────

  Future<void> _submitEmailAuth() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) context.go('/');
    } catch (e) {
      _showError(_mapFirebaseError(e is FirebaseAuthException ? e : null, fallback: e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  String _mapFirebaseError(FirebaseAuthException? e, {String? fallback}) {
    switch (e?.code) {
      case 'invalid-phone-number': return 'Numero di telefono non valido';
      case 'too-many-requests': return 'Troppi tentativi. Riprova tra qualche minuto';
      case 'invalid-verification-code': return 'Codice non corretto. Riprova';
      case 'session-expired': return 'Sessione scaduta. Reinserisci il numero';
      case 'user-not-found': return 'Nessun account trovato';
      case 'wrong-password': return 'Password errata';
      default: return fallback ?? (e?.message ?? 'Errore sconosciuto');
    }
  }

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
      _verificationId = null;
      _firebaseUser = null;
      for (final c in _otpControllers) { c.clear(); }
    });
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const inputFill = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF161616), Color(0xFF000000)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
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
                  Text('GENTLEMAN', style: GoogleFonts.cinzel(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 4)),
                  const SizedBox(height: 8),
                  Text('BARBER SHOP', style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white54, letterSpacing: 6)),
                  const SizedBox(height: 50),

                  // Main content
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutQuart,
                    child: _buildCurrentStep(inputFill),
                  ),

                  const SizedBox(height: 32),

                  // Toggle email fallback (only on phone step)
                  if (_step == _AuthStep.phone)
                    TextButton(
                      onPressed: () => setState(() => _isEmailLoginMode = !_isEmailLoginMode),
                      child: Text(
                        _isEmailLoginMode ? "Usa Numero di Telefono" : "Usa Email e Password",
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(Color inputFill) {
    if (_isEmailLoginMode && _step == _AuthStep.phone) {
      return _buildEmailAuth(inputFill);
    }
    switch (_step) {
      case _AuthStep.phone:   return _buildPhoneStep(inputFill);
      case _AuthStep.otp:     return _buildOtpStep(inputFill);
      case _AuthStep.register: return _buildRegisterStep(inputFill);
      case _AuthStep.email:   return _buildEmailAuth(inputFill);
    }
  }

  // ─── Phone Step ──────────────────────────────────────────────────────────────

  Widget _buildPhoneStep(Color inputFill) {
    return Column(
      children: [
        Text("INSERISCI IL TUO NUMERO",
          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Text("Ti invieremo un codice SMS per verificare la tua identità",
          style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11),
          textAlign: TextAlign.center),
        const SizedBox(height: 24),
        _buildPhoneField(inputFill),
        const SizedBox(height: 24),
        _primaryButton(
          label: "INVIA CODICE SMS",
          onPressed: _sendOtp,
        ),
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
          // Prefix "+39"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Text(
              '🇮🇹  +39',
              style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          // Number input (only local digits)
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

  // ─── OTP Step ────────────────────────────────────────────────────────────────

  Widget _buildOtpStep(Color inputFill) {
    final phone = _phoneController.text.trim();
    final display = phone.startsWith('+') ? phone : '+39$phone';

    return Column(
      children: [
        const Icon(Icons.sms_outlined, color: Colors.white54, size: 40),
        const SizedBox(height: 16),
        Text("CODICE DI VERIFICA",
          style: GoogleFonts.cinzel(color: Colors.white, fontSize: 16, letterSpacing: 2)),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12),
            children: [
              const TextSpan(text: "Abbiamo inviato un SMS a\n"),
              TextSpan(text: display, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 6-digit OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) => _otpBox(i)),
        ),
        const SizedBox(height: 28),

        _primaryButton(
          label: "VERIFICA",
          onPressed: _verifyOtp,
        ),
        const SizedBox(height: 16),

        // Resend + Change number
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _isLoading ? null : () => _sendOtp(isResend: true),
              child: const Text("Reinvia codice", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
            const Text("·", style: TextStyle(color: Colors.white24)),
            TextButton(
              onPressed: _isLoading ? null : _resetToPhone,
              child: const Text("Cambia numero", style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _otpBox(int index) {
    return Container(
      width: 42,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: GoogleFonts.montserrat(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (val) {
          if (!mounted) return;
          if (val.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          // Auto-submit when all 6 digits entered
          if (_otpControllers.every((c) => c.text.isNotEmpty)) {
            _verifyOtp();
          }
        },
      ),
    );
  }

  // ─── Register Step ───────────────────────────────────────────────────────────

  Widget _buildRegisterStep(Color inputFill) {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 40),
        const SizedBox(height: 16),
        Text("NUMERO VERIFICATO",
          style: GoogleFonts.cinzel(color: Colors.white, fontSize: 16, letterSpacing: 2)),
        const SizedBox(height: 6),
        Text("Completa il tuo profilo per continuare",
          style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 28),

        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: _nameController, label: 'Nome', icon: Icons.person, inputFill: inputFill),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(controller: _surnameController, label: 'Cognome', icon: Icons.person_outline, inputFill: inputFill),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _profileEmailController,
          label: 'Email (Opzionale)',
          icon: Icons.email_outlined,
          inputFill: inputFill,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        _primaryButton(label: "CREA PROFILO", onPressed: _completeRegistration),
      ],
    );
  }

  // ─── Email Auth (Admin fallback) ─────────────────────────────────────────────

  Widget _buildEmailAuth(Color inputFill) {
    return Column(
      children: [
        Text("ACCESSO ADMIN",
          style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 13, letterSpacing: 1.5)),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          inputFill: inputFill,
          keyboardType: TextInputType.emailAddress,
        ),
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

  // ─── Shared Widgets ──────────────────────────────────────────────────────────

  Widget _primaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
          : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
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
