import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AttendanceTrackerPage.dart';

class AttendanceRecordPage extends StatelessWidget {
  final String course;

  const AttendanceRecordPage({Key? key, required this.course}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AttendanceTrackerPage()),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available,
                  color: Colors.white,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Text(
                  'The Attender',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Title outside the white box
              Padding(
                padding: const EdgeInsets.only(top: 30, bottom: 20),
                child: Text(
                  'Attendance Record',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // White box containing the table
              Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(0), // Remove padding here
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1.5),
                    },
                    children: [
                      // Table Header - Dark purple
                      TableRow(
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A148C).withOpacity(0.8),
                        ),
                        children: [
                          _buildTableCell('Category', true, true),
                          _buildTableCell('Details', true, false),
                        ],
                      ),
                      // Subject Row - Left cell light purple
                      TableRow(
                        children: [
                          Container(
                            color: const Color(0xFF6A1B9A).withOpacity(0.1),
                            child: _buildTableCell('Subject', false, true),
                          ),
                          _buildTableCell(course, false, false),
                        ],
                      ),
                      // Attendance Level Row - Left cell light purple
                      TableRow(
                        children: [
                          Container(
                            color: const Color(0xFF6A1B9A).withOpacity(0.1),
                            child: _buildTableCell('Attendance Level', false, true),
                          ),
                          _buildTableCell('85% (17/20 classes)', false, false),
                        ],
                      ),
                      // Last Attended Row - Left cell light purple
                      TableRow(
                        children: [
                          Container(
                            color: const Color(0xFF6A1B9A).withOpacity(0.1),
                            child: _buildTableCell('Last Attended', false, true),
                          ),
                          _buildTableCell('2023-11-15', false, false),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Text at bottom outside the white box
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Opacity(
                  opacity: 0.7,
                  child: Text(
                    'Detailed attendance records for $course',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, bool isHeader, bool isLeftCell) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: isHeader ? 16 : 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.white :
          (isLeftCell ? const Color(0xFF4A148C) : const Color(0xFF6A1B9A)),
          fontStyle: isLeftCell ? FontStyle.italic : FontStyle.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}