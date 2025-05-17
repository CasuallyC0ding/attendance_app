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
    final doc = await FirebaseFirestore.instance
        .collection('Attendance Record')
        .doc(user.uid)
        .get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final map = <String, String>{};
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final mac = (value['MAC Address'] ?? '').toString().toUpperCase();
        if (mac.isNotEmpty && mac != '0' && mac != '1') {
          map[mac] = key;
        }
      }
    });

    setState(() => _macToCourse = map);
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
      '$courseCode.Attendance Level': FieldValue.increment(1),
      '$courseCode.Last Attended': FieldValue.serverTimestamp(),
    });

    // Add history under a subcollection
    await docRef.collection('Attendance History').add({
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _startScan() async {
    devices.clear();
    setState(() => isScanning = true);

    await FlutterBluePlus.stopScan();
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    _scanSubscription =
        FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (var result in results) {
        final mac = result.device.remoteId.id.toUpperCase();
        if (_macToCourse.containsKey(mac)) {
          FlutterBluePlus.stopScan();
          _scanSubscription?.cancel();
          setState(() => isScanning = false);
          _onBeaconFound(result);
          return;
        }
        if (!devices.any((d) => d.device.remoteId.id == mac)) {
          setState(() => devices.add(result));
        }
      }
    });
  }

  Future<void> _onBeaconFound(ScanResult result) async {
    final courseCode = _macToCourse[result.device.remoteId.id.toUpperCase()]!;
    final device = result.device;
    const insideRssiThreshold = -70;

    try {
      await device.connect(timeout: const Duration(seconds: 300));
      int lastRssi = result.rssi;
      Timer rssiPoller = Timer.periodic(const Duration(seconds: 5), (_) async {
        lastRssi = await device.readRssi();
      });

      await Future.delayed(const Duration(seconds: 20));

      await Future(() => rssiPoller.cancel());
      
      if (lastRssi >= insideRssiThreshold) {
        await _updateAttendanceFor(courseCode);

        final beacon = Beacon(
          mac: result.device.remoteId.id,
          distance: _calculateDistance(lastRssi),
          power: lastRssi.toDouble(),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceSuccessPage(
              scannedBeacons: [beacon],       // <-- wrap in list
              timestamp: DateTime.now(),      // <-- timestamp param
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Move closer to the beacon to check in.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    } finally {
      await device.disconnect();
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  double _calculateDistance(int rssi) {
    const txPower = -69;
    const pathLossExponent = 2;
    return pow(10, (txPower - rssi) / (10 * pathLossExponent)).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.event_available, color: Colors.white),
            const SizedBox(width: 8),
            Text('The Attender', style: GoogleFonts.poppins()),
          ],
        ),
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
              Text('Nearby Devices', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: isScanning ? null : _startScan,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text('Start Scan', style: GoogleFonts.poppins()),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.deepPurple),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (_, i) {
                      final r = devices[i];
                      final d = _calculateDistance(r.rssi).toStringAsFixed(2);
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(r.device.name.isNotEmpty ? r.device.name : 'Unknown', style: GoogleFonts.poppins()),
                        subtitle: Text('MAC: ${r.device.remoteId.id}\nDist: $d m', style: GoogleFonts.poppins(fontSize: 13)),
                        trailing: Text('RSSI: ${r.rssi}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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