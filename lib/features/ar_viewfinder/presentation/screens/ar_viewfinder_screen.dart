import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_theme.dart';
import '../../../scanner/presentation/providers/scanner_providers.dart';

class SpatialSignalPin {
  final String roomName;
  final int rssi;
  final String band;
  final DateTime timestamp;

  const SpatialSignalPin({
    required this.roomName,
    required this.rssi,
    required this.band,
    required this.timestamp,
  });
}

class ArViewfinderScreen extends ConsumerStatefulWidget {
  const ArViewfinderScreen({super.key});

  @override
  ConsumerState<ArViewfinderScreen> createState() => _ArViewfinderScreenState();
}

class _ArViewfinderScreenState extends ConsumerState<ArViewfinderScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _cameraMessage;
  Timer? _reticlePulseTimer;
  Timer? _geigerTimer;
  double _pulseScale = 1.0;
  bool _hapticsEnabled = true;

  final List<SpatialSignalPin> _droppedPins = [
    SpatialSignalPin(
      roomName: "Router Anchor",
      rssi: -38,
      band: "5 GHz",
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    SpatialSignalPin(
      roomName: "Kitchen Corner",
      rssi: -72,
      band: "2.4 GHz",
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _reticlePulseTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (mounted) {
        setState(() {
          _pulseScale = _pulseScale == 1.0 ? 1.08 : 1.0;
        });
      }
    });

    _startGeigerFeedback();
  }

  void _startGeigerFeedback() {
    _geigerTimer?.cancel();
    _geigerTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted || !_hapticsEnabled) return;
      final scanState = ref.read(scannerProvider);
      final rssi = scanState.connectedNetwork?.rssi ?? -65;

      // Click intensity & feedback based on signal strength
      if (rssi > -60) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final backCamera = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        setState(() {
          _cameraMessage = "Virtual spatial grid active (Emulator Mode)";
        });
      }
    } catch (e) {
      setState(() {
        _cameraMessage = "Spatial RF grid active (Simulated Feed)";
      });
    }
  }

  void _dropPinDialog(int currentRssi, String currentBand) {
    final controller = TextEditingController(text: "Room Area ${_droppedPins.length + 1}");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.push_pin, color: AppColors.emeraldBright, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('Drop Spatial Signal Pin', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sample: $currentRssi dBm ($currentBand)',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.emeraldBright,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Location Name',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.borderHairline),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim().isEmpty ? "Location" : controller.text.trim();
              setState(() {
                _droppedPins.insert(
                  0,
                  SpatialSignalPin(
                    roomName: name,
                    rssi: currentRssi,
                    band: currentBand,
                    timestamp: DateTime.now(),
                  ),
                );
              });
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surface2,
                  content: Text('Pinned spot: $name ($currentRssi dBm)'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: AppColors.surface0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Pin'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reticlePulseTimer?.cancel();
    _geigerTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scannerProvider);
    final connected = scanState.connectedNetwork;
    final rssi = connected?.rssi ?? -65;

    final Color statusColor = rssi >= -60
        ? AppColors.emerald
        : (rssi >= -75 ? AppColors.amber : AppColors.rose);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Feed / Spatial Viewfinder Substrate
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            _buildSimulatedSpatialBackground(),

          // 2. HUD Grid & Hairline Spatial Crosshairs
          _buildSpatialCrosshairs(),

          // 3. Floating Spatial RSSI Target Reticle (Central Target)
          Center(
            child: AnimatedScale(
              scale: _pulseScale,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withValues(alpha: 0.85), width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_tethering, color: statusColor, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      '$rssi dBm',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                        shadows: [Shadow(blurRadius: 8, color: Colors.black)],
                      ),
                    ),
                    Text(
                      connected?.band ?? '5 GHz',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Top Telemetry Header with Haptics & Settings Toggle
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface0.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderHairline),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (Navigator.canPop(context)) ...[
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      connected?.ssid ?? 'Home_Network_5G',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface2,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Ch ${connected?.channel ?? 36}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: AppColors.emeraldBright,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _cameraMessage ?? 'BSSID: ${connected?.bssid ?? "74:83:C2:88:1A:40"}',
                                style: const TextStyle(
                                  fontSize: 10,
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
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      // Geiger Haptic Toggle
                      IconButton(
                        tooltip: 'Geiger Haptics',
                        icon: Icon(
                          _hapticsEnabled ? Icons.vibration : Icons.smartphone,
                          color: _hapticsEnabled ? AppColors.emeraldBright : AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _hapticsEnabled = !_hapticsEnabled);
                          HapticFeedback.mediumImpact();
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'LITE AR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Floating Spatial Pins Tray (Left)
          if (_droppedPins.isNotEmpty)
            Positioned(
              left: 16,
              top: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _droppedPins.take(3).map((pin) {
                  final pinColor = pin.rssi >= -60
                      ? AppColors.emerald
                      : (pin.rssi >= -75 ? AppColors.amber : AppColors.rose);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface0.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: pinColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, size: 14, color: pinColor),
                        const SizedBox(width: 4),
                        Text(
                          '${pin.roomName}: ',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          '${pin.rssi} dBm',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: pinColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // 6. Bottom Controls: Pin Spot Action & Spatial Signal Bar
          Positioned(
            bottom: 34,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface0.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SPATIAL SIGNAL FIDELITY',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                      ),
                      Text(
                        '${connected?.signalQualityPercent ?? 84}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ((connected?.signalQualityPercent ?? 84) / 100).clamp(0.0, 1.0),
                      backgroundColor: AppColors.surface2,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _hapticsEnabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                            size: 16,
                            color: AppColors.emeraldBright,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _hapticsEnabled ? 'Geiger Ticks Active' : 'Haptics Muted',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      // Drop Pin Button
                      ElevatedButton.icon(
                        onPressed: () => _dropPinDialog(rssi, connected?.band ?? "5 GHz"),
                        icon: const Icon(Icons.add_location_alt, size: 14),
                        label: const Text('Pin Room Spot', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: AppColors.surface0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    );
  }

  Widget _buildSpatialCrosshairs() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CrosshairPainter(),
      ),
    );
  }

  Widget _buildSimulatedSpatialBackground() {
    return Container(
      color: const Color(0xFF07090C),
      child: CustomPaint(
        painter: _GridSubstratePainter(),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderHairline.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;

    final cx = size.width / 2;
    final cy = size.height / 2;

    canvas.drawLine(Offset(cx - 120, cy), Offset(cx - 95, cy), paint);
    canvas.drawLine(Offset(cx + 95, cy), Offset(cx + 120, cy), paint);
    canvas.drawLine(Offset(cx, cy - 120), Offset(cx, cy - 95), paint);
    canvas.drawLine(Offset(cx, cy + 95), Offset(cx, cy + 120), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridSubstratePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderHairline.withValues(alpha: 0.18)
      ..strokeWidth = 0.8;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
