import 'package:flutter/material.dart';
import 'package:test_windows_students/screens/home_page.dart';
import 'package:test_windows_students/screens/registration_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Remove the home property and use routes instead
      initialRoute: '/',
      routes: {
        '/': (context) => const RegistrationPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
