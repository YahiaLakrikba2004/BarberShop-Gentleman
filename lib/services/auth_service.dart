import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

import '../core/initialization.dart';
import '../config/admin_config.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, ref.read(firestoreServiceProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  final init = ref.watch(appInitializationProvider);
  if (!init.hasValue) return const Stream.empty();
  
  return ref.watch(authServiceProvider).authStateChanges;
});

// Provides the current logged-in user's profile from Firestore
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    yield* ref.watch(firestoreServiceProvider).getUserStream(user.uid);
  } else {
    yield null;
  }
});

class AuthService {
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  AuthService(this._auth, this._firestoreService);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    UserRole role = UserRole.client,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      final isShopAccount = AdminConfig.isShopAccount(email);
      // Shop Account is technically a Barber but acts as Admin in practice (Ghost Barber)
      // Allowed Admins get Admin role. Everyone else is Client.
      final role = isShopAccount ? UserRole.barber : AdminConfig.isAllowedAdmin(email) ? UserRole.admin : UserRole.client;

      final newUser = UserModel(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
      );
      await _firestoreService.createUser(newUser);

      // Special Case: Shop Account is ALSO a Barber (Hybrid)
      if (isShopAccount) {
        await _firestoreService.createBarberProfile(newUser, isBookable: false); // Not bookable
      }
    }
  }

  Future<void> createPhoneUser({
    required String uid,
    required String phoneNumber,
    required String name,
    UserRole role = UserRole.client,
  }) async {
    final newUser = UserModel(
      id: uid,
      email: '', // Phone auth users don't have email initially
      name: name,
      role: role,
      phoneNumber: phoneNumber,
    );
    await _firestoreService.createUser(newUser);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user != null && user.email != newEmail) {
      await user.verifyBeforeUpdateEmail(newEmail);
      // Also update Firestore to keep it in sync
      await _firestoreService.updateUserFields(user.uid, {'email': newEmail});
    }
  }

  Future<void> updateDisplayName(String newName) async {
    final user = _auth.currentUser;
    if (user != null && user.displayName != newName) {
      await user.updateDisplayName(newName);
      // Also update Firestore if needed (though ProfileScreen usually handles this)
      await _firestoreService.updateUserFields(user.uid, {'name': newName});
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete from Firestore first
      await _firestoreService.deleteUser(user.uid);
      // Delete from Firebase Auth
      await user.delete();
    }
  }
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  Future<void> signInWithCredential(AuthCredential credential) async {
    await _auth.signInWithCredential(credential);
  }

  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }
}
