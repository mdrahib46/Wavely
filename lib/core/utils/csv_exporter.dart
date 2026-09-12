import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/scanner/data/models/wifi_network.dart';

class CsvExporter {
  /// Exports current Wi-Fi scan results to a local CSV file and triggers native share
  static Future<String?> exportScanToCsv(List<WifiNetwork> networks) async {
    final List<List<dynamic>> rows = [
      [
        "SSID",
        "BSSID",
        "RSSI (dBm)",
        "Signal Quality (%)",
        "Channel",
        "Frequency (MHz)",
        "Band",
        "Security",
        "Standard",
        "Timestamp"
      ]
    ];

    final now = DateTime.now().toIso8601String();
    for (final net in networks) {
      rows.add([
        net.ssid,
        net.bssid,
        net.rssi,
        net.signalQualityPercent,
        net.channel,
        net.frequency,
        net.band,
        net.security,
        net.standard,
        now,
      ]);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(
        row.map((cell) {
          final str = cell.toString().replaceAll('"', '""');
          return '"$str"';
        }).join(','),
      );
    }
    final csvString = buffer.toString();

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/wavely_telemetry_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvString);

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Wavely Air-Gapped RF Diagnostic Telemetry',
        subject: 'Wavely Diagnostic Snapshot',
      );

      return file.path;
    } catch (e) {
      return null;
    }
  }
}
