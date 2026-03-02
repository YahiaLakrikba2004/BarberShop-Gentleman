import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';


enum AuthStep { phone, otp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  // Phone Auth Controllers
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController(); 
  final _surnameController = TextEditingController(); // [NEW] Surname
  final _profileEmailController = TextEditingController(); // [NEW] Optional Email

  // Email Auth Controllers (Legacy/Fallback)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _rotationController;
  
  // State
  final AuthStep _authStep = AuthStep.phone;
  bool _isEmailMode = false;
  bool _isLogin = true; 
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isNewUser = false; // [NEW] Track if user needs to register

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
    _nameController.dispose();
    _surnameController.dispose();
    _profileEmailController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- Phone Auth Logic ---



  Future<void> _verifyPhoneNumber() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showError("Inserisci il numero di telefono");
      return;
    }

    if (_isNewUser) {
       // --- REGISTER FLOW ---
       if (_nameController.text.trim().isEmpty || _surnameController.text.trim().isEmpty) {
         _showError("Nome e Cognome sono obbligatori");
         return;
       }

       setState(() => _isLoading = true);
       try {
          final authService = ref.read(authServiceProvider);
          // Deterministic Creds
          String formattedPhone = phone.startsWith('+') ? phone : '+39$phone';
          String cleanPhone = formattedPhone.replaceAll(RegExp(r'\D'), '');
          String fakeEmail = '$cleanPhone@gentleman.app';
          String fakePassword = 'UserPass$cleanPhone!';

          // Se l'utente fornisce una email reale, usa quella come email Auth
          // (così l'account è raggiungibile anche via email reale)
          final realEmail = _profileEmailController.text.trim();
          final authEmail = realEmail.isNotEmpty ? realEmail : fakeEmail;

          // Combine Name + Surname
          String fullName = "${_nameController.text.trim()} ${_surnameController.text.trim()}";

          // Register usando l'email reale se fornita, altrimenti il fake
          await authService.signUpWithEmailAndPassword(
            email: authEmail,
            password: fakePassword,
            name: fullName,
            phoneNumber: phone,
          );

          // Check Migration
          final currentUser = authService.currentUser;
          if (currentUser != null) {
            await _checkAndMigrate(currentUser, phone);
          }
          
          if (mounted) context.go('/');

       } catch (e) {
         _showError("Errore registrazione: $e");
         setState(() => _isLoading = false);
       }

    } else {
      // --- CHECK / LOGIN FLOW ---
      // For now, simplify flow: Just Anonymous Login + Phone assignment
      // (As requested: "basta mettere il numero")
      
      // Check format
      String formattedPhone = phone;
      if (!phone.startsWith('+')) {
        formattedPhone = '+39$phone';
      }

      setState(() => _isLoading = true);

      try {
        final authService = ref.read(authServiceProvider);
        // GENERATE DETERMINISTIC EMAIL/PASSWORD from Phone
        // This bypasses the need for Anonymous Auth (which is disabled) and OTP (which is skipped).
        String cleanPhone = formattedPhone.replaceAll(RegExp(r'\D'), ''); // Remove + and spaces
        String fakeEmail = '$cleanPhone@gentleman.app';
        String fakePassword = 'UserPass$cleanPhone!'; // Simple deterministic password

        try {
          // 1. Try Login
          await authService.signInWithEmailAndPassword(fakeEmail, fakePassword);
          
          // Login Success
          final currentUser = authService.currentUser;
          if (currentUser != null) {
             await _checkAndMigrate(currentUser, phone);
          }
           if (mounted) context.go('/');

        } catch (e) {
          // 2. CHECK IF USER REALLY EXISTS
          // INVALID_LOGIN_CREDENTIALS can mean "User Not Found" OR "Wrong Password".
          // We need to know which one it is.
          
          bool userExistsInAuth = false;
          try {
             final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(fakeEmail);
             userExistsInAuth = methods.isNotEmpty;
          } catch (checkErr) {
             // If this fails (e.g. strict protection), we might assume new user???
             // Or maybe we treat it as generic error.
          }

          if (!userExistsInAuth) {
             // User not found with fake email — check if registered with real email
             try {
               final firestore = ref.read(firestoreServiceProvider);
               final existing = await firestore.getUserByPhone(formattedPhone);
               if (existing != null &&
                   existing.email.isNotEmpty &&
                   !existing.email.endsWith('@gentleman.app')) {
                 // Trovato: prova login con email reale + stessa password deterministica
                 await authService.signInWithEmailAndPassword(existing.email, fakePassword);
                 final currentUser = authService.currentUser;
                 if (currentUser != null) await _checkAndMigrate(currentUser, phone);
                 if (mounted) context.go('/');
                 return;
               }
             } catch (_) {}

             // Nessun account trovato → Registrazione
             if (mounted) {
               setState(() {
                 _isLoading = false;
                 _isNewUser = true;
               });
             }
             return;
          } else {
             // User EXISTS but Login Failed -> Password Mismatch / corrupted account
             // We cannot register again (it will fail with email-in-use).
             // We must inform the user.
             _showError("Errore account: Password interna non valida. Contattare supporto o riprovare.");
             setState(() => _isLoading = false);
             return;
          }
        }

      } catch (e) {
        _showError("Errore accesso: $e");
        setState(() => _isLoading = false);
      }
    }
  }





  // --- Email Auth Logic (Legacy) ---


  Future<void> _submitEmailAuth() async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        await authService.signInWithEmailAndPassword(email, password);
      } else {
        // Register
        await authService.signUpWithEmailAndPassword(
          email: email,
          password: password,
          name: _nameController.text.trim(), // Reusing name controller
          phoneNumber: _phoneController.text.trim(), // Optional/Required?
        );
      }
      if (mounted) context.go('/');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC143C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const goldColor = Colors.white; // Changed from Gold to White as per request
    const darkBlack = Color(0xFF0A0A0A);
    const inputFill = Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: darkBlack,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF161616), // Dark center
              Color(0xFF000000), // Pure black edges
            ],
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
                  // Logo (Same as before)
                  FadeInDown(
                    child: Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.08),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Image.asset('assets/images/icon_premium_v2.png', fit: BoxFit.contain), // Assuming this asset exists
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  Text(
                    'GENTLEMAN',
                    style: GoogleFonts.cinzel(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'BARBER SHOP',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white54,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // MAIN AUTH CONTENT
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _isEmailMode ? _buildEmailAuth(goldColor, inputFill) : _buildPhoneAuth(goldColor, inputFill),
                  ),

                  const SizedBox(height: 40),

                  // TOGGLE BUTTON (Phone <-> Email)
                  if (!_isEmailMode && _authStep == AuthStep.phone)
                    TextButton(
                      onPressed: () => setState(() => _isEmailMode = true),
                      child: const Text("Usa Email e Password", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                  
                  if (_isEmailMode)
                    TextButton(
                      onPressed: () => setState(() => _isEmailMode = false),
                      child: const Text("Usa Numero di Telefono", style: TextStyle(color: goldColor, fontSize: 12)),
                    ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneAuth(Color goldColor, Color inputFill) {
    return Column(
      children: [
        if (_isNewUser)
          Text(
            "COMPLETA REGISTRAZIONE",
            style: GoogleFonts.cinzel(color: Colors.white, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold),
          )
        else
          Text(
            "ACCEDI CON TELEFONO",
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14, letterSpacing: 1),
          ),
        
        const SizedBox(height: 20),
        
        // PHONE INPUT (Always visible, locked in registration phase)
        _buildTextField(
          controller: _phoneController,
          label: 'Numero di Telefono',
          icon: Icons.phone_android,
          goldColor: goldColor,
          fillColor: inputFill,
          keyboardType: TextInputType.phone,
          hint: "333 1234567",
          enabled: !_isNewUser,
        ),

        // ANIMATED REGISTRATION FIELDS
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          child: _isNewUser 
            ? Column(
                children: [
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       Expanded(
                         child: _buildTextField(
                           controller: _nameController,
                           label: 'Nome',
                           icon: Icons.person,
                           goldColor: goldColor,
                           fillColor: inputFill,
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: _buildTextField(
                           controller: _surnameController,
                           label: 'Cognome',
                           icon: Icons.person_outline,
                           goldColor: goldColor,
                           fillColor: inputFill,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                   _buildTextField(
                      controller: _profileEmailController,
                      label: 'Email (Opzionale)',
                      icon: Icons.email_outlined,
                      goldColor: goldColor,
                      fillColor: inputFill,
                      keyboardType: TextInputType.emailAddress,
                   ),
                ],
              ) 
            : const SizedBox.shrink(),
        ),

         const SizedBox(height: 24),
         
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyPhoneNumber,
            style: ElevatedButton.styleFrom(
              backgroundColor: goldColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
              ? const CircularProgressIndicator(color: Colors.black)
              : Text(
                  _isNewUser ? "REGISTRATI" : "AVANTI",
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
          ),
        ),
        
        // Back button if in Registration mode
        if (_isNewUser)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton(
              onPressed: () {
                 setState(() {
                   _isNewUser = false;
                 });
              },
              child: const Text("Annulla", style: TextStyle(color: Colors.white54)),
            ),
          )
      ],
    );
  }

  Widget _buildEmailAuth(Color goldColor, Color inputFill) {
    return Column(
      children: [
         // LOGIN / REGISTER TABS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _authTab("ACCEDI", _isLogin, () => setState(() => _isLogin = true), goldColor),
            const SizedBox(width: 20),
            _authTab("REGISTRATI", !_isLogin, () => setState(() => _isLogin = false), goldColor),
          ],
        ),
        const SizedBox(height: 30),

        if (!_isLogin) ...[
          _buildTextField(
             controller: _nameController,
             label: 'Nome Completo',
             icon: Icons.person,
             goldColor: goldColor,
             fillColor: inputFill
          ),
          const SizedBox(height: 16),
          _buildTextField(
             controller: _phoneController, // Reusing phone controller
             label: 'Telefono',
             icon: Icons.phone,
             goldColor: goldColor,
             fillColor: inputFill
          ),
           const SizedBox(height: 16),
        ],

        _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            goldColor: goldColor,
            fillColor: inputFill
        ),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock,
            goldColor: goldColor,
            fillColor: inputFill,
            isPassword: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
        ),
        
        const SizedBox(height: 24),
         SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitEmailAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24, // Subtle for secondary
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_isLogin ? "ACCEDI CON EMAIL" : "REGISTRATI", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _authTab(String title, bool isActive, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(title, style: TextStyle(
            color: isActive ? color : Colors.white24,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 1
          )),
          const SizedBox(height: 4),
          if (isActive) Container(height: 2, width: 40, color: color)
        ],
      ),
    );
  }

   Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color goldColor,
    required Color fillColor,
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
      cursorColor: goldColor,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white12),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: goldColor.withOpacity(0.8)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: goldColor)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
  Future<void> _checkAndMigrate(User currentUser, String inputPhone) async {
    try {
      final firestore = ref.read(firestoreServiceProvider);

      // Formatted +39
      String formatted = inputPhone.startsWith('+') ? inputPhone : '+39$inputPhone';

      // 1. Search by formatted (+39...)
      UserModel? oldUser = await firestore.getUserByPhone(formatted, excludeUserId: currentUser.uid);

      // 2. Search by raw input
      if (oldUser == null && inputPhone != formatted) {
        oldUser = await firestore.getUserByPhone(inputPhone, excludeUserId: currentUser.uid);
      }

      // 3. Search by stripped digits
      if (oldUser == null) {
        final stripped = inputPhone.replaceAll(RegExp(r'\D'), '');
        if (stripped.isNotEmpty) {
           oldUser = await firestore.getUserByPhone(stripped, excludeUserId: currentUser.uid);
        }
      }

      // If found AND it's a different ID than current (dangling profile)
      if (oldUser != null && oldUser.id != currentUser.uid) {
        // Found a dangling old profile! Migrate it to this current account.
        await firestore.migrateUser(oldUser.id, currentUser.uid);
      }
    } catch (e) {
      print("Migration Check Failed: $e");
    }
  }
}
