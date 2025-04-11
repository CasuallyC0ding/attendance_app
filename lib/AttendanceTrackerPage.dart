/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'HomePage.dart';
import 'constants.dart';
import 'AttendanceRecordPage.dart';
import 'Take_Attendence.dart';

class AttendanceTrackerPage extends StatefulWidget {
  const AttendanceTrackerPage({super.key});

  @override
  _AttendanceTrackerPageState createState() => _AttendanceTrackerPageState();
}

class _AttendanceTrackerPageState extends State<AttendanceTrackerPage> {
  String selectedCourse = 'COMM604';
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _getCurrentUserEmail();
  }
  void _getCurrentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
    }
  }


  void navigateToAttendanceRecord(String course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceRecordPage(course: course),
      ),
    );
  }

  void navigateToTakeAttend(String course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeAttendence(selectedCourse: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.event_available, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'The Attender',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: isSmallScreen ? 500 : 600),
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 20.0 : 30.0),
                      decoration: BoxDecoration(
                        color: Color (0xFF00BFA5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Attendance Tracker',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 22 : 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6A1B9A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_circle,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: isSmallScreen ? 180 : 250,
                          child: Text(
                            globalEmail.isNotEmpty
                                ? globalEmail
                                : 'No email set',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          context,
                          'Take Attendance',
                          Icons.check,
                              () => navigateToTakeAttend(selectedCourse),
                        ),
                        SizedBox(width: isSmallScreen ? 16 : 24),
                        _buildActionButton(
                          context,
                          'Attendance Review',
                          Icons.history,
                              () => navigateToAttendanceRecord(selectedCourse),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Courses',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: isSmallScreen ? 180 : 220,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: Color (0xFF6A1B9A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: Color (0xFF6A1B9A),
                        iconEnabledColor: Colors.white,
                        iconSize: isSmallScreen ? 24 : 28,
                        underline: const SizedBox(),
                        value: selectedCourse,
                        items: const [
                          DropdownMenuItem(value: 'COMM604', child: Text('COMM604')),
                          DropdownMenuItem(value: 'NETW603', child: Text('NETW603')),
                          DropdownMenuItem(value: 'MNGT601', child: Text('MNGT601')),
                          DropdownMenuItem(value: 'NETW703', child: Text('NETW703')),
                          DropdownMenuItem(value: 'NETW707', child: Text('NETW707')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCourse = value!;
                          });
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                          );
                        },
                        icon: const Icon(Icons.home, size: 20,color: Colors.white),
                        label: Text(
                          "Log out",
                          style: GoogleFonts.poppins(fontSize: 14,color:Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 10.0 : 12.0,
                            horizontal: isSmallScreen ? 16.0 : 24.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return Container(
      width: 150,
      height: 150,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
              backgroundColor: Color (0xFF6A1B9A),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}*/
import 'package:attendance_app/attendance_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'HomePage.dart';
import 'AttendanceRecordPage.dart';
//import 'take_attendance_page.dart';

class AttendanceTrackerPage extends StatefulWidget {
  const AttendanceTrackerPage({super.key});

  @override
  _AttendanceTrackerPageState createState() => _AttendanceTrackerPageState();
}

class _AttendanceTrackerPageState extends State<AttendanceTrackerPage> {
  String selectedCourse = 'COMM604';
  String? _userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUserEmail();
  }

  void _getCurrentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void navigateToAttendanceRecord(String course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceRecordPage(course: course),
      ),
    );
  }

  void navigateToTakeAttend(String course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendancePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          if (_userEmail != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 100,
                    child: Text(
                      _userEmail!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.event_available, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'The Attender',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: isSmallScreen ? 500 : 600),
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 20.0 : 30.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Attendance Tracker',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 22 : 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6A1B9A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_circle,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: isSmallScreen ? 180 : 250,
                          child: Text(
                            _userEmail ?? 'No email set',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActionButton(
                          context,
                          'Take Attendance',
                          Icons.check,
                              () => navigateToTakeAttend(selectedCourse),
                        ),
                        SizedBox(width: isSmallScreen ? 16 : 24),
                        _buildActionButton(
                          context,
                          'Attendance Review',
                          Icons.history,
                              () => navigateToAttendanceRecord(selectedCourse),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Courses',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: isSmallScreen ? 180 : 220,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A1B9A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        isExpanded: true,
                        dropdownColor: const Color(0xFF6A1B9A),
                        iconEnabledColor: Colors.white,
                        iconSize: isSmallScreen ? 24 : 28,
                        underline: const SizedBox(),
                        value: selectedCourse,
                        items: const [
                          DropdownMenuItem(value: 'COMM604', child: Text('COMM604', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'NETW603', child: Text('NETW603', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'MNGT601', child: Text('MNGT601', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'NETW703', child: Text('NETW703', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'NETW707', child: Text('NETW707', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCourse = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _signOut,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.logout, size: 20, color: Colors.white),
                        label: Text(
                          _isLoading ? "Logging out..." : "Log out",
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 10.0 : 12.0,
                            horizontal: isSmallScreen ? 16.0 : 24.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onPressed,
      ) {
    return Container(
      width: 150,
      height: 150,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
              backgroundColor: const Color(0xFF6A1B9A),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}
