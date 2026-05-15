/// Per-device persistent profile saved in SharedPreferences
class DeviceProfile {
  final String address;
  final String customName;
  final int savedVolume;
  final bool autoResync;
  final bool forceAbsoluteVolume;
  final DateTime lastSeen;

  const DeviceProfile({
    required this.address,
    required this.customName,
    this.savedVolume = 10,
    this.autoResync = true,
    this.forceAbsoluteVolume = false,
    required this.lastSeen,
  });

  factory DeviceProfile.fromJson(Map<String, dynamic> json) {
    return DeviceProfile(
      address: json['address'] as String,
      customName: json['customName'] as String? ?? '',
      savedVolume: json['savedVolume'] as int? ?? 10,
      autoResync: json['autoResync'] as bool? ?? true,
      forceAbsoluteVolume: json['forceAbsoluteVolume'] as bool? ?? false,
      lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'customName': customName,
        'savedVolume': savedVolume,
        'autoResync': autoResync,
        'forceAbsoluteVolume': forceAbsoluteVolume,
        'lastSeen': lastSeen.toIso8601String(),
      };

  DeviceProfile copyWith({
    String? customName,
    int? savedVolume,
    bool? autoResync,
    bool? forceAbsoluteVolume,
    DateTime? lastSeen,
  }) {
    return DeviceProfile(
      address: address,
      customName: customName ?? this.customName,
      savedVolume: savedVolume ?? this.savedVolume,
      autoResync: autoResync ?? this.autoResync,
      forceAbsoluteVolume: forceAbsoluteVolume ?? this.forceAbsoluteVolume,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
