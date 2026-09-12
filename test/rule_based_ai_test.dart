import 'package:flutter_test/flutter_test.dart';
import 'package:wavely/features/diagnostic_engine/domain/rule_based_ai_engine.dart';
import 'package:wavely/features/scanner/data/models/wifi_network.dart';

void main() {
  group('RuleBasedAiEngine Tests', () {
    test('Identifies Signal Drop when RSSI < -70 dBm', () {
      final connected = WifiNetwork(
        ssid: 'Home_5G',
        bssid: '00:11:22:33:44:55',
        rssi: -78,
        frequency: 5180,
        channel: 36,
        band: '5 GHz',
        security: 'WPA3',
        standard: 'Wi-Fi 6',
        isConnected: true,
      );

      final rec = RuleBasedAiEngine.analyze(connected: connected, allNetworks: [connected]);
      expect(rec.type, RecommendationType.signalDrop);
      expect(rec.severity, 'critical');
    });

    test('Identifies Channel Congestion when >= 2 neighboring networks overlap', () {
      final connected = WifiNetwork(
        ssid: 'Home_2.4G',
        bssid: '00:11:22:33:44:55',
        rssi: -58,
        frequency: 2437,
        channel: 6,
        band: '2.4 GHz',
        security: 'WPA3',
        standard: 'Wi-Fi 6',
        isConnected: true,
      );

      final neighbor1 = WifiNetwork(
        ssid: 'Neighbor1',
        bssid: 'AA:BB:CC:DD:EE:01',
        rssi: -65,
        frequency: 2437,
        channel: 6,
        band: '2.4 GHz',
        security: 'WPA2',
        standard: 'Wi-Fi 5',
      );

      final neighbor2 = WifiNetwork(
        ssid: 'Neighbor2',
        bssid: 'AA:BB:CC:DD:EE:02',
        rssi: -70,
        frequency: 2437,
        channel: 6,
        band: '2.4 GHz',
        security: 'WPA2',
        standard: 'Wi-Fi 4',
      );

      final rec = RuleBasedAiEngine.analyze(
        connected: connected,
        allNetworks: [connected, neighbor1, neighbor2],
      );

      expect(rec.type, RecommendationType.channelCongestion);
      expect(rec.title, contains('Channel Congestion'));
    });

    test('Identifies Unencrypted / Open Security Risk', () {
      final connected = WifiNetwork(
        ssid: 'Cafe_Open',
        bssid: '00:11:22:33:44:55',
        rssi: -52,
        frequency: 5180,
        channel: 36,
        band: '5 GHz',
        security: 'Open',
        standard: 'Wi-Fi 5',
        isConnected: true,
      );

      final rec = RuleBasedAiEngine.analyze(connected: connected, allNetworks: [connected]);
      expect(rec.type, RecommendationType.securityRisk);
      expect(rec.severity, 'critical');
    });

    test('Identifies Optimal State when signal is strong and uncongested', () {
      final connected = WifiNetwork(
        ssid: 'Home_5G_Optimal',
        bssid: '00:11:22:33:44:55',
        rssi: -50,
        frequency: 5180,
        channel: 36,
        band: '5 GHz',
        security: 'WPA3',
        standard: 'Wi-Fi 6',
        isConnected: true,
      );

      final rec = RuleBasedAiEngine.analyze(connected: connected, allNetworks: [connected]);
      expect(rec.type, RecommendationType.optimal);
      expect(rec.severity, 'optimal');
    });
  });
}
