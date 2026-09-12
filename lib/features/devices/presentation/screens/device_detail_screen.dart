import 'package:flutter/material.dart';
import '../../../../core/constants/app_theme.dart';
import '../../data/models/connected_device.dart';

class DeviceDetailScreen extends StatelessWidget {
  final ConnectedDevice device;

  const DeviceDetailScreen({super.key, required this.device});

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.tv:
        return Icons.tv;
      case DeviceType.laptop:
        return Icons.laptop_mac;
      case DeviceType.smartphone:
        return Icons.phone_android;
      case DeviceType.gateway:
        return Icons.router;
      default:
        return Icons.device_unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface0,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Detail',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Text(
              'BSSID & ARP Telemetry',
              style: TextStyle(
                fontSize: 10,
                fontFamily: 'monospace',
                color: AppColors.emeraldBright,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero Device Header Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Column(
              children: [
                // Device Icon with Pulse Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.surface2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getDeviceIcon(device.type),
                        size: 38,
                        color: AppColors.emeraldBright,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: device.isOnline ? AppColors.emerald : AppColors.rose,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface1, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  device.hostName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  device.vendorOUI,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.emerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            device.isOnline ? 'Online • Active now' : 'Offline / Blocked',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emeraldBright,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        device.leaseType,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Real-Time Telemetry Grid (Signal vs Traffic)
          Row(
            children: [
              // Signal Quality Tile
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Signal Quality',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          Text(
                            '84%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              color: AppColors.emeraldBright,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${device.signalDbm}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'dBm',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: (device.signalQualityPercent / 100).clamp(0.0, 1.0),
                          backgroundColor: AppColors.surface2,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Session Traffic Tile
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface1,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderHairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Session Traffic',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          Icon(Icons.swap_vert, size: 16, color: AppColors.emeraldBright),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${device.totalTrafficGb}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'GB',
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Peak Speed',
                            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                          Text(
                            '${device.peakSpeedMbps} MB/s',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.emeraldBright,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Hardware & Network Telemetry List
          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HARDWARE & TELEMETRY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      device.frequencyBand,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.emeraldBright,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TelemetryRow(
                  title: 'IP Address',
                  subtitle: 'Subnet: ${device.subnet}',
                  value: device.ipAddress,
                ),
                const Divider(color: AppColors.surface2, height: 16),
                _TelemetryRow(
                  title: 'Physical MAC',
                  subtitle: 'OUI: ${device.vendorOUI}',
                  value: device.macAddress,
                ),
                const Divider(color: AppColors.surface2, height: 16),
                _TelemetryRow(
                  title: 'DHCP Assignment',
                  subtitle: 'Lease Expiry: 24h',
                  value: '${device.ipAddress.contains(".") ? device.ipAddress.substring(0, device.ipAddress.lastIndexOf(".")) : "192.168.0"}.1 (GW)',
                ),
                const Divider(color: AppColors.surface2, height: 16),
                _TelemetryRow(
                  title: 'Current Throughput',
                  subtitle: 'In-Memory Stream',
                  value: '${device.bandwidthMbps} Mbps',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;

  const _TelemetryRow({required this.title, required this.subtitle, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
