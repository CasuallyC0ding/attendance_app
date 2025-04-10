import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class TakeAttendence extends StatefulWidget {
  final String selectedCourse;

  const TakeAttendence({super.key, required this.selectedCourse});

  @override
  State<TakeAttendence> createState() => _TakeAttendencepage();
}

class _TakeAttendencepage extends State<TakeAttendence> {
  // Device address mapping remains unchanged
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

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  // Scanning logic remains unchanged
  Future<void> _startScan() async {
    try {
      await Permission.location.request();
      setState(() {
        _isScanning = true;
        _status = 'Searching for ${widget.selectedCourse} device...';
      });

      FlutterBluePlus.scanResults.listen((results) {
        final targetAddress = _courseDevices[widget.selectedCourse]?.replaceAll(':', '') ?? '';
        for (ScanResult result in results) {
          if (result.device.remoteId.toString().toUpperCase() == targetAddress) {
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

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      setState(() => _status = 'Error: ${e.toString()}');
    } finally {
      setState(() => _isScanning = false);
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
        title: Text(
          '${widget.selectedCourse} Attendance',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
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
              width: MediaQuery.of(context).size.width * 0.85,
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
                      // Smaller search text
                      Text(
                        'Looking for ${_courseDevices[widget.selectedCourse] ?? 'device'}',
                        style: GoogleFonts.poppins(
                          fontSize: 13, // Reduced from 14
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
                      const SizedBox(height: 25),
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
                          'Rescan',
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
          // Smaller status text
          Text(
            _status,
            style: GoogleFonts.poppins(
              fontSize: 14, // Reduced from 16
              color: Color(0xFF6A1B9A),
              fontWeight: FontWeight.w500,
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