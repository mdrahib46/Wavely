import '../../scanner/data/models/wifi_network.dart';

enum RecommendationType { optimal, channelCongestion, signalDrop, securityRisk }

class DiagnosticRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final String actionLabel;
  final String severity; // "optimal", "warning", "critical"

  const DiagnosticRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.severity,
  });
}

class RuleBasedAiEngine {
  /// Analyzes scan results and connected network, returning expert recommendations
  static DiagnosticRecommendation analyze({
    required WifiNetwork? connected,
    required List<WifiNetwork> allNetworks,
  }) {
    if (connected == null) {
      return const DiagnosticRecommendation(
        type: RecommendationType.signalDrop,
        title: "No Active Connection",
        description: "Connect to a local Wi-Fi network to begin precision diagnostic telemetry.",
        actionLabel: "Open Wi-Fi Settings",
        severity: "warning",
      );
    }

    // 1. Critical Security Risk Check
    if (connected.security == 'Open' || connected.security == 'WEP') {
      return const DiagnosticRecommendation(
        type: RecommendationType.securityRisk,
        title: "Unencrypted Network Risk",
        description: "Network traffic is unencrypted. Upgrade router security cipher to WPA3 or WPA2-Personal.",
        actionLabel: "Security Guide",
        severity: "critical",
      );
    } else if (connected.security == 'WPA2') {
      // Prompt Rule: "Security Risk: Network is using WPA2. Upgrade router to WPA3."
      // Only flag if signal is fine and channel is not heavily congested
      final coChannelCount = allNetworks
          .where((n) => n.channel == connected.channel && n.bssid != connected.bssid)
          .length;
      if (connected.rssi >= -68 && coChannelCount < 2) {
        return const DiagnosticRecommendation(
          type: RecommendationType.securityRisk,
          title: "Upgrade to WPA3",
          description: "Network is using WPA2. Upgrade router to WPA3 for enhanced forward secrecy and spoofing protection.",
          actionLabel: "Router Guide",
          severity: "warning",
        );
      }
    }

    // 2. Severe Signal Drop Check
    // Prompt Rule: "Signal Drop: RSSI is below -70dBm. Move closer to the router."
    if (connected.rssi < -70) {
      return DiagnosticRecommendation(
        type: RecommendationType.signalDrop,
        title: "Weak Signal (${connected.rssi} dBm)",
        description: "RSSI is below -70 dBm. Move closer to the router or reposition your mesh node to eliminate dead zones.",
        actionLabel: "Launch AR Finder",
        severity: "critical",
      );
    }

    // 3. Channel Congestion Check
    // Prompt Rule: "Channel Congestion: Too many networks on Channel 6. Switch to 1 or 11."
    final coChannelNetworks = allNetworks
        .where((n) => n.channel == connected.channel && n.bssid != connected.bssid)
        .toList();

    if (coChannelNetworks.length >= 2) {
      final alternateChannels = connected.channel == 6 ? "1 or 11" : (connected.channel == 1 ? "6 or 11" : "1 or 6");
      return DiagnosticRecommendation(
        type: RecommendationType.channelCongestion,
        title: "Channel Congestion Detected",
        description: "Too many networks on Channel ${connected.channel} (${coChannelNetworks.length} overlapping). Switch to $alternateChannels.",
        actionLabel: "Optimize Channel",
        severity: "warning",
      );
    }

    // 4. Optimal State
    return DiagnosticRecommendation(
      type: RecommendationType.optimal,
      title: "Optimal Signal & Alignment",
      description: "Connected to Channel ${connected.channel} (${connected.band}) with low interference and strong RSSI.",
      actionLabel: "View Pro Spectrum",
      severity: "optimal",
    );
  }
}
