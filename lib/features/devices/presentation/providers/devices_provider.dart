import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/connected_device.dart';
import '../../data/services/device_scanner_service.dart';

enum DeviceFilter { all, alerts }

final deviceFilterProvider = StateProvider<DeviceFilter>((ref) => DeviceFilter.all);

final deviceScannerServiceProvider = Provider<DeviceScannerService>((ref) => DeviceScannerService());

class DevicesState {
  final bool isLoading;
  final List<ConnectedDevice> devices;
  final double totalLanLoadMbps;
  final int alertCount;

  const DevicesState({
    this.isLoading = false,
    this.devices = const [],
    this.totalLanLoadMbps = 14.3,
    this.alertCount = 1,
  });

  DevicesState copyWith({
    bool? isLoading,
    List<ConnectedDevice>? devices,
    double? totalLanLoadMbps,
    int? alertCount,
  }) {
    return DevicesState(
      isLoading: isLoading ?? this.isLoading,
      devices: devices ?? this.devices,
      totalLanLoadMbps: totalLanLoadMbps ?? this.totalLanLoadMbps,
      alertCount: alertCount ?? this.alertCount,
    );
  }
}

class DevicesNotifier extends StateNotifier<DevicesState> {
  final DeviceScannerService _service;
  Timer? _timer;

  DevicesNotifier(this._service) : super(const DevicesState()) {
    refreshDevices();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => refreshDevices());
  }

  Future<void> refreshDevices() async {
    final list = await _service.scanLocalDevices();
    final double load = list.fold(0.0, (sum, dev) => sum + dev.bandwidthMbps);
    final alerts = list.where((d) => !d.isTrusted).length;

    state = state.copyWith(
      devices: list,
      totalLanLoadMbps: double.parse(load.toStringAsFixed(1)),
      alertCount: alerts,
      isLoading: false,
    );
  }

  void blockDevice(String macAddress) {
    final updated = state.devices.map((d) {
      if (d.macAddress == macAddress) {
        return ConnectedDevice(
          ipAddress: d.ipAddress,
          macAddress: d.macAddress,
          vendorOUI: d.vendorOUI,
          hostName: '${d.hostName} (BLOCKED)',
          type: d.type,
          signalDbm: d.signalDbm,
          bandwidthMbps: 0.0,
          isTrusted: false,
          isOnline: false,
          firstSeen: d.firstSeen,
        );
      }
      return d;
    }).toList();

    state = state.copyWith(devices: updated);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final devicesProvider = StateNotifierProvider<DevicesNotifier, DevicesState>((ref) {
  final service = ref.watch(deviceScannerServiceProvider);
  return DevicesNotifier(service);
});
