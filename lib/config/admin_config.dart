/// Configurazione admin dell'app.
///
/// In produzione, passa le variabili tramite --dart-define:
///   flutter build apk \
///     --dart-define=ADMIN_EMAIL=tuaemail@esempio.com \
///     --dart-define=SHOP_EMAIL=tuaemail@esempio.com
///
/// Nell'IDE (VS Code), aggiungile in launch.json:
///   "args": ["--dart-define=ADMIN_EMAIL=...", "--dart-define=SHOP_EMAIL=..."]
class AdminConfig {
  static const String _adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: '', // Imposta tramite --dart-define in produzione
  );

  static const String _shopEmail = String.fromEnvironment(
    'SHOP_EMAIL',
    defaultValue: '', // Imposta tramite --dart-define in produzione
  );

  static List<String> get allowedAdminEmails =>
      _adminEmail.isNotEmpty ? [_adminEmail] : [];

  static String get shopEmail => _shopEmail;

  static bool isAllowedAdmin(String email) {
    if (_adminEmail.isEmpty) return false;
    return email.toLowerCase() == _adminEmail.toLowerCase();
  }

  static bool isShopAccount(String email) {
    if (_shopEmail.isEmpty) return false;
    return email.toLowerCase() == _shopEmail.toLowerCase();
  }
}
