import 'dart:async';
import 'dart:math';
import 'package:attendance_app/take_attendance_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  // holds MAC → courseCode
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Map<String, String> _macToCourse = {};
  bool isScanning = false;
  List<ScanResult> devices = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadMacCourseMap();
  }

  Future<void> _loadMacCourseMap() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('Attendance Record')
            .doc(user.uid)
            .get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final map = <String, String>{};
    data.forEach((courseCode, courseDataRaw) {
      final courseData = Map<String, dynamic>.from(courseDataRaw);
      final mac = (courseData['MAC Address'] ?? '').toString().toUpperCase();
      if (mac.isNotEmpty && mac != '0' && mac != '1') {
        map[mac] = courseCode;
      }
    });

    setState(() => _macToCourse = map);
    print('Loaded MAC→Course map: $_macToCourse');
  }

  Future<void> _checkPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  Future<void> _updateAttendanceFor(String courseCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('Attendance Record')
        .doc(user.uid);

    await docRef.update({
      // FieldValue.increment(1) adds 1 to whatever the current counter is
      '$courseCode.Attendance Level': FieldValue.increment(1),
      '$courseCode.Last Attended': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _startScan() async {
    // Clear out any old state
    devices.clear();
    setState(() => isScanning = true);

    // Make sure any previous scan is stopped
    await FlutterBluePlus.stopScan();

    // Kick off the scan with a timeout
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    // Listen exactly once
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final mac = result.device.remoteId.str.toUpperCase();
        if (_macToCourse.containsKey(mac)) {
          final course = _macToCourse[mac]!;

          // Stop scanning and clean up
          FlutterBluePlus.stopScan();
          _scanSubscription?.cancel();
          setState(() => isScanning = false);

          // Navigate & update
          final distance = _calculateDistance(result.rssi);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AttendanceSuccessPage(
                mac: mac,
                distance: distance,
                timestamp: DateTime.now(),
              ),
            ),
          );
          _updateAttendanceFor(course);
          return;
        }

        // Otherwise show device in the list
        if (!devices.any((d) => d.device.remoteId == result.device.remoteId)) {
          setState(() => devices.add(result));
        }
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  double _calculateDistance(int rssi) {
    const txPower = -69;
    const n = 2;
    return pow(10, (txPower - rssi) / (10 * n)).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(
                  Icons.event_available,
                  color: Colors.white,
                  size: 24,
                ),
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
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                'Nearby Devices',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: isScanning ? null : _startScan,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text('Start Scan', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final distance = _calculateDistance(
                        device.rssi,
                      ).toStringAsFixed(2);
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(
                          device.device.platformName.isNotEmpty
                              ? device.device.platformName
                              : 'Unknown Device',
                          style: GoogleFonts.poppins(),
                        ),
                        subtitle: Text(
                          'MAC: ${device.device.remoteId.str}\nEst. Distance: $distance m',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'RSSI: ${device.rssi}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
