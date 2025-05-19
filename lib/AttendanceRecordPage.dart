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
      final courseData = data[widget.course];
      if (courseData == null) return null;

      return {
        'Attendance Level': courseData['Attendance Level'] ?? 0,
        'Last Attended': courseData['Last Attended'],
        'Attendance History': courseData['Attendance History'] ?? [],
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

    final doc = await recordRef.get();
    if (!doc.exists) return;

    final courseData = doc.data()![widget.course] as Map<String, dynamic>;
    final history = List<dynamic>.from(courseData['Attendance History'] ?? []);

    if (history.isEmpty) return;

    final lastAttendance = history.last;
    final newLevel = (currentLevel - 1).clamp(0, currentLevel);

    await recordRef.update({
      '${widget.course}.Attendance Level': newLevel,
      '${widget.course}.Attendance History': FieldValue.arrayRemove([lastAttendance]),
      '${widget.course}.Last Attended': history.length > 1 ? history[history.length - 2] : null
    });

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
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: Text('Close', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          );
        },
      );
    });

    setState(() {
      _hasDeletedOnce = true;
      _attendanceData = _fetchAttendanceData();
    });
  }

  @override
  Widget build(BuildContext context) {
    const totalClasses = 20;
    return Scaffold(
      extendBody: true,
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

            // pick a GIF & message based on perc
            String gifPath;
            String message;

            if (perc >= 100) {
              gifPath = 'assets/gifs/goku_5.gif';
              message = "Perfect! You're Super Saiyan strong!";
            } else if (perc >= 80) {
              gifPath = 'assets/gifs/goku_4.gif';
              message = "Awesome! Keep powering up!";
            } else if (perc >= 60) {
              gifPath = 'assets/gifs/goku_3.gif';
              message = "Great job! Almost there!";
            } else if (perc >= 40) {
              gifPath = 'assets/gifs/goku_2.gif';
              message = "Nice start! Train harder!";
            } else {
              gifPath = 'assets/gifs/goku_1.gif';
              message = "Let’s power up! You can do it!";
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Text('Attendance Record', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 20),
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
                  ElevatedButton.icon(
                    onPressed: canDeleteNow ? () => _deleteLastAttendance(level) : null,
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: Text('Delete Last Attendance', style: GoogleFonts.poppins(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  ),

                  
                  // GIF & message
                  
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      // ← Center everything vertically
                      mainAxisAlignment: MainAxisAlignment.center,
                      // ← Center everything horizontally
                      crossAxisAlignment: CrossAxisAlignment.center,
                       children: [
                        Image.asset(gifPath),
                        const SizedBox(height: 16),
                        Text(
                          message,
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
          color: header ? Colors.white : (isLeft ? const Color(0xFF4A148C) : const Color(0xFF6A1B9A)),
          fontStyle: header ? FontStyle.normal : FontStyle.italic,
        ),
      ),
    );
  }
}