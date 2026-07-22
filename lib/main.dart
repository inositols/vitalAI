import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/plugin/module_registry.dart';
import 'features/vitals/vitals_plugin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ModuleRegistry.instance.registerModule(VitalsPlugin());
  await setupLocator();

  runApp(const VitalApp());
}
