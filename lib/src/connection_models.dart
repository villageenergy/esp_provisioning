enum WifiConnectionState {
  Connected,
  Connecting,
  Disconnected,
  ConnectionFailed,
}

enum WifiConnectFailedReason {
  AuthError,
  NetworkNotFound,
}

class ConnectionStatus {
  ConnectionStatus({
    this.state = WifiConnectionState.Disconnected,
    this.ip,
    this.failedReason,
  });

  final WifiConnectionState state;
  final String? ip;
  final WifiConnectFailedReason? failedReason;
}

class WifiAP {
  const WifiAP({
    this.ssid,
    this.rssi = 1,
    this.active = false,
    this.private = true,
  });

  final String? ssid;
  final num rssi;
  final bool active;
  final bool private;

  int compareTo(WifiAP other) {
    if (rssi > other.rssi) {
      return -1;
    }
    if (rssi == other.rssi) {
      return 0;
    }
    return 1;
  }
}
