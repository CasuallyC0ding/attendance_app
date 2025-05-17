import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore package
//import 'AttendanceTrackerPage.dart';

// Model for beacon/device scan result
class Beacon {
  final String mac;
  final double distance;
  final double power;

  Beacon({required this.mac, required this.distance, required this.power});
}

class AttendanceSuccessPage extends StatelessWidget {
  final List<Beacon> scannedBeacons;
  final DateTime timestamp;

  // Define thresholds
  static const double maxAllowedDistance = 10.0; // meters (testing values)
  static const double minAllowedPower = -90.0; // dBm (testing values)

  const AttendanceSuccessPage({
    super.key,
    required this.scannedBeacons,
    required this.timestamp,
  });

  /// Fetch recognized MAC addresses from the 'courses' collection in Firestore
  Future<Set<String>> _fetchRecognizedMacs() async {
    final macs = <String>{};
    final snapshot = await FirebaseFirestore.instance.collection('courses').get();
    for (final doc in snapshot.docs) {
      if (doc.data().containsKey('MAC Address')) {
        final list = List<String>.from(doc.get('MAC Address') as List<dynamic>);
        for (var m in list) {
          macs.add((m as String).toUpperCase());
        }
      }
    }
    return macs;
  }

  /// Select the best beacon based on conditions:
  /// - If user is outside (any beacon beyond threshold), pick the one with weakest signal.
  /// - If two have equal power, pick the one with smaller distance.
  Beacon _selectBestBeacon(List<Beacon> beacons) {
    final outside = beacons.any((b) => b.distance > maxAllowedDistance);
    if (outside) {
      beacons.sort((a, b) {
        final cmp = a.power.compareTo(b.power);
        if (cmp != 0) return cmp;
        return a.distance.compareTo(b.distance);
      });
      return beacons.first;
    }
    final inside = beacons
        .where((b) => b.distance <= maxAllowedDistance && b.power >= minAllowedPower)
        .toList();
    if (inside.isNotEmpty) {
      inside.sort((a, b) {
        final cmp = b.power.compareTo(a.power);
        if (cmp != 0) return cmp;
        return a.distance.compareTo(b.distance);
      });
      return inside.first;
    }
    beacons.sort((a, b) => b.power.compareTo(a.power));
    return beacons.first;
  }

  Future<Set<String>> _delayedFetchRecognizedMacs() async {
  await Future.delayed(const Duration(seconds: 5));
  return _fetchRecognizedMacs();
}


  @override
  Widget build(BuildContext context) {
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

    return FutureBuilder<Set<String>>(
      future: _delayedFetchRecognizedMacs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final recognized = snapshot.data ?? {};
        final best = _selectBestBeacon(scannedBeacons);
        final allowed = recognized.contains(best.mac.toUpperCase()) && best.distance <= maxAllowedDistance && best.power >= minAllowedPower;
        //bool allowed = true;
        if (!allowed) {
          return Scaffold(
            backgroundColor: const Color(0xFF6A1B9A),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.redAccent, size: 100),
                      const SizedBox(height: 24),
                      Text(
                        'Unrecognized Device or Out of Range',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'MAC: ${best.mac}\nDistance: ${best.distance.toStringAsFixed(2)} m\nPower: ${best.power.toStringAsFixed(1)} dBm',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Back', style: GoogleFonts.poppins()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF6A1B9A),
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Attendance Marked Successfully!',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      _buildDetailsCard(best, formattedTime),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsCard(Beacon beacon, String time) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, spreadRadius: 2)],
      ),
      child: Column(
        children: [
          _detailRow('Device MAC', beacon.mac),
          const Divider(),
          _detailRow('Time', time),
          const Divider(),
          _detailRow('Distance', '${beacon.distance.toStringAsFixed(2)} m'),
          const Divider(),
          _detailRow('Power', '${beacon.power.toStringAsFixed(1)} dBm'),
        ],
      ),
    );
  }

  Widget _detailRow(String field, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(field, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF4A148C))),
          Text(value, style: GoogleFonts.poppins(fontStyle: FontStyle.italic, fontSize: 14, color: const Color(0xFF00BFA5))),
        ],
      ),
    );
  }
}
