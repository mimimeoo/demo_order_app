import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_colors.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 

import 'firebase_options.dart'; 
import 'providers/auth_provider.dart';
import 'providers/favorite_provider.dart'; 
import 'providers/cart_provider.dart'; 

import 'screens/home_screen.dart'; 
import 'screens/onboarding_screen.dart'; 
import 'admin/admin_dashboard_screen.dart'; 
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/setup_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MyApp(isFirstTime: isFirstTime),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/setup_profile': (context) =>  const SetupProfileScreen(phoneNumber: ''),
    '/home': (context) => const HomeScreen(),
  },
      title: 'BrewGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'GoogleSans',
              bodyColor: AppColors.textDark,
              displayColor: AppColors.textDark,
            ),
      ),
      home: isFirstTime ? const OnboardingScreen() : const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    
    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primaryBright)));
    }

    
    if (authProvider.isLoggedIn && authProvider.isAdmin) {
      return const AdminDashboardScreen();
    }

    
    return const HomeScreen();
  }
}