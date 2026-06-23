import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de Hive para almacenamiento local
  await Hive.initFlutter();
  await Hive.openBox('channels_box');
  await Hive.openBox('profiles_box');
  
  // Inicialización de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: TajamarTvApp(),
    ),
  );
}
