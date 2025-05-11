import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceHistoryPage extends StatefulWidget {
  final String course;
  const AttendanceHistoryPage({Key? key, required this.course}) : super(key: key);

  @override
  _AttendanceHistoryPageState createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  late Stream<QuerySnapshot> _historyStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    // assumes you stored history under subcollection: Courses/{course}/History
    _historyStream = FirebaseFirestore.instance
      .collection('Attendance Record')
      .doc(uid)
      .collection('Courses')
      .doc(widget.course)
      .collection('History')
      .orderBy('timestamp', descending: true)
      .snapshots();
  }

  String _formatTimestamp(Timestamp ts) {
    final dt = ts.toDate();
    return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} '
           '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        leading: BackButton(color: Colors.white),
        title: Text(
          '${widget.course} History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
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
        child: StreamBuilder<QuerySnapshot>(
          stream: _historyStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  'No attendance records yet.',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              );
            }

            // Build a simple table: Date | Time
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Date', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Time', style: GoogleFonts.poppins(fontWeight: FontWeight.bold))),
                  ],
                  rows: docs.map((d) {
                    final ts = d['timestamp'] as Timestamp;
                    final formatted = _formatTimestamp(ts);
                    final parts = formatted.split(' ');
                    return DataRow(cells: [
                      DataCell(Text(parts[0], style: GoogleFonts.poppins())),
                      DataCell(Text(parts[1], style: GoogleFonts.poppins())),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
