import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:flutter_blue/flutter_blue.dart';
import 'transport.dart';

class TransportBLE implements ProvTransport {
  final BluetoothDevice? peripheral;
  // final BluetoothDevice bluetoothDevice;
  // List<BluetoothService> services;
  // final FlutterBluePlus bleManager = FlutterBluePlus.instance;
  final String serviceUUID;
  Map<String, String> nuLookup = {};
  final Map<String, String> lockupTable;

  static const PROV_BLE_SERVICE = '021a9004-0382-4aea-bff4-6b3f1c5adfb4';
  static const PROV_BLE_EP = {
    'prov-scan': 'ff50',
    'prov-session': '0001',
    'prov-config': '0002',
    'proto-ver': '0003',
    'custom-data': 'ff54',
  };

  //  {"prov-session", 0x0001},
  //     {"prov-config",  0x0002},
  //     {"proto-ver",    0x0003},

  TransportBLE(
    this.peripheral, {
    this.serviceUUID = PROV_BLE_SERVICE,
    this.lockupTable = PROV_BLE_EP,
  }) {
    nuLookup = new Map<String, String>();

    for (var name in lockupTable.keys) {
      var charsInt = lockupTable[name] == null
          ? null
          : int.parse(lockupTable[name]!, radix: 16);
      var serviceHex = charsInt?.toRadixString(16).padLeft(4, '0');
      if (charsInt != null && serviceHex != null) {
        nuLookup[name] =
            serviceUUID.substring(0, 4) + serviceHex + serviceUUID.substring(8);
      }
    }
  }

  Future<bool> connect() async {
    // bluetoothDevice.state.listen((state) async {
    //   if (state == BluetoothDeviceState.connected) {
    //     Future.value(true);
    //   } else {
    //     await bluetoothDevice.connect(autoConnect: false);
    //     await bluetoothDevice.requestMtu(512);
    //     services = await bluetoothDevice.discoverServices();
    //   }
    // });

    bool isConnected =
        (await FlutterBluePlus.connectedSystemDevices).contains(peripheral);
    if (isConnected) {
      return Future.value(true);
    }
    await peripheral?.connect();
    // await peripheral.requestMtu(512);

    try {
      await peripheral?.discoverServices();
    } catch (e) {
      return Future.error(e);
    }
    // discoverAllServicesAndCharacteristics(
    //     transactionId: 'discoverAllServicesAndCharacteristics');
    return (await FlutterBluePlus.connectedSystemDevices).contains(peripheral);
  }

  Future<List<int>> sendReceive(String? epName, Uint8List? data) async {
    List<BluetoothService>? services = await peripheral?.discoverServices();

    log("EP NAME $epName DATA $data");
    if (data != null && (services?.isNotEmpty ?? false)) {
      if (data.length > 0) {
        for (int i = 0; i < services!.length; i++) {
          if (services[i].uuid.toString() == serviceUUID) {
            var characteristics = services[i].characteristics;
            for (BluetoothCharacteristic c in characteristics) {
              if (c.uuid.toString() == nuLookup[epName ?? ""]) {
                // log("WAIT FOR 300 MILLISECONDS");
                // await Future.delayed(const Duration(milliseconds: 300));
                log("WRITING DATA $i DEVICEID: ${c.remoteId.toString()} DEVICE UUID: ${c.uuid.toString()} SERVICE UUID: ${c.serviceUuid.toString()} DATA: $data");
                await c.write(data, withoutResponse: false);
              }
            }
          }
        }
      }
    }

    log("WRITE DATA COMPLETE, NOW READING");
    late List<int> readResponse;
    for (int i = 0; i < (services?.length ?? 0); i++) {
      if (services![i].uuid.toString() == serviceUUID) {
        var characteristics = services[i].characteristics;
        for (BluetoothCharacteristic c in characteristics) {
          if (c.uuid.toString() == nuLookup[epName ?? ""] &&
              c.properties.read) {
            // log("WAIT FOR 300 MILLISECONDS");
            // await Future.delayed(const Duration(milliseconds: 300));
            log("READ CHARACTERISTIC ${c.uuid.toString()} ${nuLookup[epName ?? ""]}");
            List<int> value = await c.read();
            log("VALUE $value");
            readResponse = value;
          }
        }
      }
    }
    log("READ DATA COMPLETE, RESPONSE $readResponse");
    return readResponse;
  }

  Future<void> disconnect() async {
    // bluetoothDevice.state.listen((state) async {
    //   if (state == BluetoothDeviceState.connected) {
    //     return await bluetoothDevice.disconnect();
    //   } else {
    //     return;
    //   }
    // });

    bool check =
        (await FlutterBluePlus.connectedSystemDevices).contains(peripheral);
    if (check) {
      return await peripheral?.disconnect();
    } else {
      return;
    }
  }

  Future<bool> checkConnect() async {
    log("INSIDE CHECK CONNECT FUNCTION");
    return (await FlutterBluePlus.connectedSystemDevices).contains(peripheral);
    // bluetoothDevice.state.listen((state) async {
    //   if (state == BluetoothDeviceState.connected) {
    //     return true;
    //   } else {
    //     return false;
    //   }
    // });
  }

  void dispose() {
    print('dispose ble');
  }
}
