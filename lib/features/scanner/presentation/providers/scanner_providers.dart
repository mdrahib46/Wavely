import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wifi_network.dart';
import '../../data/services/wifi_scanner_service.dart';
import '../../../diagnostic_engine/domain/rule_based_ai_engine.dart';

enum UIMode { beginner, pro }

final uiModeProvider = StateProvider<UIMode>((ref) => UIMode.beginner);

final selectedBandProvider = StateProvider<String>((ref) => "Both");

final wifiServiceProvider = Provider<WifiScannerService>((ref) => WifiScannerService());

class ScannerState {
  final bool isLoading;
  final WifiNetwork? connectedNetwork;
  final List<WifiNetwork> networks;
  final int healthScore;
  final DiagnosticRecommendation recommendation;
  final String? errorMessage;

  ScannerState({
    this.isLoading = false,
    this.connectedNetwork,
    this.networks = const [],
    this.healthScore = 84,
    this.recommendation = const DiagnosticRecommendation(
      type: RecommendationType.optimal,
      title: "Analyzing Spectrum",
      description: "Gathering local RF parameters...",
      actionLabel: "Analyze",
      severity: "optimal",
    ),
    this.errorMessage,
  });

  ScannerState copyWith({
    bool? isLoading,
    WifiNetwork? connectedNetwork,
    List<WifiNetwork>? networks,
    int? healthScore,
    DiagnosticRecommendation? recommendation,
    String? errorMessage,
  }) {
    return ScannerState(
      isLoading: isLoading ?? this.isLoading,
      connectedNetwork: connectedNetwork ?? this.connectedNetwork,
      networks: networks ?? this.networks,
      healthScore: healthScore ?? this.healthScore,
      recommendation: recommendation ?? this.recommendation,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ScannerNotifier extends StateNotifier<ScannerState> {
  final WifiScannerService _service;
  Timer? _pollingTimer;

  ScannerNotifier(this._service) : super(ScannerState()) {
    startScanning();
  }

  void startScanning() async {
    final hasPerm = await _service.checkPermissions();
    if (!hasPerm) {
      await _service.requestPermissions();
    }
    refreshScan();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => refreshScan());
  }

  Future<void> refreshScan() async {
    try {
      final networks = await _service.getScanResults();
      final connected = await _service.getConnectedNetwork();

      List<WifiNetwork> combinedNetworks = List.from(networks);
      if (connected != null) {
        final existingIdx = combinedNetworks.indexWhere((n) => n.bssid == connected.bssid);
        if (existingIdx != -1) {
          combinedNetworks[existingIdx] = connected;
        } else {
          combinedNetworks.insert(0, connected);
        }
      }

      // Compute Health Score (0-100)
      int score = 100;
      if (connected != null) {
        if (connected.rssi < -70) {
          score -= 30;
        } else if (connected.rssi < -60) {
          score -= 15;
        }

        if (connected.security == 'Open') {
          score -= 35;
        } else if (connected.security == 'WEP') {
          score -= 30;
        }

        final coChannel = combinedNetworks
            .where((n) => n.channel == connected.channel && n.bssid != connected.bssid)
            .length;
        score -= (coChannel * 10).clamp(0, 30);
      } else {
        score = 50;
      }

      final recommendation = RuleBasedAiEngine.analyze(
        connected: connected,
        allNetworks: combinedNetworks,
      );

      state = state.copyWith(
        networks: combinedNetworks,
        connectedNetwork: connected,
        healthScore: score.clamp(10, 100),
        recommendation: recommendation,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((ref) {
  final service = ref.watch(wifiServiceProvider);
  return ScannerNotifier(service);
});
