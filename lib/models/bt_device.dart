/// Represents a connected Bluetooth audio device
class BtDevice {
  final String address;
  final String name;
  final int batteryLevel; // -1 = unknown
  final bool avrcpSupported;
  final bool absoluteVolumeSupported;
  final bool volumeSynced;
  final int androidVolume; // 0-15 typically
  final int maxAndroidVolume;
  final String profileType; // A2DP, HFP, etc.
  final bool isConnected;

  const BtDevice({
    required this.address,
    required this.name,
    this.batteryLevel = -1,
    this.avrcpSupported = false,
    this.absoluteVolumeSupported = false,
    this.volumeSynced = false,
    this.androidVolume = 0,
    this.maxAndroidVolume = 15,
    this.profileType = 'A2DP',
    this.isConnected = false,
  });

  factory BtDevice.fromMap(Map<dynamic, dynamic> map) {
    return BtDevice(
      address: map['address'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown Device',
      batteryLevel: map['batteryLevel'] as int? ?? -1,
      avrcpSupported: map['avrcpSupported'] as bool? ?? false,
      absoluteVolumeSupported: map['absoluteVolumeSupported'] as bool? ?? false,
      volumeSynced: map['volumeSynced'] as bool? ?? false,
      androidVolume: map['androidVolume'] as int? ?? 0,
      maxAndroidVolume: map['maxAndroidVolume'] as int? ?? 15,
      profileType: map['profileType'] as String? ?? 'A2DP',
      isConnected: map['isConnected'] as bool? ?? false,
    );
  }

  BtDevice copyWith({
    String? name,
    int? batteryLevel,
    bool? avrcpSupported,
    bool? absoluteVolumeSupported,
    bool? volumeSynced,
    int? androidVolume,
    int? maxAndroidVolume,
    String? profileType,
    bool? isConnected,
  }) {
    return BtDevice(
      address: address,
      name: name ?? this.name,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      avrcpSupported: avrcpSupported ?? this.avrcpSupported,
      absoluteVolumeSupported: absoluteVolumeSupported ?? this.absoluteVolumeSupported,
      volumeSynced: volumeSynced ?? this.volumeSynced,
      androidVolume: androidVolume ?? this.androidVolume,
      maxAndroidVolume: maxAndroidVolume ?? this.maxAndroidVolume,
      profileType: profileType ?? this.profileType,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  double get volumePercent =>
      maxAndroidVolume > 0 ? androidVolume / maxAndroidVolume : 0.0;

  String get batteryString =>
      batteryLevel < 0 ? 'N/A' : '$batteryLevel%';

  /// Friendly icon name based on device name heuristics
  String get deviceIcon {
    final n = name.toLowerCase();
    if (n.contains('headphone') || n.contains('headset') || n.contains('airpod') || n.contains('wh-') || n.contains('wf-')) {
      return 'headphones';
    }
    if (n.contains('speaker') || n.contains('soundbar') || n.contains('bose') || n.contains('jbl')) {
      return 'speaker';
    }
    if (n.contains('amp') || n.contains('amplifier') || n.contains('dac') || n.contains('receiver')) {
      return 'amp';
    }
    if (n.contains('car') || n.contains('auto') || n.contains('stereo')) {
      return 'car';
    }
    return 'bluetooth';
  }
}
