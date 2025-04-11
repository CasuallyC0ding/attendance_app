import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'AttendanceTrackerPage.dart';

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
        child: Stack(
          children: [
            // The Attender logo at top right
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: Colors.white, size: 30),
                  const SizedBox(width: 8),
                  Text(
                    'The Attender',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Home button at top left
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.home, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttendanceTrackerPage(),
                    ),
                        (route) => false,
                  );
                },
              ),
            ),

            // Main content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Attendance Marked Successfully!',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Success icon
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: const Icon(
                        Icons.check_circle,
                        size: 100,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Table container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(2),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          border: TableBorder.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                          children: [
                            // Header row
                            TableRow(
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A1B9A).withOpacity(0.8),
                              ),
                              children: [
                                _buildTableCell('Field', null, true),
                                _buildTableCell('Value', null, true),
                              ],
                            ),

                            // MAC Address row
                            TableRow(
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A1B9A).withOpacity(0.2),
                              ),
                              children: [
                                _buildTableCell('Device MAC', Icons.device_hub, false),
                                _buildTableCell(mac, null, false),
                              ],
                            ),

                            // Time row
                            TableRow(
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A1B9A).withOpacity(0.1),
                              ),
                              children: [
                                _buildTableCell('Time', Icons.access_time, false),
                                _buildTableCell(formattedTime, null, false),
                              ],
                            ),

                            // Distance row
                            TableRow(
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A1B9A).withOpacity(0.2),
                              ),
                              children: [
                                _buildTableCell('Distance', Icons.place, false),
                                _buildTableCell('${distance.toStringAsFixed(2)} meters', null, false),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, IconData? icon, bool isHeader) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: const Color(0xFF00BFA5)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.visible,
              style: GoogleFonts.poppins(
                fontSize: 14, // Reduced font size
                fontWeight: isHeader ? FontWeight.bold : (icon != null ? FontWeight.w600 : FontWeight.normal),
                color: isHeader ? Colors.white : (icon != null ? const Color(0xFF00BFA5) : const Color(0xFF4A148C)),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}