import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/plugin/module_registry.dart';
import 'features/vitals/vitals_plugin.dart';

void main() async {
  // Ensure engine is bound before initialization services
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1. Register active health modules
  ModuleRegistry.instance.registerModule(VitalsPlugin());

  // 2. Boot up core dependency containers, database connections, and configurations
  await setupLocator();

  // 3. Launch App UI
  runApp(const VitalApp());
}

