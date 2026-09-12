import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/wifi_network.dart';

class WifiScannerService {
  static const MethodChannel _channel = MethodChannel('com.wavely.app/wifi_scanner');
  final Random _rnd = Random();

  Future<bool> checkPermissions() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;
    try {
      final bool? granted = await _channel.invokeMethod<bool>('checkPermissions');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;
    try {
      final bool? granted = await _channel.invokeMethod<bool>('requestPermissions');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<WifiNetwork>> getScanResults({bool forceSimulate = false}) async {
    if (!forceSimulate && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final List<dynamic>? rawList = await _channel.invokeMethod<List<dynamic>>('getScanResults');
        if (rawList != null && rawList.isNotEmpty) {
          return rawList.map((item) => WifiNetwork.fromMap(item as Map<dynamic, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint('[Wavely Scanner] Native scan error, falling back to simulated telemetry: $e');
      }
    }

    return _generateRealisticSimulatedNetworks();
  }

  Future<WifiNetwork?> getConnectedNetwork({bool forceSimulate = false}) async {
    if (!forceSimulate && !kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final Map<dynamic, dynamic>? rawConnected =
            await _channel.invokeMethod<Map<dynamic, dynamic>>('getConnectedNetwork');
        if (rawConnected != null) {
          final ssid = rawConnected['ssid'] as String?;
          if (ssid != null && ssid.isNotEmpty && ssid != '<unknown ssid>') {
            return WifiNetwork.fromMap(rawConnected, isConnected: true);
          }
        }
      } catch (e) {
        debugPrint('[Wavely Scanner] Native connected info unavailable: $e');
      }
    }

    final simulatedList = _generateRealisticSimulatedNetworks();
    return simulatedList.firstWhere((n) => n.isConnected, orElse: () => simulatedList.first);
  }

  List<WifiNetwork> _generateRealisticSimulatedNetworks() {
    final jitter = _rnd.nextInt(5) - 2; // ±2 dBm fluctuation
    return [
      WifiNetwork(
        ssid: "Home_Network_5G",
        bssid: "74:83:C2:88:1A:40",
        rssi: -54 + jitter,
        frequency: 5180,
        channel: 36,
        band: "5 GHz",
        security: "WPA3",
        standard: "Wi-Fi 6 (802.11ax)",
        isConnected: true,
      ),
      WifiNetwork(
        ssid: "Home_Network_2.4G",
        bssid: "74:83:C2:88:1A:41",
        rssi: -62 + jitter,
        frequency: 2437,
        channel: 6,
        band: "2.4 GHz",
        security: "WPA2",
        standard: "Wi-Fi 5 (802.11ac)",
      ),
      WifiNetwork(
        ssid: "Neighbor_Mesh_Ch6",
        bssid: "B4:E6:2D:91:FA:3C",
        rssi: -67 + jitter,
        frequency: 2437,
        channel: 6,
        band: "2.4 GHz",
        security: "WPA2",
        standard: "Wi-Fi 4 (802.11n)",
      ),
      WifiNetwork(
        ssid: "Studio_Office_UNII3",
        bssid: "18:E8:29:43:99:A2",
        rssi: -73 + jitter,
        frequency: 5745,
        channel: 149,
        band: "5 GHz",
        security: "WPA2",
        standard: "Wi-Fi 5 (802.11ac)",
      ),
      WifiNetwork(
        ssid: "Guest_Open_Hotspot",
        bssid: "00:1A:2B:3C:4D:5E",
        rssi: -84 + jitter,
        frequency: 2412,
        channel: 1,
        band: "2.4 GHz",
        security: "Open",
        standard: "Wi-Fi 4 (802.11n)",
      ),
    ];
  }
}
