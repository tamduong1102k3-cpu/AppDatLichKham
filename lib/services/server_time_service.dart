import 'package:shared_preferences/shared_preferences.dart';

import '../core/dio_client.dart';

class ServerTimeService {
  static final ServerTimeService _instance = ServerTimeService._internal();
  factory ServerTimeService() => _instance;
  ServerTimeService._internal();

  Duration _offset = Duration.zero;
  bool _initialized = false;

  Future<void> init() async {
    await _loadOffsetFromPrefs();
    try {
      final response = await DioClient().dio.get('/server-time');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final serverTimeRaw = data['serverTime'];
        if (serverTimeRaw is String && serverTimeRaw.isNotEmpty) {
          final serverTime = DateTime.parse(serverTimeRaw);
          _offset = serverTime.difference(DateTime.now());
          _initialized = true;
          await _saveOffsetToPrefs();
        }
      }
    } catch (_) {
      // Keep the cached offset (or zero) if the server cannot be reached.
    }
  }

  static DateTime now() {
    return DateTime.now().add(_instance._offset);
  }

  bool get isInitialized => _initialized;

  Future<void> _saveOffsetToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('server_time_offset_ms', _offset.inMilliseconds);
    } catch (_) {
      // Ignore persistence errors.
    }
  }

  Future<void> _loadOffsetFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offsetMs = prefs.getInt('server_time_offset_ms');
      if (offsetMs != null) {
        _offset = Duration(milliseconds: offsetMs);
      }
    } catch (_) {
      // Ignore cache read errors.
    }
  }
}
