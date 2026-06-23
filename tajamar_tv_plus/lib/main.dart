import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialización de Hive para almacenamiento local
  await Hive.initFlutter();
  await Hive.openBox('channels_box');
  await Hive.openBox('profiles_box');
  
  // Inicialización de Firebase (comentado hasta tener firebase_options.dart)
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(
    const ProviderScope(
      child: TajamarTvApp(),
    ),
  );
}
