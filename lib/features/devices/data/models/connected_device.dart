enum DeviceType { gateway, smartphone, tv, laptop, iot, unknown }

class ConnectedDevice {
  final String ipAddress;
  final String macAddress;
  final String vendorOUI;
  final String hostName;
  final DeviceType type;
  final int signalDbm;
  final double bandwidthMbps;
  final double peakSpeedMbps;
  final double totalTrafficGb;
  final bool isTrusted;
  final bool isOnline;
  final String frequencyBand;
  final String subnet;
  final String leaseType;
  final String firstSeen;

  const ConnectedDevice({
    required this.ipAddress,
    required this.macAddress,
    required this.vendorOUI,
    required this.hostName,
    required this.type,
    required this.signalDbm,
    required this.bandwidthMbps,
    this.peakSpeedMbps = 14.8,
    this.totalTrafficGb = 1.2,
    this.isTrusted = true,
    this.isOnline = true,
    this.frequencyBand = "5 GHz",
    this.subnet = "255.255.255.0",
    this.leaseType = "DHCP LEASE",
    required this.firstSeen,
  });

  factory ConnectedDevice.fromMap(Map<dynamic, dynamic> map) {
    DeviceType devType = DeviceType.unknown;
    final typeStr = map['type']?.toString().toLowerCase() ?? '';
    if (typeStr == 'gateway') {
      devType = DeviceType.gateway;
    } else if (typeStr == 'smartphone') {
      devType = DeviceType.smartphone;
    } else if (typeStr == 'laptop') {
      devType = DeviceType.laptop;
    } else if (typeStr == 'tv') {
      devType = DeviceType.tv;
    } else if (typeStr == 'iot') {
      devType = DeviceType.iot;
    }

    final isGateway = devType == DeviceType.gateway;
    final isPhone = devType == DeviceType.smartphone;

    return ConnectedDevice(
      ipAddress: map['ip']?.toString() ?? '',
      macAddress: map['mac']?.toString() ?? '',
      vendorOUI: map['vendor']?.toString() ?? 'Unrecognized Vendor',
      hostName: map['hostname']?.toString() ?? 'Network Node',
      type: devType,
      signalDbm: isGateway ? -39 : (isPhone ? -38 : -47),
      bandwidthMbps: isGateway ? 4.8 : (isPhone ? 1.2 : 3.5),
      peakSpeedMbps: isGateway ? 300.0 : (isPhone ? 144.0 : 250.0),
      totalTrafficGb: isGateway ? 32.4 : (isPhone ? 2.8 : 14.2),
      isTrusted: map['isTrusted'] ?? true,
      isOnline: true,
      frequencyBand: isGateway ? 'Ethernet / Gateway' : '2.4 GHz (Ch 13)',
      firstSeen: isGateway ? 'Gateway Node' : 'Active now',
    );
  }

  int get signalQualityPercent {
    if (signalDbm <= -100) return 0;
    if (signalDbm >= -50) return 100;
    return (2 * (signalDbm + 100)).clamp(0, 100);
  }
}
