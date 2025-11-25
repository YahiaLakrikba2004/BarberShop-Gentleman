import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance, ref.read(firestoreServiceProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
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
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      final newUser = UserModel(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        role: UserRole.client, // Default role
      );
      await _firestoreService.createUser(newUser);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
