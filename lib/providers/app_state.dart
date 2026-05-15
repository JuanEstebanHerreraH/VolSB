import 'dart:async';
import 'package:flutter/material.dart';
import '../models/bt_device.dart';
import '../models/device_profile.dart';
import '../services/bt_channel_service.dart';
import '../services/profile_service.dart';

enum AppStatus { idle, scanning, syncing, reconnecting, error, success }

class AppState extends ChangeNotifier {
  final _btService = BtChannelService();
  final _profileService = ProfileService();

  // ── State ────────────────────────────────────────────────────────────────────

  List<BtDevice> devices = [];
  BtDevice? selectedDevice;
  Map<String, DeviceProfile> profiles = {};

  bool isDarkMode = true;
  bool absoluteVolumeEnabled = true;
  String? backgroundImagePath;

  AppStatus status = AppStatus.idle;
  String statusMessage = '';
  bool isMuted = false;

  int androidVolume = 0;
  int maxAndroidVolume = 15;

  Timer? _refreshTimer;

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    isDarkMode = await _profileService.getDarkMode();
    absoluteVolumeEnabled = await _profileService.getAbsoluteVolEnabled();
    backgroundImagePath = await _profileService.getBackgroundPath();
    profiles = await _profileService.loadAll();
    notifyListeners();

    await scanDevices();
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final vol = await _btService.getAndroidVolume();
      final max = await _btService.getMaxAndroidVolume();
      if (androidVolume != vol || maxAndroidVolume != max) {
        androidVolume = vol;
        maxAndroidVolume = max;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ── Device scanning ──────────────────────────────────────────────────────────

  Future<void> scanDevices() async {
    _setStatus(AppStatus.scanning, 'Buscando dispositivos…');
    final found = await _btService.getConnectedDevices();
    androidVolume = await _btService.getAndroidVolume();
    maxAndroidVolume = await _btService.getMaxAndroidVolume();
    devices = found;
    if (found.isNotEmpty && selectedDevice == null) {
      selectedDevice = found.first;
    } else if (selectedDevice != null) {
      // Refresh selected device info
      final updated = found.firstWhere(
        (d) => d.address == selectedDevice!.address,
        orElse: () => selectedDevice!,
      );
      selectedDevice = updated;
    }
    _setStatus(AppStatus.idle, found.isEmpty ? 'Sin dispositivos conectados' : '');
  }

  void selectDevice(BtDevice device) {
    selectedDevice = device;
    notifyListeners();
  }

  // ── Volume controls ──────────────────────────────────────────────────────────

  Future<void> setAndroidVolume(int level) async {
    await _btService.setAndroidVolume(level);
    androidVolume = level;
    notifyListeners();
  }

  Future<void> volumeUp() async {
    await _btService.sendVolumeUp(address: selectedDevice?.address);
    await _refreshVolume();
  }

  Future<void> volumeDown() async {
    await _btService.sendVolumeDown(address: selectedDevice?.address);
    await _refreshVolume();
  }

  Future<void> toggleMute() async {
    isMuted = !isMuted;
    if (isMuted) {
      await _btService.sendMute();
    } else {
      await _btService.sendUnmute();
    }
    notifyListeners();
  }

  Future<void> _refreshVolume() async {
    androidVolume = await _btService.getAndroidVolume();
    notifyListeners();
  }

  // ── Advanced operations ──────────────────────────────────────────────────────

  Future<void> resyncVolume() async {
    _setStatus(AppStatus.syncing, 'Resincronizando volumen…');
    final result = await _btService.resyncVolume();
    final success = result['success'] as bool? ?? false;
    _setStatus(
      success ? AppStatus.success : AppStatus.error,
      success ? 'Volumen resincronizado ✓' : 'No se pudo resincronizar',
    );
    await _refreshVolume();
    _clearStatusAfterDelay();
  }

  Future<void> reconnectDevice() async {
    if (selectedDevice == null) return;
    _setStatus(AppStatus.reconnecting, 'Reconectando dispositivo…');
    final ok = await _btService.reconnectDevice(selectedDevice!.address);
    _setStatus(
      ok ? AppStatus.success : AppStatus.error,
      ok ? 'Dispositivo reconectado ✓' : 'Error al reconectar',
    );
    await scanDevices();
    _clearStatusAfterDelay();
  }

  Future<void> resetBluetoothVolume() async {
    _setStatus(AppStatus.syncing, 'Reseteando volumen Bluetooth…');
    final ok = await _btService.resetBluetoothVolume();
    _setStatus(
      ok ? AppStatus.success : AppStatus.error,
      ok ? 'Volumen Bluetooth reseteado ✓' : 'Error al resetear',
    );
    await _refreshVolume();
    _clearStatusAfterDelay();
  }

  Future<void> recoverMutedDevice() async {
    if (selectedDevice == null) return;
    _setStatus(AppStatus.syncing, 'Intentando recuperar dispositivo muteado…');
    final ok = await _btService.recoverMutedDevice(selectedDevice!.address);
    _setStatus(
      ok ? AppStatus.success : AppStatus.error,
      ok ? 'Recuperación completada ✓' : 'No se pudo recuperar automáticamente',
    );
    _clearStatusAfterDelay();
  }

  Future<void> toggleAbsoluteVolume(bool value) async {
    absoluteVolumeEnabled = value;
    await _btService.setAbsoluteVolume(enabled: value);
    await _profileService.setAbsoluteVolEnabled(value);
    notifyListeners();
  }

  // ── Profiles ─────────────────────────────────────────────────────────────────

  Future<void> saveDeviceProfile(String address, {
    String? customName,
    int? savedVolume,
    bool? autoResync,
    bool? forceAbsoluteVolume,
  }) async {
    final existing = profiles[address];
    final profile = existing != null
        ? existing.copyWith(
            customName: customName,
            savedVolume: savedVolume,
            autoResync: autoResync,
            forceAbsoluteVolume: forceAbsoluteVolume,
            lastSeen: DateTime.now(),
          )
        : DeviceProfile(
            address: address,
            customName: customName ?? '',
            savedVolume: savedVolume ?? androidVolume,
            autoResync: autoResync ?? true,
            forceAbsoluteVolume: forceAbsoluteVolume ?? false,
            lastSeen: DateTime.now(),
          );
    profiles[address] = profile;
    await _profileService.save(profile);
    notifyListeners();
  }

  // ── Appearance ────────────────────────────────────────────────────────────────

  Future<void> setDarkMode(bool value) async {
    isDarkMode = value;
    await _profileService.setDarkMode(value);
    notifyListeners();
  }

  Future<void> setBackgroundImage(String? path) async {
    backgroundImagePath = path;
    await _profileService.setBackgroundPath(path);
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  void _setStatus(AppStatus s, String msg) {
    status = s;
    statusMessage = msg;
    notifyListeners();
  }

  void _clearStatusAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (status == AppStatus.success || status == AppStatus.error) {
        status = AppStatus.idle;
        statusMessage = '';
        notifyListeners();
      }
    });
  }

  double get volumePercent =>
      maxAndroidVolume > 0 ? androidVolume / maxAndroidVolume : 0.0;
}
