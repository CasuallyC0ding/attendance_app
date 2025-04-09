import 'dart:async';

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
  final String targetDeviceAddress = 'BC:57:29:00:4B:3A';
  BluetoothDevice? _targetDevice;
  int _rssi = 0;
  bool _isScanning = false;
  String _status = 'Searching for device...';
  late StreamSubscription<List<ScanResult>> _scanSubscription;
  bool _attendanceTaken = false; // Add this new state variable

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    try {
      // 1. Check if Bluetooth is enabled
      if (!await FlutterBluePlus.isAvailable) {
        throw Exception("Bluetooth not supported");
      }
      if (!await FlutterBluePlus.isOn) {
        throw Exception("Bluetooth is off");
      }

      // 2. Android 12+ permissions
      if (await Permission.bluetoothScan.request().isDenied ||
          await Permission.bluetoothConnect.request().isDenied ||
          await Permission.location.request().isDenied) {
        throw Exception("Permissions denied");
      }

      setState(() {
        _isScanning = true;
        _status = "Scanning...";
        _attendanceTaken = false; // Reset when starting new scan
      });

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        bool foundDevice = false;
        
        for (ScanResult result in results) {
          String deviceId = result.device.remoteId.toString().toUpperCase();
          String targetId = targetDeviceAddress.replaceAll(':', '').toUpperCase();
          
          if (deviceId == targetId) {
            foundDevice = true;
            setState(() {
              _rssi = result.rssi;
              if (!_attendanceTaken) {
                _status = 'Attendance Taken';
                _attendanceTaken = true;
              }
            });
          }
        }

        if (!foundDevice && _attendanceTaken) {
          setState(() {
            _status = 'Device out of range';
          });
        }
      });

      // Start continuous scan without timeout
      await FlutterBluePlus.startScan();
    } catch (e) {
      setState(() => _status = _parseError(e));
    } finally {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      setState(() => _isScanning = false);
    }
  }

  String _parseError(dynamic error) {
    String message = error.toString();
    if (message.contains("PlatformException(3")) {
      return "Bluetooth is disabled";
    } else if (message.contains("Permissions denied")) {
      return "Enable Bluetooth permissions";
    } else {
      return "Error: ${error.toString().split(':').last.trim()}";
    }
  }
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6A1B9A);
    const Color accentColor = Color(0xFF00BFA5);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 40,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bluetooth, size: 50, color: primaryColor),
                      const SizedBox(height: 25),
                      Text(
                        'Attendance System',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 35),
                      _buildStatusIndicator(),
                      const SizedBox(height: 25),
                      Text(
                        'RSSI: $_rssi',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isScanning)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(),
            ),
          const SizedBox(width: 15),
          Text(
            _status,
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanSubscription.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
