import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  static Future<bool> checkBluetooth() async {
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth not supported');
    }

    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
      throw Exception('Bluetooth is disabled');
    }

    return true;
  }
}
