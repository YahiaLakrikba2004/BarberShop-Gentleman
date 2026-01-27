class AdminConfig {
  static const List<String> allowedAdminEmails = [
    'thegentlemanshop059@gmail.com',
  ];

  static const String shopEmail = 'thegentlemanshop059@gmail.com';

  static bool isAllowedAdmin(String email) {
    return allowedAdminEmails.contains(email.toLowerCase());
  }

  static bool isShopAccount(String email) {
    return email.toLowerCase() == shopEmail.toLowerCase();
  }
}
