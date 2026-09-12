import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/csv_exporter.dart';
import '../../../ar_viewfinder/presentation/screens/ar_viewfinder_screen.dart';
import '../../../diagnostic_engine/domain/rule_based_ai_engine.dart';
import '../../data/models/wifi_network.dart';
import '../providers/scanner_providers.dart';
import '../widgets/channel_graph.dart';
import '../widgets/health_score_gauge.dart';
import '../../../diagnostics/presentation/widgets/latency_jitter_card.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiMode = ref.watch(uiModeProvider);
    final scanState = ref.watch(scannerProvider);
    final activeBand = ref.watch(selectedBandProvider);

    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: const Icon(Icons.wifi_tethering, color: AppColors.emeraldBright, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Wavely',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'LOCAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldBright,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Air-Gapped RF Telemetry',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // The "Wavely Toggle"
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Row(
              children: [
                _ModeButton(
                  label: 'Beginner',
                  isSelected: uiMode == UIMode.beginner,
                  onTap: () => ref.read(uiModeProvider.notifier).state = UIMode.beginner,
                ),
                _ModeButton(
                  label: 'Pro',
                  isSelected: uiMode == UIMode.pro,
                  onTap: () => ref.read(uiModeProvider.notifier).state = UIMode.pro,
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(scannerProvider.notifier).refreshScan(),
        color: AppColors.emerald,
        backgroundColor: AppColors.surface1,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Connected AP Header Banner
            if (scanState.connectedNetwork != null)
              _ConnectedNetworkCard(
                network: scanState.connectedNetwork!,
                onLaunchAr: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ArViewfinderScreen()),
                ),
              ),

            const SizedBox(height: 16),

            // 2. Beginner vs. Pro Mode Branching
            if (uiMode == UIMode.beginner) ...[
              // Circular Health Score Hero Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderHairline),
                ),
                child: Center(
                  child: HealthScoreGauge(score: scanState.healthScore),
                ),
              ),

              const SizedBox(height: 16),

              // Plain-English Rule-Based Local AI Card
              _AiRecommendationTile(rec: scanState.recommendation),

              const SizedBox(height: 16),

              // Lite AR Quick Launch Action Banner
              _ArQuickLaunchCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ArViewfinderScreen()),
                ),
              ),
            ] else ...[
              // Pro Mode: Top Toolbar with Band Filters and CSV Export
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: ["Both", "2.4 GHz", "5 GHz"].map((band) {
                      final isSelected = activeBand == band;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(band),
                          selected: isSelected,
                          onSelected: (_) =>
                              ref.read(selectedBandProvider.notifier).state = band,
                          selectedColor: AppColors.surface2,
                          backgroundColor: AppColors.surface1,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.emeraldBright : AppColors.textMuted,
                            fontFamily: 'monospace',
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.emerald : AppColors.borderHairline,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }).toList(),
                  ),
                  // CSV Export Action
                  IconButton(
                    tooltip: 'Export CSV Snapshot',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface1,
                      side: const BorderSide(color: AppColors.borderHairline),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download, color: AppColors.emeraldBright, size: 20),
                    onPressed: () async {
                      final path = await CsvExporter.exportScanToCsv(scanState.networks);
                      if (context.mounted && path != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surface2,
                            content: Text(
                              'Local snapshot generated: ${path.split("/").last}',
                              style: const TextStyle(color: AppColors.textPrimary),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // LAN vs WAN Latency & Bufferbloat Isolation Card
              const LatencyJitterCard(),

              const SizedBox(height: 14),

              // Overlapping RF Channel Graph (fl_chart)
              ChannelGraph(networks: scanState.networks, activeBand: activeBand),

              const SizedBox(height: 16),

              // Raw Telemetry List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RAW BSSID SPECTRUM TELEMETRY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    '${scanState.networks.length} Detected',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Telemetry Tiles
              ...scanState.networks.map((net) => _TelemetryDetailTile(network: net)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.emerald : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.surface0 : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ConnectedNetworkCard extends StatelessWidget {
  final WifiNetwork network;
  final VoidCallback onLaunchAr;

  const _ConnectedNetworkCard({required this.network, required this.onLaunchAr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.emerald, blurRadius: 6, spreadRadius: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  network.ssid,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.lock, size: 14, color: AppColors.emeraldBright),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'BSSID: ${network.bssid} • ${network.standard}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${network.rssi} dBm',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: AppColors.emeraldBright,
                    ),
                  ),
                  Text(
                    'Ch ${network.channel} (${network.band})',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (network.signalQualityPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.surface2,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${network.signalQualityPercent}% Quality',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                  color: AppColors.emeraldBright,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiRecommendationTile extends StatelessWidget {
  final DiagnosticRecommendation rec;

  const _AiRecommendationTile({required this.rec});

  @override
  Widget build(BuildContext context) {
    Color iconColor = AppColors.emerald;
    IconData icon = Icons.verified_user_outlined;

    if (rec.severity == 'warning') {
      iconColor = AppColors.amber;
      icon = Icons.lightbulb_outline;
    } else if (rec.severity == 'critical') {
      iconColor = AppColors.rose;
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rec.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Local Rule-Based Diagnostic AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: iconColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rec.description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArQuickLaunchCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ArQuickLaunchCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
          gradient: LinearGradient(
            colors: [AppColors.surface1, AppColors.emerald.withValues(alpha: 0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.camera_alt_outlined, color: AppColors.emeraldBright, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Launch Lite AR Viewfinder',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Overlay live signal gauge on camera feed to inspect rooms.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.emeraldBright),
          ],
        ),
      ),
    );
  }
}

class _TelemetryDetailTile extends StatelessWidget {
  final WifiNetwork network;

  const _TelemetryDetailTile({required this.network});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.emerald;
    if (network.rssi < -75) {
      color = AppColors.rose;
    } else if (network.rssi < -65) {
      color = AppColors.amber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        network.ssid,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (network.isConnected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CONNECTED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emeraldBright,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ch ${network.channel} • ${network.frequency} MHz (${network.band})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'MAC: ${network.bssid} • ${network.security} • ${network.standard}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${network.rssi} dBm',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _SignalBar(active: network.rssi >= -85, color: color, height: 6),
                  const SizedBox(width: 2),
                  _SignalBar(active: network.rssi >= -75, color: color, height: 9),
                  const SizedBox(width: 2),
                  _SignalBar(active: network.rssi >= -65, color: color, height: 12),
                  const SizedBox(width: 2),
                  _SignalBar(active: network.rssi >= -55, color: color, height: 15),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalBar extends StatelessWidget {
  final bool active;
  final Color color;
  final double height;

  const _SignalBar({required this.active, required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3.5,
      height: height,
      decoration: BoxDecoration(
        color: active ? color : AppColors.surface2,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
