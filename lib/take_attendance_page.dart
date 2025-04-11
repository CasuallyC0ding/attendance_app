import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AttendanceSuccessPage extends StatelessWidget {
  final String mac;
  final double distance;
  final DateTime timestamp;

  const AttendanceSuccessPage({
    super.key,
    required this.mac,
    required this.distance,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

    return Scaffold(
      backgroundColor: const Color(0xFF6A1B9A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'You are good to go!',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const Icon(Icons.check_circle,
                    size: 100, color: Colors.greenAccent),
                const SizedBox(height: 40),
                _infoCard('Device MAC', mac),
                _infoCard('Time', formattedTime),
                _infoCard('Distance', '${distance.toStringAsFixed(2)} meters'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        '$title: $value',
        style: GoogleFonts.poppins(fontSize: 18, color: Colors.black87),
        textAlign: TextAlign.center,
      ),
    );
  }
}
