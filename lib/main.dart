import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart'; 
import 'theme/app_colors.dart';
import 'theme/app_theme.dart'; 

import 'providers/auth_provider.dart';
import 'providers/favorite_provider.dart'; 
import 'providers/cart_provider.dart'; 

import 'screens/home_screen.dart'; 
import 'admin/admin_dashboard_screen.dart'; 
import 'screens/login_screen.dart';
import 'screens/user_info_screen.dart'; 
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final isFirstTime = prefs.getBool('isFirstTime') ?? true;
  
  runApp(AppInit(isFirstTime: isFirstTime));
}

class AppInit extends StatelessWidget {
  final bool isFirstTime;
  const AppInit({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(body: Center(child: Text('Lỗi Firebase:\n${snapshot.error}'))),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => FavoriteProvider()),
              ChangeNotifierProvider(create: (_) => CartProvider()),
            ],
            child: MyApp(isFirstTime: isFirstTime), 
          );
        }
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator(color: AppColors.primary))),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BrewGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/setup_profile': (context) => const UserInfoScreen(),
        '/home': (context) => const HomeScreen(),
      },
      home: AuthWrapper(isFirstTime: isFirstTime),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final bool isFirstTime;
  const AuthWrapper({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // ✅ BỎ ĐOẠN CHECK isLoading Ở ĐÂY ĐỂ TRÁNH LỖI HỦY DIỆT MÀN HÌNH LOGIN KHI GỬI OTP
    
    // Nếu là lần đầu mở app -> Vào màn hình Onboarding
    if (isFirstTime) {
      return const OnboardingScreen();
    }

    // Nếu là Admin -> Vào trang quản trị
    if (authProvider.isLoggedIn && authProvider.isAdmin) {
      return const AdminDashboardScreen();
    }

    // ✅ Luôn luôn vào HomeScreen mặc định (Cho cả Khách chưa Login và User đã Login)
    return const HomeScreen();
  }
}