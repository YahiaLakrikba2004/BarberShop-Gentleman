import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../firebase_options.dart';

final appInitializationProvider = FutureProvider<void>((ref) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await initializeDateFormatting('it_IT', null);
    
  } catch (e, stack) {
    debugPrint('App Initialization Error: $e');
    debugPrint(stack.toString());
    rethrow;
  }
});