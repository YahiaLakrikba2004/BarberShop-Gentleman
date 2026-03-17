import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService();
});

class MessagingService {
  
  /// Opens WhatsApp with a pre-filled message.
  /// 
  /// [phoneNumber] should include the country code (e.g., "+393331234567").
  /// If the phone number is missing the country code, we can defaulting to Italy (+39) for this specific app context.
  Future<void> sendWhatsAppMessage(String phoneNumber, String message) async {
    // Basic sanitization
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');

    // Default to +39 if no country code (Project specific assumption: Italy)
    if (!cleanPhone.startsWith('+')) {
      cleanPhone = '+39$cleanPhone';
    }

    // WhatsApp URL Scheme
    // android: https://wa.me/number?text=text
    // ios: https://api.whatsapp.com/send?phone=number&text=text
    // universal: https://wa.me/number?text=text usually works for both if app is installed
    
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUrl = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (kDebugMode) debugPrint("Could not launch WhatsApp for $cleanPhone");
        // Fallback or error handling
      }
    } catch (e) {
      if (kDebugMode) debugPrint("Error launching WhatsApp: $e");
    }
  }

  /// Opens the default SMS app with a pre-filled message.
  Future<void> sendSMS(String phoneNumber, String message) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');
    
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(smsLaunchUri)) {
        await launchUrl(smsLaunchUri);
      } else {
         if (kDebugMode) debugPrint("Could not launch SMS");
      }
    } catch (e) {
       if (kDebugMode) debugPrint("Error launching SMS: $e");
    }
  }
}
