import 'package:attendance_app/AttendanceHistoryPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AttendanceTrackerPage.dart';

class AttendanceRecordPage extends StatefulWidget {
  final String course;

  const AttendanceRecordPage({Key? key, required this.course}) : super(key: key);

  @override
  _AttendanceRecordPageState createState() => _AttendanceRecordPageState();
}

class _AttendanceRecordPageState extends State<AttendanceRecordPage> {
  bool _hasDeletedOnce = false;
  late Future<Map<String, dynamic>?> _attendanceData;

  @override
  void initState() {
    super.initState();
    _attendanceData = _fetchAttendanceData();
  }

  Future<Map<String, dynamic>?> _fetchAttendanceData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Attendance Record')
          .doc(currentUser.uid)
          .get();

      if (!doc.exists) return null;
      final data = doc.data()!;
      final courseData = data[widget.course]
          ?? data[widget.course.toUpperCase()]
          ?? data[widget.course.toLowerCase()];
      if (courseData == null) return null;

      return {
        'Attendance Level': courseData['Attendance Level'] ?? 0,
        'Last Attended': courseData['Last Attended'],
      };
    } catch (_) {
      return null;
    }
  }

  String _formatLastAttended(Timestamp? timestamp) {
    if (timestamp == null) return 'Never attended';
    final d = timestamp.toDate();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  double _percentage(int attended, int total) {
    return total > 0 ? attended / total * 100 : 0;
  }

Future<void> _deleteLastAttendance(int currentLevel) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final recordRef = FirebaseFirestore.instance
      .collection('Attendance Record')
      .doc(user.uid);

  // 1) Read the whole document once
  final snap = await recordRef.get();
  if (!snap.exists) return;

  final data = snap.data()![widget.course] as Map<String, dynamic>? ?? {};
  // Pull the history array (or empty list if missing)
  final historyList = List<Timestamp>.from(
    (data['Attendance History'] as List<dynamic>? ?? [])
        .whereType<Timestamp>(),
  );
  if (historyList.isEmpty) return;  // nothing to delete

  // 2) Identify last and second‑last timestamps
  final lastTs = historyList.removeLast();
  final newLastTs = historyList.isNotEmpty ? historyList.last : null;

  // 3) Batch‑update:
  final batch = FirebaseFirestore.instance.batch();
  batch.update(recordRef, {
    // decrement level, never below 0
    '${widget.course}.Attendance Level':
       (currentLevel - 1).clamp(0, double.infinity).toInt(),
    // set new Last Attended (or null)
    '${widget.course}.Last Attended': newLastTs,
    // remove the last timestamp from the array
    '${widget.course}.Attendance History':
      FieldValue.arrayRemove([lastTs]),
  });

  // 4) Commit & refresh UI
  await batch.commit();


  // Defer the dialog until after this frame, and ensure widget is still mounted
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF6A1B9A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Deleted', style: GoogleFonts.poppins(color: Colors.white)),
          content: Text(
            'Last attendance record removed successfully.',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (Navigator.of(dialogCtx).canPop()) Navigator.of(dialogCtx).pop();
              },
              child: Text('Close', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  });

  // Finally update your UI state
  if (!mounted) return;

  // REFRESH UI
  setState(() {
    _hasDeletedOnce = true;
    _attendanceData = _fetchAttendanceData();
  });
}


  @override
  Widget build(BuildContext context) {
    const totalClasses = 20;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceTrackerPage()),
          ),
        ),
        title: Text('The Attender', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
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
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _attendanceData,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snap.data;
            if (data == null) {
              return Center(
                child: Text('Could not load attendance.', style: GoogleFonts.poppins(color: Colors.white70)),
              );
            }

            final level = data['Attendance Level'] as int;
            final last = data['Last Attended'] as Timestamp?;
            final perc = _percentage(level, totalClasses);
            final canDelete = last != null && DateTime.now().difference(last.toDate()).inMinutes <= 15;
            final canDeleteNow = canDelete && !_hasDeletedOnce && level > 0;


            String gif;
            String msg;
            if (perc >= 100) {
              gif = 'assets/gifs/goku_5.gif';
              msg = "Perfect! You're Super Saiyan strong!";
            } else if (perc >= 80) {
              gif = 'assets/gifs/goku_4.gif';
              msg = "Awesome! Keep powering up!";
            } else if (perc >= 60) {
              gif = 'assets/gifs/goku_3.gif';
              msg = "Great job! Almost there!";
            } else if (perc >= 40) {
              gif = 'assets/gifs/goku_2.gif';
              msg = "Nice start! Train harder!";
            } else {
              gif = 'assets/gifs/goku_1.gif';
              msg = "Let’s power up! You can do it!";
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Text('Attendance Record', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
                  // Summary table
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1.5)},
                      children: [
                        _buildRow('Category', 'Details', isHeader: true),
                        _buildRow('Subject', widget.course),
                        _buildRow('Attendance Level', '$level/$totalClasses'),
                        _buildRow('Last Attended', _formatLastAttended(last)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // View history button
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AttendanceHistoryPage(course: widget.course)),
                    ),
                    icon: const Icon(Icons.history, color: Colors.white),
                    label: Text('View History', style: GoogleFonts.poppins(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
                  ),
                  const SizedBox(height: 10),
                  // Delete button
                  ElevatedButton.icon(
                    onPressed: canDeleteNow ? () => _deleteLastAttendance(level) : null,
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: Text('Delete Last Attendance', style: GoogleFonts.poppins(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  ),
                  const SizedBox(height: 30),
                  // GIF & message
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(15)),
                    child: Column(
                       children: [
                        Image.asset(gif),
                        const SizedBox(height: 16),
                        Text(
                          msg,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${perc.toStringAsFixed(1)}% attendance',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  TableRow _buildRow(String a, String b, {bool isHeader = false}) {
    final bg = isHeader ? const Color(0xFF4A148C).withOpacity(0.8) : Colors.transparent;
    return TableRow(
      decoration: BoxDecoration(color: bg),
      children: [
        _cell(a, isHeader, isLeft: true),
        _cell(b, isHeader, isLeft: false),
      ],
    );
  }

  Widget _cell(String txt, bool header, {required bool isLeft}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      color: !header && isLeft ? const Color(0xFF6A1B9A).withOpacity(0.1) : null,
      child: Text(
        txt,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: header ? 16 : 14,
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
          color: header
              ? Colors.white
              : (isLeft ? const Color(0xFF4A148C) : const Color(0xFF6A1B9A)),
          fontStyle: header ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }
}
