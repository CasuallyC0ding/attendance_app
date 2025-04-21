import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AttendanceTrackerPage.dart';
import 'userDocService.dart';

class AttendanceRecordPage extends StatefulWidget {
  final String course;

  const AttendanceRecordPage({Key? key, required this.course}) : super(key: key);

  @override
  _AttendanceRecordPageState createState() => _AttendanceRecordPageState();
}

class _AttendanceRecordPageState extends State<AttendanceRecordPage> {
  late Future<Map<String, dynamic>?> _attendanceData;
  final String documentId = 'RePgzpGQJfSSVh5QJEMK'; // Your document ID

  @override
  void initState() {
    super.initState();
    _attendanceData = _fetchAttendanceData();
  }

Future<Map<String, dynamic>?> _fetchAttendanceData() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('Attendance Record')
        .doc(documentId)
        .get();

    if (!doc.exists) {
      print('Document does not exist');
      return null;
    }

    final data = doc.data();
    if (data == null) {
      print('Document data is null');
      return null;
    }

    // Try different field name variations
    final courseData = data[widget.course] ?? 
                     data[widget.course.toUpperCase()] ?? 
                     data[widget.course.toLowerCase()];

    if (courseData == null) {
      print('Course ${widget.course} not found in document. Available keys: ${data.keys}');
      return null;
    }

    // Ensure we have the required fields
    final result = {
      'Attendance Level': courseData['Attendance Level'] ?? courseData['attendance_level'] ?? 0,
      'Last Attended': courseData['Last Attended'] ?? courseData['last_attended'],
    };

    return result;
  } catch (e) {
    print('Error fetching data: $e');
    return null;
  }
}

  String _formatLastAttended(Timestamp? timestamp) {
    if (timestamp == null) return 'Never attended';
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _calculatePercentage(int? attended, int? total) {
    if (attended == null || total == null || total == 0) return '0% (0/0 classes)';
    final percentage = (attended / total * 100).round();
    return '$percentage% ($attended/$total classes)';
  }

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
                padding: const EdgeInsets.all(0),
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
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _attendanceData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return ClipRRect(
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
                            TableRow(
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A148C).withOpacity(0.8),
                              ),
                              children: [
                                _buildTableCell('Error', true, true),
                                _buildTableCell('Could not load data', true, false),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    final attendanceData = snapshot.data!;
                    final attendanceLevel = attendanceData['Attendance Level'] as int? ?? 0;
                    final lastAttended = attendanceData['Last Attended'] as Timestamp?;

                    return ClipRRect(
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
                              _buildTableCell(widget.course, false, false),
                            ],
                          ),
                          // Attendance Level Row - Left cell light purple
                          TableRow(
                            children: [
                              Container(
                                color: const Color(0xFF6A1B9A).withOpacity(0.1),
                                child: _buildTableCell('Attendance Level', false, true),
                              ),
                              _buildTableCell(
                                _calculatePercentage(attendanceLevel, 20), // Assuming 20 is total classes
                                false, 
                                false
                              ),
                            ],
                          ),
                          // Last Attended Row - Left cell light purple
                          TableRow(
                            children: [
                              Container(
                                color: const Color(0xFF6A1B9A).withOpacity(0.1),
                                child: _buildTableCell('Last Attended', false, true),
                              ),
                              _buildTableCell(
                                _formatLastAttended(lastAttended),
                                false, 
                                false
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Text at bottom outside the white box
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Opacity(
                  opacity: 0.7,
                  child: Text(
                    'Detailed attendance records for ${widget.course}',
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