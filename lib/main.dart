import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app/lifelink_app.dart';
import 'features/chat/chat_controller.dart';
import 'features/chat/firebase_chat_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ChatController(FirebaseChatService()),
      child: const LifeLinkApp(),
    ),
  );
}