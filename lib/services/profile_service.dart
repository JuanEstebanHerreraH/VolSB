import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_profile.dart';

class ProfileService {
  static const _profilesKey = 'device_profiles';
  static const _backgroundKey = 'background_path';
  static const _darkModeKey = 'dark_mode';
  static const _absoluteVolKey = 'absolute_vol_enabled';

  // ── Profiles ─────────────────────────────────────────────────────────────────

  Future<Map<String, DeviceProfile>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profilesKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map(
      (k, v) => MapEntry(k, DeviceProfile.fromJson(v as Map<String, dynamic>)),
    );
  }

  Future<DeviceProfile?> load(String address) async {
    final all = await loadAll();
    return all[address];
  }

  Future<void> save(DeviceProfile profile) async {
    final all = await loadAll();
    all[profile.address] = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesKey, jsonEncode(
      all.map((k, v) => MapEntry(k, v.toJson())),
    ));
  }

  Future<void> delete(String address) async {
    final all = await loadAll();
    all.remove(address);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesKey, jsonEncode(
      all.map((k, v) => MapEntry(k, v.toJson())),
    ));
  }

  // ── App-wide settings ─────────────────────────────────────────────────────────

  Future<String?> getBackgroundPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundKey);
  }

  Future<void> setBackgroundPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_backgroundKey);
    } else {
      await prefs.setString(_backgroundKey, path);
    }
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? true;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<bool> getAbsoluteVolEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_absoluteVolKey) ?? true;
  }

  Future<void> setAbsoluteVolEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_absoluteVolKey, value);
  }
}
