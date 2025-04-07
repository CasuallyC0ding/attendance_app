import 'package:flutter/material.dart';
import 'home_page.dart';
import 'sign_in_page.dart';
import 'create_account_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Attender',
      theme: ThemeData(primarySwatch: Colors.deepPurple, fontFamily: 'Poppins'),
      // Use either home or initialRoute, not both
      home: const HomePage(),
      routes: {
        '/signin': (context) => const SignInPage(),
        '/createaccount': (context) => const CreateAccountPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
