import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:testsdk/pages/daily.dart';
import 'package:testsdk/pages/home_page.dart';
import 'package:testsdk/pages/login.dart';
import 'package:testsdk/pages/page1.dart';
import 'package:testsdk/pages/page2.dart';
import 'package:testsdk/pages/post_page.dart';
import 'package:testsdk/pages/sign_up_page.dart';
import 'package:testsdk/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String page1Route = '/page1';
  static const String page2Route = '/page2';
  static const String signUpRoute = '/signUp';
  static const String postRoute = '/post';
  static const String dailyRoute = '/daily';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        homeRoute: (context) => HomePage(),
        loginRoute: (context) => const LoginPage(),
        page1Route: (context) => Page1(),
        page2Route: (context) => Page2(),
        signUpRoute: (context) => const SignUpPage(),
        postRoute: (context) => const PostPage(userId: '',),
        dailyRoute: (context) => DailyChallengesPage(),
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const LoginPage();
          } else {
            return HomePage();
          }
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
