import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/auth/loginPage.dart';
import 'services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting Patra Dating App...');

  try {
    // Initialize configuration first
    await ConfigService.initialize();
    print('✅ Configuration loaded successfully!');

    // Initialize Firebase
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('🔥 Firebase initialized successfully!');
    } else {
      print('🔥 Firebase already initialized!');
    }

    // Validate configuration
    ConfigService.validateConfiguration();

    runApp(const MyApp());
  } catch (e) {
    print('❌ Error during app initialization: $e');
    runApp(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Configuration Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Failed to initialize app'),
              Text('Error: $e'),
              SizedBox(height: 16),
              Text('Please check your .env and api_keys.env files'),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Patra',
      theme: ThemeData(primarySwatch: Colors.grey),
      home: LoginPage(),
    );
  }
}
