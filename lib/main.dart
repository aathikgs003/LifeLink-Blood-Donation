import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/service_providers.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('📦 Initializing Services...');
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Fix for "Offline" issue on Web
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    
    print('🚀 Firebase Ready');
    runApp(
      const ProviderScope(
        child: LifeLinkApp(),
      ),
    );
  } catch (e) {
    print('❌ Initialization Error: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Startup Error: $e\n\nPlease check your Firebase configuration.'),
          ),
        ),
      ),
    );
  }
}

class LifeLinkApp extends ConsumerStatefulWidget {
  const LifeLinkApp({super.key});

  @override
  ConsumerState<LifeLinkApp> createState() => _LifeLinkAppState();
}

class _LifeLinkAppState extends ConsumerState<LifeLinkApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(pushNotificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LifeLink',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      routerConfig: AppRoutes.router,
    );
  }
}
