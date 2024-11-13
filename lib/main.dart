import 'package:flutter/material.dart';
import 'package:alc_eljadida_tests/screens/instruction_page.dart';
import 'package:alc_eljadida_tests/screens/registration_page.dart';
import 'package:alc_eljadida_tests/services/auth_service.dart';
import 'package:media_kit/media_kit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _authService = AuthService();

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Language Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<bool>(
        future: _authService.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2193b0),
                ),
              ),
            );
          }

          if (snapshot.data == true) {
            return InstructionPage();
          }

          return RegistrationPage();
        },
      ),
    );
  }
}