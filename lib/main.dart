import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jasaku_app/providers/auth_provider.dart';
import 'package:jasaku_app/providers/wishlist_provider.dart';
import 'package:jasaku_app/screens/auth/login_screen.dart';
import 'package:jasaku_app/screens/home/home_screen.dart';
import 'package:jasaku_app/screens/chat/chat_list_screen.dart';
import 'package:jasaku_app/screens/chat/chat_detail_screen.dart';
import 'package:jasaku_app/screens/profile/profile_screen.dart';
import 'package:jasaku_app/screens/service/service_detail_screen.dart';
import 'package:jasaku_app/screens/search/search_screen.dart';
import 'package:jasaku_app/providers/services_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => ServicesProvider()),
      ],
      child: MaterialApp(
        title: 'Jasaku App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Inter',
        ),
        home: AuthWrapper(),
        routes: {
          '/home': (context) => HomeScreen(),
          '/search': (context) => SearchScreen(),
          '/chat': (context) => ChatListScreen(),
          '/chat-detail': (context) => ChatDetailScreen(contactName: 'Andy Wijaya'),
          '/profile': (context) => ProfileScreen(),
          '/service-detail': (context) => ServiceDetailScreen(),
          '/login': (context) => LoginScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Check login status saat pertama kali
    if (authProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        authProvider.checkLoginStatus();
      });
      
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Memuat...'),
            ],
          ),
        ),
      );
    }

    // Jika sudah login, langsung ke Home, jika belum ke Login
    return authProvider.isLoggedIn ? HomeScreen() : LoginScreen();
  }
}