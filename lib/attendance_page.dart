import 'dart:async';
import 'dart:math';
import 'package:attendance_app/take_attendance_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {
  // Configuration
  final int scanWindow = 20;             // seconds
  final int rssiThreshold = -60;         // dBm

  // State
  bool isScanning = false;
  bool isCounting = false;               // phase‑2 timer running
  int timerSeconds = 20;
  int? currentRssi;                      // last read RSSI
  double avgRssi = 0;                    // running average
  final List<int> readings = [];

  late String targetMac;
  late String courseCode;
  Map<String, String> macToCourse = {};
  Beacon? lastBeacon;

  // Animation for tap circle
  late AnimationController glowController;
  late Animation<double> glowAnimation;

  StreamSubscription<List<ScanResult>>? scanSub;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadMacCourseMap();

    glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    glowController.dispose();
    scanSub?.cancel();
    countdownTimer?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse
    ].request();
  }

  Future<void> _loadMacCourseMap() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('Attendance Record')
        .doc(user.uid)
        .get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final map = <String, String>{};
    data.forEach((course, val) {
      if (val is Map<String, dynamic>) {
        final mac = (val['MAC Address'] ?? '').toString().toUpperCase();
        if (mac.isNotEmpty) map[mac] = course;
      }
    });

    setState(() => macToCourse = map);
  }

  Future<void> _updateAttendance(String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    await FirebaseFirestore.instance
        .collection('Attendance Record')
        .doc(user.uid)
        .update({
      '$code.Attendance Level': FieldValue.increment(1),
      '$code.Last Attended': FieldValue.serverTimestamp(),
      '$code.Attendance History': FieldValue.arrayUnion([now]),
    });
  }

  void _startScan() async {
    if (isScanning || macToCourse.isEmpty) return;

    // Light haptic
    if (await Vibration.hasVibrator() ?? false) Vibration.vibrate(duration: 100);

    setState(() {
      isScanning = true;
      isCounting = false;
      timerSeconds = scanWindow;
      readings.clear();
      currentRssi = null;
      avgRssi = 0;
      lastBeacon = null;
      glowController.stop();
    });

    FlutterBluePlus.startScan(
      timeout: Duration(seconds: scanWindow * 2),
      // allowDuplicates: true,
      // scanMode: ScanMode.lowLatency,
    );

    scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (var r in results) {
        final mac = r.device.remoteId.id.toUpperCase();

        // Phase 1: lock on first known beacon
        if (!isCounting && macToCourse.containsKey(mac)) {
          setState(() {
            isCounting = true;
            targetMac = mac;
            courseCode = macToCourse[mac]!;
          });
          _startCountdown();
          break;
        }

        // Phase 2: collect RSSI for locked beacon
        if (isCounting && mac == targetMac) {
          setState(() {
            currentRssi = r.rssi;
            readings.add(r.rssi);
            avgRssi = readings.reduce((a, b) => a + b) / readings.length;
            // store lastBeacon for navigation
            final dist = pow(10, (-69 - r.rssi) / (10 * 2)).toDouble();
            lastBeacon = Beacon(mac: mac, distance: dist, power: r.rssi.toDouble());
          });
          break;
        }
      }
    });
  }

  void _startCountdown() {
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timerSeconds <= 0) {
        t.cancel();
        _finishScan();
      } else {
        setState(() => timerSeconds--);
      }
    });
  }

  void _finishScan() async {
  await FlutterBluePlus.stopScan();
  await scanSub?.cancel();

  if (lastBeacon == null) {
    // Never saw a registered beacon
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No registered beacon found')),
    );

  } else if (avgRssi >= rssiThreshold) {
    // Strong enough on average!
    await _updateAttendance(courseCode);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceSuccessPage(
          scannedBeacons: [lastBeacon!],
          timestamp: DateTime.now(),
        ),
      ),
    );

  } else {
    // Averaged below threshold
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Avg RSSI too low: ${avgRssi.toStringAsFixed(1)} dBm'),
      ),
    );
  }

  // Reset UI state
  setState(() {
    isScanning  = false;
    isCounting  = false;
    glowController.repeat(reverse: true);
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        leading: BackButton(),
        title: Text('The Attender', style: GoogleFonts.poppins()),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status / live RSSI / average
              Text(
                isScanning
                    ? (isCounting
                        ? 'Measuring $targetMac\nRSSI: ${currentRssi ?? '-'} dBm\nAvg: ${avgRssi.toStringAsFixed(1)} dBm'
                        : 'Searching for any registered beacon…')
                    : 'Tap to start scanning',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              // Timer or glowing button
              if (isCounting)
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: timerSeconds / scanWindow,
                        strokeWidth: 12,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                      Text('$timerSeconds',
                          style: GoogleFonts.poppins(
                              fontSize: 48, color: Colors.white)),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: _startScan,
                  child: AnimatedBuilder(
                    animation: glowAnimation,
                    builder: (_, __) => Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.white.withOpacity(glowAnimation.value * .7),
                            spreadRadius: 12 * glowAnimation.value,
                            blurRadius: 24 * glowAnimation.value,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text('Tap to Scan',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: const Color(0xFF4A148C))),
                      ),
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
