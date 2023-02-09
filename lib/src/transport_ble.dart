import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
// import 'package:flutter_blue/flutter_blue.dart';
import 'transport.dart';

class TransportBLE implements ProvTransport {
  final Peripheral peripheral;
  // final BluetoothDevice bluetoothDevice;
  // List<BluetoothService> services;
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

  TransportBLE(this.peripheral,
      {this.serviceUUID = PROV_BLE_SERVICE, this.lockupTable = PROV_BLE_EP}) {
    nuLookup = new Map<String, String>();

    for (var name in lockupTable.keys) {
      var charsInt = lockupTable[name] == null
          ? null
          : int.parse(lockupTable[name], radix: 16);
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

    bool isConnected = await peripheral.isConnected();
    if (isConnected) {
      return Future.value(true);
    }
    await peripheral.connect(requestMtu: 512);
    await peripheral.discoverAllServicesAndCharacteristics(
        transactionId: 'discoverAllServicesAndCharacteristics');
    return await peripheral.isConnected();
  }

  Future<Uint8List> sendReceive(String epName, Uint8List data) async {
    log("EP NAME $epName DATA $data");
    if (data != null) {
      if (data.length > 0) {
        // BluetoothService service = services.firstWhere(
        //     (s) => s.uuid.toString() == serviceUUID,
        //     orElse: () => null);
        // if (service != null) {
        //   BluetoothCharacteristic characteristic = service.characteristics
        //       .firstWhere((c) => c.uuid.toString() == nuLookup[epName ?? ""],
        //           orElse: () => null);
        //   characteristic.write(data);
        // }
        var res = await peripheral.writeCharacteristic(
            serviceUUID, nuLookup[epName ?? ""], data, true);
        log("CHARACTERISTIC $res");
      }
    }

    // BluetoothService service = services.firstWhere(
    //     (s) => s.uuid.toString() == serviceUUID,
    //     orElse: () => null);
    // if (service != null) {
    //   BluetoothCharacteristic characteristic = service.characteristics
    //       .firstWhere((c) => c.uuid.toString() == nuLookup[epName ?? ""],
    //           orElse: () => null);
    //   await characteristic.write(data);
    //   return characteristic.read();
    // }

    CharacteristicWithValue receivedData = await peripheral.readCharacteristic(
        serviceUUID, nuLookup[epName ?? ""],
        transactionId: 'readCharacteristic');
    return receivedData.value;
  }

  Future<void> disconnect() async {
    // bluetoothDevice.state.listen((state) async {
    //   if (state == BluetoothDeviceState.connected) {
    //     return await bluetoothDevice.disconnect();
    //   } else {
    //     return;
    //   }
    // });

    bool check = await peripheral.isConnected();
    if (check) {
      return await peripheral.disconnectOrCancelConnection();
    } else {
      return;
    }
  }

  Future<bool> checkConnect() async {
    log("INSIDE CHECK CONNECT FUNCTION");
    return await peripheral.isConnected();
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
