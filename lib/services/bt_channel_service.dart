import 'package:flutter/services.dart';
import '../models/bt_device.dart';

/// Communicates with the native Kotlin side via MethodChannel.
class BtChannelService {
  static const _channel = MethodChannel('com.btvolumepro/bluetooth');

  // ── Device discovery ────────────────────────────────────────────────────────

  Future<List<BtDevice>> getConnectedDevices() async {
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getConnectedDevices');
      if (raw == null) return [];
      return raw
          .map((e) => BtDevice.fromMap(e as Map<dynamic, dynamic>))
          .toList();
    } on PlatformException catch (e) {
      _log('getConnectedDevices', e);
      return [];
    }
  }

  // ── Android system volume ────────────────────────────────────────────────────

  Future<int> getAndroidVolume() async {
    try {
      return await _channel.invokeMethod<int>('getAndroidVolume') ?? 0;
    } on PlatformException catch (e) {
      _log('getAndroidVolume', e);
      return 0;
    }
  }

  Future<int> getMaxAndroidVolume() async {
    try {
      return await _channel.invokeMethod<int>('getMaxVolume') ?? 15;
    } on PlatformException catch (e) {
      _log('getMaxAndroidVolume', e);
      return 15;
    }
  }

  Future<bool> setAndroidVolume(int level) async {
    try {
      final ok = await _channel.invokeMethod<bool>('setAndroidVolume', {'level': level});
      return ok ?? false;
    } on PlatformException catch (e) {
      _log('setAndroidVolume', e);
      return false;
    }
  }

  // ── AVRCP commands ───────────────────────────────────────────────────────────

  Future<bool> sendVolumeUp() async {
    try {
      return await _channel.invokeMethod<bool>('sendVolumeUp') ?? false;
    } on PlatformException catch (e) {
      _log('sendVolumeUp', e);
      return false;
    }
  }

  Future<bool> sendVolumeDown() async {
    try {
      return await _channel.invokeMethod<bool>('sendVolumeDown') ?? false;
    } on PlatformException catch (e) {
      _log('sendVolumeDown', e);
      return false;
    }
  }

  Future<bool> sendMute() async {
    try {
      return await _channel.invokeMethod<bool>('sendMute') ?? false;
    } on PlatformException catch (e) {
      _log('sendMute', e);
      return false;
    }
  }

  Future<bool> sendUnmute() async {
    try {
      return await _channel.invokeMethod<bool>('sendUnmute') ?? false;
    } on PlatformException catch (e) {
      _log('sendUnmute', e);
      return false;
    }
  }

  // ── Advanced operations ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> resyncVolume() async {
    try {
      final r = await _channel.invokeMethod<Map<dynamic, dynamic>>('resyncVolume');
      return Map<String, dynamic>.from(r ?? {});
    } on PlatformException catch (e) {
      _log('resyncVolume', e);
      return {'success': false, 'message': e.message};
    }
  }

  Future<bool> reconnectDevice(String address) async {
    try {
      return await _channel.invokeMethod<bool>('reconnectDevice', {'address': address}) ?? false;
    } on PlatformException catch (e) {
      _log('reconnectDevice', e);
      return false;
    }
  }

  Future<bool> resetBluetoothVolume() async {
    try {
      return await _channel.invokeMethod<bool>('resetBluetoothVolume') ?? false;
    } on PlatformException catch (e) {
      _log('resetBluetoothVolume', e);
      return false;
    }
  }

  Future<bool> setAbsoluteVolume({required bool enabled}) async {
    try {
      return await _channel.invokeMethod<bool>(
            'setAbsoluteVolume',
            {'enabled': enabled},
          ) ??
          false;
    } on PlatformException catch (e) {
      _log('setAbsoluteVolume', e);
      return false;
    }
  }

  Future<bool> getAbsoluteVolumeEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('getAbsoluteVolumeEnabled') ?? true;
    } on PlatformException catch (e) {
      _log('getAbsoluteVolumeEnabled', e);
      return true;
    }
  }

  Future<bool> toggleBluetooth() async {
    try {
      return await _channel.invokeMethod<bool>('toggleBluetooth') ?? false;
    } on PlatformException catch (e) {
      _log('toggleBluetooth', e);
      return false;
    }
  }

  /// Sends a burst of AVRCP volume-up commands to recover muted device
  Future<bool> recoverMutedDevice(String address) async {
    try {
      return await _channel.invokeMethod<bool>(
            'recoverMutedDevice',
            {'address': address},
          ) ??
          false;
    } on PlatformException catch (e) {
      _log('recoverMutedDevice', e);
      return false;
    }
  }

  void _log(String method, PlatformException e) {
    // ignore: avoid_print
    print('[BtChannelService] $method failed: ${e.message}');
  }
}
