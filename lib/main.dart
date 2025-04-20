
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:attendance_app/firebase_options.dart';

import 'HomePage.dart';
import 'LogInPage.dart';
import 'AttendanceTrackerPage.dart';
import 'creat_account_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
    // You might want to show an error screen here
  }
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Attender',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => const LogInPage(),
        '/createAccount': (context) => const CreateAccountPage(),
        '/attendanceTracker': (context) => const AttendanceTrackerPage(),
        '/attendanceTrack': (context) => const AttendanceTrackerPage(),
      },
    );
  }
}











