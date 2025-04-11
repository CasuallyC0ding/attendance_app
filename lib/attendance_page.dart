import 'dart:async';
import 'package:attendance_app/take_attendance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final String targetMac = 'BC:57:29:00:4B:3A';
  final Map<String, ScanResult> _devices = {};
  bool _scanning = false;
  bool _attendanceTaken = false;
  StreamSubscription<List<ScanResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request(); // required for Android BLE
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _attendanceTaken = false;
      _devices.clear();
    });

    _subscription = FlutterBluePlus.scanResults.listen((results) {
      for (var result in results) {
        final id = result.device.remoteId.str.toUpperCase();
        setState(() {
          _devices[id] = result;
        });

        if (id == targetMac.toUpperCase() && !_attendanceTaken) {
          _giveAttendance(result);
        }
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    setState(() => _scanning = false);
  }

  Future<void> _giveAttendance(ScanResult result) async {
    _attendanceTaken = true;
    await FlutterBluePlus.stopScan();
    await _subscription?.cancel();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceSuccessPage(
          macAddress: result.device.remoteId.str,
          rssi: result.rssi,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceList = _devices.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Attendance System'),
        actions: [
          IconButton(
            icon: Icon(_scanning ? Icons.stop : Icons.search),
            onPressed: _scanning ? FlutterBluePlus.stopScan : _startScan,
          )
        ],
      ),
      body: Column(
        children: [
          if (_attendanceTaken)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '✅ Attendance taken',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: deviceList.length,
              itemBuilder: (context, index) {
                final result = deviceList[index].value;
                final id = result.device.remoteId.str;
                final name = result.device.platformName.isNotEmpty
                    ? result.device.platformName
                    : "Unknown Device";
                final rssi = result.rssi;

                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(name, style: GoogleFonts.poppins()),
                  subtitle: Text('$id\nRSSI: $rssi dBm'),
                  isThreeLine: true,
                  tileColor: id.toUpperCase() == targetMac.toUpperCase()
                      ? Colors.green.withOpacity(0.1)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
