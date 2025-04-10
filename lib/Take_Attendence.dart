
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class TakeAttendence extends StatefulWidget {
  final String selectedCourse;

  const TakeAttendence({Key? key, required this.selectedCourse}) : super(key: key);

  @override
  State<TakeAttendence> createState() => _TakeAttendencePage();
}

class _TakeAttendencePage extends State<TakeAttendence> {
  final Map<String, String> _courseDevices = {
    'COMM604': 'BC:57:29:00:4B:3A',
    'NETW603': 'D4:36:39:DB:6F:7B',
    'MNGT601': 'E2:C7:9D:45:1F:2A',
    'NETW703': 'F8:A9:D0:3E:7C:51',
    'NETW707': '9B:24:58:EF:0D:6C',
  };

  BluetoothDevice? _targetDevice;
  int _rssi = 0;
  bool _isScanning = false;
  String _status = 'Searching for device...';
  List<ScanResult> _allDevices = [];

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndStartScan();
  }

  Future<void> _requestPermissionsAndStartScan() async {
    // Request location permission (required for BLE on Android)
    var status = await Permission.location.request();
    if (status.isGranted) {
      _startScan();
    } else {
      setState(() {
        _status = 'Location permission required for Bluetooth scanning';
      });
    }
  }

  Future<void> _startScan() async {
    try {
      setState(() {
        _isScanning = true;
        _status = 'Searching for ${widget.selectedCourse} device...';
        _allDevices.clear();
      });

      // Setup scan listener
      FlutterBluePlus.scanResults.listen((results) {
        final targetAddress = _courseDevices[widget.selectedCourse]?.replaceAll(':', '') ?? '';
        setState(() {
          _allDevices = results.where((result) => result.device.remoteId.str.isNotEmpty).toList();
        });

        for (ScanResult result in results) {
          if (result.device.remoteId.str.toUpperCase() == targetAddress) {
            setState(() {
              _targetDevice = result.device;
              _rssi = result.rssi;
              _status = 'Attendance Taken for ${widget.selectedCourse}';
            });
            FlutterBluePlus.stopScan();
            return;
          }
        }
      });

      // Start scan with timeout
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );

    } catch (e) {
      setState(() => _status = 'Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6A1B9A);
    const Color accentColor = Color(0xFF00BFA5);
    const Color purpleTextColor = Color(0xFF6A1B9A);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A148C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.event_available, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'The Attender',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.85,
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bluetooth, size: 40, color: primaryColor),
                      const SizedBox(height: 20),
                      Text(
                        '${widget.selectedCourse} Attendance',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Looking for ${_courseDevices[widget.selectedCourse] ?? 'device'}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: purpleTextColor,
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildStatusIndicator(),
                      const SizedBox(height: 20),
                      Text(
                        'RSSI: $_rssi',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Nearby Beacons (${_allDevices.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildDeviceList(),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isScanning ? null : _startScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text(
                          _isScanning ? 'Scanning...' : 'Rescan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildDeviceList() {
    if (_allDevices.isEmpty) {
      return Center(
        child: Text(
          'No devices found',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: const Color(0xFF6A1B9A).withOpacity(0.6),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _allDevices.length,
      itemBuilder: (context, index) {
        final device = _allDevices[index];
        final distance = _calculateDistance(device.rssi);
        final isTargetDevice = _courseDevices[widget.selectedCourse]?.replaceAll(':', '') ==
            device.device.remoteId.str.toUpperCase();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          color: isTargetDevice ? const Color(0xFFE1BEE7) : Colors.white,
          elevation: 2,
          child: ListTile(
            title: Text(
              device.device.remoteId.str,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6A1B9A),
              ),
            ),
            subtitle: Text(
              'RSSI: ${device.rssi} | Distance: ${distance.toStringAsFixed(2)}m',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF6A1B9A).withOpacity(0.7),
              ),
            ),
            trailing: isTargetDevice
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
        );
      },
    );
  }

  double _calculateDistance(int rssi) {
    // Simple distance calculation (can be adjusted based on your environment)
    const txPower = -59; // Reference RSSI at 1 meter
    if (rssi == 0) return -1.0; // Unknown distance

    double ratio = rssi * 1.0 / txPower;
    if (ratio < 1.0) {
      return pow(ratio, 10).toDouble();
    } else {
      return (0.89976) * pow(ratio, 7.7095) + 0.111;
    }
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isScanning)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A1B9A)),
              ),
            ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _status,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF6A1B9A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}