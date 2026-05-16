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

  bool absoluteVolumeEnabled = true;
  String? backgroundImagePath;

  AppStatus status = AppStatus.idle;
  String statusMessage = '';
  bool isMuted = false;

  int androidVolume = 0;
  int maxAndroidVolume = 15;

  // Volumen BT independiente (solo relevante cuando AV=OFF)
  // Representa el nivel 0–100 del DAC desde la perspectiva de la app.
  // NO es STREAM_MUSIC — es el contador interno del nativo.
  int btVolume = 50;
  int btMaxVolume = 100;

  Timer? _refreshTimer;

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> init() async {
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
      // Cuando AV=ON refrescamos también btVolume para que refleje lo mismo
      if (absoluteVolumeEnabled) {
        btVolume = vol;
        btMaxVolume = max;
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

    // Sincronizar btVolume con el nativo
    btVolume = await _btService.getBtVolume();
    btMaxVolume = await _btService.getBtMaxVolume();
    // Con AV ON, btVolume debe reflejar el mismo valor que androidVolume
    if (absoluteVolumeEnabled) {
      btVolume = androidVolume;
      btMaxVolume = maxAndroidVolume;
    }

    devices = found;
    if (found.isNotEmpty && selectedDevice == null) {
      selectedDevice = found.first;
    } else if (selectedDevice != null) {
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
    // La barra Android siempre toca STREAM_MUSIC directamente.
    // Con AV ON: también mueve el DAC (esperado).
    // Con AV OFF: SOLO mueve la barra Android — el DAC queda independiente.
    await _btService.setAndroidVolume(level);
    androidVolume = level;
    notifyListeners();
  }

  Future<void> volumeUp() async {
    isMuted = false;
    await _btService.sendVolumeUp(address: selectedDevice?.address);
    if (absoluteVolumeEnabled) {
      // AV ON: Android y BT están vinculados. Refrescamos ambas barras desde STREAM_MUSIC.
      await _refreshVolume();
      btVolume = androidVolume;
      btMaxVolume = maxAndroidVolume;
    } else {
      // AV OFF: El nativo incrementa el contador BT interno.
      // Leemos el nuevo valor para actualizar la barra BT de la UI.
      btVolume = await _btService.getBtVolume();
      // La barra Android NO se refresca — permanece independiente.
    }
    notifyListeners();
  }

  Future<void> volumeDown() async {
    isMuted = false;
    await _btService.sendVolumeDown(address: selectedDevice?.address);
    if (absoluteVolumeEnabled) {
      await _refreshVolume();
      btVolume = androidVolume;
      btMaxVolume = maxAndroidVolume;
    } else {
      btVolume = await _btService.getBtVolume();
      // La barra Android NO se refresca — permanece independiente.
    }
    notifyListeners();
  }

  Future<void> sendPlayPause() async {
    // La mayoría de los dispositivos aceptan play como toggle de play/pause
    await _btService.sendPlay(address: selectedDevice?.address);
  }

  Future<void> sendNext() async {
    await _btService.sendNext(address: selectedDevice?.address);
  }

  Future<void> sendPrev() async {
    await _btService.sendPrev(address: selectedDevice?.address);
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

  Future<bool> toggleAbsoluteVolume(bool value) async {
    final success = await _btService.setAbsoluteVolume(enabled: value);
    if (success) {
      absoluteVolumeEnabled = value;
      await _profileService.setAbsoluteVolEnabled(value);
      notifyListeners();
      return true;
    }
    return false;
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

  /// Porcentaje de volumen Android (para la barra Android de la UI)
  double get volumePercent =>
      maxAndroidVolume > 0 ? androidVolume / maxAndroidVolume : 0.0;

  /// Porcentaje de volumen BT independiente (para la barra BT de la UI)
  /// Cuando AV=ON: igual a volumePercent.
  /// Cuando AV=OFF: refleja el contador interno btVolume/btMaxVolume.
  double get btVolumePercent =>
      btMaxVolume > 0 ? btVolume / btMaxVolume : 0.0;
}
