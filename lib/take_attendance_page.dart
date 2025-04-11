import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceSuccessPage extends StatelessWidget {
  final String macAddress;
  final int rssi;

  const AttendanceSuccessPage({
    super.key,
    required this.macAddress,
    required this.rssi,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Confirmed')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🎉 Attendance successfully taken!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text('Device MAC: $macAddress', style: GoogleFonts.poppins()),
            Text('Signal Strength: $rssi dBm', style: GoogleFonts.poppins()),
            const SizedBox(height: 40),
            Center(
              child: Icon(Icons.check_circle, color: Colors.green, size: 80),
            ),
          ],
        ),
      ),
    );
  }
}
