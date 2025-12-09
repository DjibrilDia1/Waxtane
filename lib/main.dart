import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter_chat_service/Views/user_list_screen.dart';
import 'Views/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Chat',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3AB78D),
        ),
        useMaterial3: true,
      ),
      
      // IMPORTANT : Utiliser SOIT home, SOIT initialRoute + routes
      // Ici on utilise initialRoute + routes
      initialRoute: '/',
      
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/users': (context) => const UsersListScreen(),
      },
    );
  }
}

/// Widget qui gère l'authentification automatique
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // État de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement...'),
                ],
              ),
            ),
          );
        }
        
        // Utilisateur connecté
        if (snapshot.hasData && snapshot.data != null) {
          return const UsersListScreen();
        }
        
        // Utilisateur non connecté
        return const LoginScreen();
      },
    );
  }
}