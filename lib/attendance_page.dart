import 'dart:async';
import 'dart:math';
import 'package:attendance_app/take_attendance_page.dart';
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
  final String targetMac = 'BC:57:29:00:4B:3A';
  bool isScanning = false;
  List<ScanResult> devices = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  Future<void> _startScan() async {
    devices.clear();
    setState(() => isScanning = true);

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        final mac = result.device.remoteId.str.toUpperCase();
        if (mac == targetMac.toUpperCase()) {
          FlutterBluePlus.stopScan();
          setState(() => isScanning = false);

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
          return;
        }

        if (!devices.any((d) => d.device.remoteId == result.device.remoteId)) {
          setState(() => devices.add(result));
        }
      }
    });
  }

  double _calculateDistance(int rssi) {
    const txPower = -69;
    const n = 2;
    return pow(10, (txPower - rssi) / (10 * n)).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      final distance =
                          _calculateDistance(device.rssi).toStringAsFixed(2);
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
