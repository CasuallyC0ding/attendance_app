import 'package:attendance_app/firebase_options.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'sign_in_page.dart';
import 'create_account_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );
  runApp(const MyApp());
  //runApp(DevicePreview(builder: (context)=> const MyApp()));
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
