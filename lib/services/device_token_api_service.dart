import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/dio_client.dart';
import '../services/auth_service.dart';
import 'device_info_service.dart';

/// Service gửi FCM Token lên backend để lưu trữ
class DeviceTokenApiService {
  static final DeviceTokenApiService _instance = DeviceTokenApiService._internal();
  factory DeviceTokenApiService() => _instance;
  DeviceTokenApiService._internal();

  final _dio = DioClient().dio;
  final _authService = AuthService();
  final _deviceInfo = DeviceInfoService();

  static const String _cachePrefix = 'device_token_cache_v1';
  String _cacheKey(int userId) => '${_cachePrefix}_$userId';

  Future<Map<String, String?>> _readCache(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'deviceId': prefs.getString('${_cacheKey(userId)}_deviceId'),
      'fcmToken': prefs.getString('${_cacheKey(userId)}_fcmToken'),
      'enabled': prefs.getString('${_cacheKey(userId)}_enabled'),
    };
  }

  Future<void> _writeCache(int userId, String deviceId, String? fcmToken,
      bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(userId);
    await prefs.setString('${key}_deviceId', deviceId);
    if (fcmToken != null) {
      await prefs.setString('${key}_fcmToken', fcmToken);
    } else {
      await prefs.remove('${key}_fcmToken');
    }
    await prefs.setString('${key}_enabled', enabled ? '1' : '0');
  }

  /// Xóa cache khi logout (kể cả logout im lặng do 401).
  Future<void> clearCache() async {
    final userId = _authService.maTaiKhoanBn;
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey(userId);
    await prefs.remove('${key}_deviceId');
    await prefs.remove('${key}_fcmToken');
    await prefs.remove('${key}_enabled');
  }

  /// Đăng ký FCM Token lên backend. Token null khi quyền tắt (vẫn tạo dòng).
  /// loginEvent=true chỉ khi login. Bỏ qua gọi API khi trùng cache.
  Future<bool> registerToken(
    String? fcmToken, {
    required bool notificationsEnabled,
    required bool loginEvent,
  }) async {
    final maTaiKhoanBn = _authService.maTaiKhoanBn;
    if (maTaiKhoanBn == null) {
      debugPrint('Cannot register token: User not logged in');
      return false;
    }
    try {
      final deviceId = await _deviceInfo.getDeviceId();
      final deviceName = await _deviceInfo.getDeviceName();
      final osVersion = await _deviceInfo.getOsVersion();
      final appVersion = await _deviceInfo.getAppVersion();
      final deviceType = await _deviceInfo.getDeviceType();
      final cache = await _readCache(maTaiKhoanBn);
      if (!loginEvent &&
          cache['deviceId'] == deviceId &&
          cache['fcmToken'] == fcmToken &&
          cache['enabled'] == (notificationsEnabled ? '1' : '0')) {
        debugPrint('registerToken: skipped (no change)');
        return true;
      }
      final response = await _dio.post(
        '/device-tokens/register',
        data: {
          'maTaiKhoanBn': maTaiKhoanBn,
          'fcmToken': fcmToken,
          'deviceType': deviceType,
          'deviceId': deviceId,
          'deviceName': deviceName,
          'osVersion': osVersion,
          'appVersion': appVersion,
          'notificationsEnabled': notificationsEnabled,
          'loginEvent': loginEvent,
        },
      );
      if (response.statusCode == 200) {
        debugPrint('Token registered successfully');
        await _writeCache(maTaiKhoanBn, deviceId, fcmToken, notificationsEnabled);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error registering token: $e');
      return false;
    }
  }

  /// Cập nhật cờ quyền (và token nếu có). BE không insert khi thiếu dòng.
  Future<bool> updateNotificationStatus(bool enabled, {String? fcmToken}) async {
    final maTaiKhoanBn = _authService.maTaiKhoanBn;
    if (maTaiKhoanBn == null) return false;
    try {
      final deviceId = await _deviceInfo.getDeviceId();
      final response = await _dio.patch(
        '/device-tokens/notification-status',
        data: {
          'maTaiKhoanBn': maTaiKhoanBn,
          'deviceId': deviceId,
          'notificationsEnabled': enabled,
          if (fcmToken != null) 'fcmToken': fcmToken,
        },
      );
      if (response.statusCode == 200) {
        final cache = await _readCache(maTaiKhoanBn);
        await _writeCache(maTaiKhoanBn, deviceId, fcmToken ?? cache['fcmToken'], enabled);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating notification status: $e');
      return false;
    }
  }

  /// Xóa dòng của máy đó khỏi backend theo (user, deviceId).

  Future<bool> removeToken(String? fcmToken) async {
    final maTaiKhoanBn = _authService.maTaiKhoanBn;
    if (maTaiKhoanBn == null) return false;
    try {
      final deviceId = await _deviceInfo.getDeviceId();
      final response = await _dio.delete(
        '/device-tokens/remove',
        data: {
          'maTaiKhoanBn': maTaiKhoanBn,
          'deviceId': deviceId,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error removing token: $e');
      return false;
    }
  }

  /// Xóa tất cả token của user
  Future<bool> removeAllTokens() async {
    final maTaiKhoanBn = _authService.maTaiKhoanBn;
    if (maTaiKhoanBn == null) return false;
    try {
      final response = await _dio.delete(
        '/device-tokens/remove-all/$maTaiKhoanBn',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error removing all tokens: $e');
      return false;
    }
  }
}