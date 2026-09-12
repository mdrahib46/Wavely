import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../scanner/presentation/providers/scanner_providers.dart';
import '../../data/models/connected_device.dart';
import '../providers/devices_provider.dart';
import 'device_detail_screen.dart';

class ConnectedDevicesScreen extends ConsumerWidget {
  const ConnectedDevicesScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final devState = ref.watch(devicesProvider);
    final filter = ref.watch(deviceFilterProvider);

    final filteredDevices = filter == DeviceFilter.alerts
        ? devState.devices.where((d) => !d.isTrusted).toList()
        : devState.devices;

    final unknownDevices = devState.devices.where((d) => !d.isTrusted).toList();

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
              child: const Icon(Icons.devices, color: AppColors.emeraldBright, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Devices',
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
                      ),
                      child: const Text(
                        'ARP SCAN',
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
                  'Local Subnet Inventory',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(devicesProvider.notifier).refreshDevices(),
        color: AppColors.emerald,
        backgroundColor: AppColors.surface1,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Network Status Hub Banner
            Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              color: AppColors.emeraldBright,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Secure Local Network',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Gateway: ${devState.devices.isNotEmpty ? devState.devices.firstWhere((d) => d.type == DeviceType.gateway, orElse: () => devState.devices.first).ipAddress : "192.168.0.1"} • ${ref.watch(scannerProvider).connectedNetwork?.security ?? "WPA2"}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: unknownDevices.isNotEmpty
                              ? AppColors.rose.withValues(alpha: 0.15)
                              : AppColors.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: unknownDevices.isNotEmpty
                                ? AppColors.rose.withValues(alpha: 0.3)
                                : AppColors.emerald.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          unknownDevices.isNotEmpty
                              ? '${unknownDevices.length} Attention'
                              : 'All Clear',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: unknownDevices.isNotEmpty ? AppColors.rose : AppColors.emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Sub-row: Total Active, LAN Load, Isolation
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TelemetryStat(
                          label: 'Total Active',
                          value: '${devState.devices.length} Nodes',
                        ),
                        Container(width: 1, height: 24, color: AppColors.borderHairline),
                        _TelemetryStat(
                          label: 'LAN Load',
                          value: '${devState.totalLanLoadMbps} Mbps',
                          highlight: true,
                        ),
                        Container(width: 1, height: 24, color: AppColors.borderHairline),
                        const _TelemetryStat(
                          label: 'Isolation',
                          value: 'Enforced',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Filter & Segmentation Strip ("All" vs "Alerts")
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Connected Devices',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${devState.devices.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _FilterTab(
                        label: 'All',
                        isSelected: filter == DeviceFilter.all,
                        onTap: () =>
                            ref.read(deviceFilterProvider.notifier).state = DeviceFilter.all,
                      ),
                      _FilterTab(
                        label: 'Alerts',
                        isSelected: filter == DeviceFilter.alerts,
                        badgeCount: unknownDevices.length,
                        onTap: () =>
                            ref.read(deviceFilterProvider.notifier).state = DeviceFilter.alerts,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 3. Priority Unknown Device Alert Card (if any and filter allows)
            if (unknownDevices.isNotEmpty &&
                (filter == DeviceFilter.all || filter == DeviceFilter.alerts))
              ...unknownDevices.map((dev) => _UnknownDeviceAlertCard(
                    device: dev,
                    onBlock: () {
                      ref.read(devicesProvider.notifier).blockDevice(dev.macAddress);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surface2,
                          content: Text('Access revoked for MAC ${dev.macAddress}'),
                        ),
                      );
                    },
                    onLearnMore: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DeviceDetailScreen(device: dev)),
                    ),
                  )),

            const SizedBox(height: 10),

            // 4. Trusted Devices Group
            ...filteredDevices.where((d) => d.isTrusted).map((dev) => _DeviceTile(
                  device: dev,
                  icon: _getDeviceIcon(dev.type),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DeviceDetailScreen(device: dev)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _TelemetryStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _TelemetryStat({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            color: highlight ? AppColors.emeraldBright : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface1 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            if (badgeCount != null && badgeCount! > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.rose,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnknownDeviceAlertCard extends StatelessWidget {
  final ConnectedDevice device;
  final VoidCallback onBlock;
  final VoidCallback onLearnMore;

  const _UnknownDeviceAlertCard({
    required this.device,
    required this.onBlock,
    required this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rose.withValues(alpha: 0.4)),
      ),
      child: Stack(
        children: [
          // Left Hazard Rose border strip
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.rose,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.rose.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.gpp_maybe, color: AppColors.rose, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  device.hostName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.rose.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'NEW MAC',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.rose,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              device.macAddress,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.rose,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      device.ipAddress,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  device.vendorOUI.contains("Unrecognized") || device.vendorOUI.contains("Private")
                      ? 'Private / Randomized MAC (${device.vendorOUI}). Node active on local subnet.'
                      : 'Vendor: ${device.vendorOUI}. Device joined ${device.firstSeen}.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onLearnMore,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.surface2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Inspect', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onBlock,
                      icon: const Icon(Icons.block, size: 14),
                      label: const Text('Block Node', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final ConnectedDevice device;
  final IconData icon;
  final VoidCallback onTap;

  const _DeviceTile({required this.device, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.emeraldBright, size: 20),
        ),
        title: Text(
          device.hostName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${device.ipAddress} • ${device.vendorOUI}',
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${device.bandwidthMbps} Mbps',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: AppColors.emeraldBright,
              ),
            ),
            Text(
              '${device.signalDbm} dBm',
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
