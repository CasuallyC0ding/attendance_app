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
  late Future<List<Timestamp>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<Timestamp>> _fetchHistory() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final snap = await FirebaseFirestore.instance
        .collection('Attendance Record')
        .doc(uid)
        .get();

    if (!snap.exists) return [];

    final data = snap.data()!;
    final courseMap = data[widget.course] as Map<String, dynamic>? ?? {};
    final raw = courseMap['Attendance History'] as List<dynamic>? ?? [];
    return raw
        .where((e) => e is Timestamp)
        .map((e) => e as Timestamp)
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first
  }

  String _format(Timestamp ts) {
    final d = ts.toDate();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} '
           '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width * 0.9;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        leading: const BackButton(color: Colors.white),
        title: Text('${widget.course} History', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<Timestamp>>(
          future: _historyFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return Center(
                child: Text(
                  'No attendance records yet.',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            final rows = list.map((ts) {
              final parts = _format(ts).split(' ');
              return DataRow(cells: [
                DataCell(Text(parts[0], style: GoogleFonts.poppins())),
                DataCell(Text(parts[1], style: GoogleFonts.poppins())),
              ]);
            }).toList();

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 8,
                  child: Container(
                    width: screenWidth,
                    padding: const EdgeInsets.all(16),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFF4A148C).withOpacity(0.9)),
                      headingTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                      dataTextStyle: GoogleFonts.poppins(color: Colors.black87),
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Time')),
                      ],
                      rows: rows,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
