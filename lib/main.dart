import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import 'app/lifelink_app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before the app starts
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const LifeLinkApp());
}