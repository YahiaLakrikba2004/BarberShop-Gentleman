import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../firebase_options.dart';
import '../services/notification_service.dart';

final appInitializationProvider = FutureProvider<void>((ref) async {
  try {
    // 1. Load Environment Variables
    await dotenv.load(fileName: ".env");
    
    // 2. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. Initialize Date Formatting
    await initializeDateFormatting('it_IT', null);

    // 4. Initialize Notifications (can be done here or later, but here ensures it's ready)
    // We don't await this to avoid blocking if it takes time, unless critical.
    // For now, let's just register the background handler which is static.
    // The instance initialization happens in main or after login.
    
  } catch (e, stack) {
    debugPrint('App Initialization Error: $e');
    debugPrint(stack.toString());
    throw e; // Re-throw to let the UI handle the error state
  }
});
