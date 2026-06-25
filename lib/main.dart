import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'app/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && Platform.isWindows) {
    fvp.registerWith();
  }
  
  // Inicialización de Hive para almacenamiento local
  await Hive.initFlutter();
  await Hive.openBox('channels_box');
  await Hive.openBox('profiles_box');
  
  // Inicialización de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const YouTVPlayApp(),
    ),
  );
}
