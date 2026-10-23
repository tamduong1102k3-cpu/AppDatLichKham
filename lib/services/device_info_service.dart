import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Định danh máy ổn định cho chính sách single-active-device.
/// deviceId là UUID tự sinh, lưu bền trong SharedPreferences.
/// KHÔNG dùng giá trị dễ đổi (FCM token, Android ID).
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  static const String _deviceIdKey = 'stable_device_id_v1';

  String? _cachedDeviceId;
  String? _cachedAppVersion;
  String? _cachedOsVersion;
  String? _cachedDeviceName;

  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_deviceIdKey, id);
    }
    _cachedDeviceId = id;
    return id;
  }

  Future<String> getDeviceName() async {
    if (_cachedDeviceName != null) return _cachedDeviceName!;

    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final brand = info.brand.trim();
        final model = info.model.trim();
        var combined = [brand, model].where((s) => s.isNotEmpty).join(' ').trim();
        // Cột device_name VARCHAR(100) -> cắt an toàn, giữ nguyên khi ngắn.
        if (combined.length > 100) combined = combined.substring(0, 100);
        _cachedDeviceName = combined.isNotEmpty ? combined : 'unknown';
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final name = info.name.trim();
        if (name.isNotEmpty && name != 'iPhone' && name != 'iPad') {
          _cachedDeviceName = name;
        } else {
          final model = info.model.trim();
          _cachedDeviceName = model.isNotEmpty ? model : 'unknown';
        }
      } else {
        _cachedDeviceName = Platform.operatingSystem;
      }
    } catch (e) {
      debugPrint('DeviceInfo error: $e');
      _cachedDeviceName = 'unknown';
    }
    return _cachedDeviceName!;
  }

  Future<String> getOsVersion() async {
    if (_cachedOsVersion != null) return _cachedOsVersion!;

    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final v = info.version.release.trim();
        _cachedOsVersion = v.isNotEmpty ? 'Android $v (SDK ${info.version.sdkInt})' : null;
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final v = info.systemVersion.trim();
        _cachedOsVersion = v.isNotEmpty ? 'iOS $v' : null;
      }
    } catch (e) {
      debugPrint('DeviceInfo osVersion error: $e');
    }
    _cachedOsVersion ??= Platform.operatingSystemVersion;
    return _cachedOsVersion!;
  }

  Future<String> getAppVersion() async {
    if (_cachedAppVersion != null) return _cachedAppVersion!;
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedAppVersion = '${info.version}+${info.buildNumber}';
    } catch (e) {
      debugPrint('PackageInfo error: $e');
      _cachedAppVersion = 'unknown';
    }
    return _cachedAppVersion!;
  }

  Future<String> getDeviceType() async {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return Platform.operatingSystem;
  }
}
