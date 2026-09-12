import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../../core/utils/csv_exporter.dart';
import '../../../scanner/presentation/providers/scanner_providers.dart';

class SettingsHubScreen extends ConsumerStatefulWidget {
  const SettingsHubScreen({super.key});

  @override
  ConsumerState<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends ConsumerState<SettingsHubScreen> {
  bool _localOnlyMode = true;
  bool _anonymizeMac = true;

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scannerProvider);

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
              child: const Icon(Icons.settings, color: AppColors.emeraldBright, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Settings',
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
                        'TELEMETRY',
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
                  'Privacy & Diagnostic Controls',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy Shield Status Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surface2,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user, color: AppColors.emeraldBright, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Air-Gapped Telemetry',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.emerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emeraldBright,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'All RF analytics computed in-memory',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const Text(
                  '0B egress',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: AppColors.emeraldBright,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 1: NETWORK CONTROLS
          const Text(
            'NETWORK SCANNING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.emeraldBright,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Export Diagnostic Log', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Generate local .csv snapshot', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('CSV', style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.emeraldBright)),
                        SizedBox(width: 4),
                        Icon(Icons.download, size: 14, color: AppColors.emeraldBright),
                      ],
                    ),
                  ),
                  onTap: () async {
                    final path = await CsvExporter.exportScanToCsv(scanState.networks);
                    if (context.mounted && path != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surface2,
                          content: Text('Log exported to: ${path.split("/").last}'),
                        ),
                      );
                    }
                  },
                ),
                const Divider(color: AppColors.surface2, height: 1),
                const ListTile(
                  title: Text('Auto-Refresh Polling', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text('Sample RF channels every 4 seconds', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  trailing: Text(
                    '4.0s',
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: PRIVACY & HARDWARE
          const Text(
            'PRIVACY & SECURITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.emeraldBright,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _localOnlyMode,
                  onChanged: (val) => setState(() => _localOnlyMode = val),
                  activeThumbColor: AppColors.emerald,
                  title: const Text('Strict Local-Only Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Zero telemetry sent off-device. Ever.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
                const Divider(color: AppColors.surface2, height: 1),
                const ListTile(
                  title: Text('Local ARP Cache Retention', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text('Cleared automatically upon app termination', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  trailing: Chip(
                    label: Text('Ephemeral', style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: AppColors.amberLight)),
                    backgroundColor: AppColors.surface2,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const Divider(color: AppColors.surface2, height: 1),
                SwitchListTile(
                  value: _anonymizeMac,
                  onChanged: (val) => setState(() => _anonymizeMac = val),
                  activeThumbColor: AppColors.emerald,
                  title: const Text('Hardware Identifier Anonymization', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: const Text('Anonymize device MACs during export', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Info Footnote
          Center(
            child: Column(
              children: [
                Text(
                  'Wavely v1.2.0 (Precision Spectrum Build)',
                  style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 2),
                Text(
                  '100% On-Device Diagnostic Architecture',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
