import 'dart:typed_data';

abstract class ProvTransport {
  Future<bool> connect();

  Future<bool> checkConnect();

  Future<void> disconnect();

  Future<List<int>> sendReceive(String? epName, Uint8List? data);
}
