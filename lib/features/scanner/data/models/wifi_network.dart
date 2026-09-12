class WifiNetwork {
  final String ssid;
  final String bssid;
  final int rssi; // e.g., -55 dBm
  final int frequency; // in MHz
  final int channel; // e.g., 36
  final String band; // "2.4 GHz", "5 GHz", "6 GHz"
  final String security; // "WPA3", "WPA2", "Open"
  final String standard; // "Wi-Fi 6", "Wi-Fi 5"
  final bool isConnected;

  WifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.frequency,
    required this.channel,
    required this.band,
    required this.security,
    required this.standard,
    this.isConnected = false,
  });

  factory WifiNetwork.fromMap(Map<dynamic, dynamic> map, {bool isConnected = false}) {
    return WifiNetwork(
      ssid: map['ssid'] as String? ?? 'Hidden Network',
      bssid: map['bssid'] as String? ?? '00:00:00:00:00:00',
      rssi: (map['rssi'] as num?)?.toInt() ?? -90,
      frequency: (map['frequency'] as num?)?.toInt() ?? 2412,
      channel: (map['channel'] as num?)?.toInt() ?? 1,
      band: map['band'] as String? ?? '2.4 GHz',
      security: map['security'] as String? ?? 'WPA2',
      standard: map['standard'] as String? ?? '802.11',
      isConnected: isConnected,
    );
  }

  int get signalQualityPercent {
    if (rssi <= -100) return 0;
    if (rssi >= -50) return 100;
    return (2 * (rssi + 100)).clamp(0, 100);
  }

  String get semanticStatus {
    if (rssi >= -60) return 'optimal';
    if (rssi >= -75) return 'moderate';
    return 'critical';
  }
}
