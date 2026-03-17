import 'package:firebase_auth/firebase_auth.dart';

/// Translates Firebase exceptions into user-friendly Italian messages.
///
/// Usage:
/// ```dart
/// try {
///   await authService.signIn(...);
/// } on FirebaseAuthException catch (e) {
///   final msg = FirebaseErrorHandler.auth(e);
///   showSnackBar(msg);
/// } catch (e) {
///   final msg = FirebaseErrorHandler.generic(e);
///   showSnackBar(msg);
/// }
/// ```
class FirebaseErrorHandler {
  FirebaseErrorHandler._();

  /// Translates a [FirebaseAuthException] to a readable Italian string.
  static String auth(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'invalid-credential':
        return 'Email o password non corretti.';
      case 'wrong-password':
        return 'Password errata. Riprova.';
      case 'email-already-in-use':
        return 'Questa email è già registrata.';
      case 'weak-password':
        return 'La password è troppo debole (minimo 6 caratteri).';
      case 'invalid-email':
        return 'Indirizzo email non valido.';
      case 'user-disabled':
        return 'Account disabilitato. Contatta il supporto.';
      case 'too-many-requests':
        return 'Troppi tentativi. Riprova tra qualche minuto.';
      case 'network-request-failed':
        return 'Nessuna connessione internet. Verifica la rete.';
      case 'requires-recent-login':
        return 'Per motivi di sicurezza, effettua nuovamente il login.';
      case 'operation-not-allowed':
        return 'Operazione non consentita.';
      case 'expired-action-code':
        return 'Il codice è scaduto. Richiedi un nuovo link.';
      case 'invalid-action-code':
        return 'Codice non valido. Richiedi un nuovo link.';
      case 'session-expired':
        return 'Sessione scaduta. Richiedi un nuovo codice.';
      case 'invalid-verification-code':
        return 'Codice di verifica non valido.';
      case 'quota-exceeded':
        return 'Limite di invii SMS raggiunto. Riprova più tardi.';
      default:
        return e.message ?? 'Errore di autenticazione. Riprova.';
    }
  }

  /// Translates a [FirebaseException] (Firestore, Storage, etc.) to Italian.
  static String firestore(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Permesso negato. Non hai i diritti per questa operazione.';
      case 'not-found':
        return 'Documento non trovato.';
      case 'already-exists':
        return 'Il documento esiste già.';
      case 'resource-exhausted':
        return 'Limite di richieste raggiunto. Riprova tra poco.';
      case 'unavailable':
      case 'network-request-failed':
        return 'Servizio non disponibile. Verifica la connessione.';
      case 'deadline-exceeded':
        return 'Operazione scaduta. Riprova.';
      default:
        return e.message ?? 'Errore del database. Riprova.';
    }
  }

  /// Fallback for any other exception type.
  static String generic(Object e) {
    if (e is FirebaseAuthException) return auth(e);
    if (e is FirebaseException) return firestore(e);
    return 'Si è verificato un errore. Riprova.';
  }
}
