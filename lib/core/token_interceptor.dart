import 'package:dio/dio.dart';

import '../services/auth_service.dart';

class TokenInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;

  TokenInterceptor({required AuthService authService, required Dio dio})
    : _authService = authService,
      _dio = dio;

  static const List<String> _publicApiPaths = ['/server-time', '/tai-khoan-benh-nhan/login'];

  bool _isPublicApi(RequestOptions options) {
    final path = options.path;
    if (options.method == 'POST' && path == '/tai-khoan-benh-nhan') return true;
    return _publicApiPaths.any((p) => path.contains(p));
  }

  bool _isAuthEndpoint(RequestOptions options) {
    final path = options.path;
    return path.contains('/refresh-token') || path.contains('/login') || path.contains('/logout') || path.contains('/verify-email') || path.contains('/forgot-password');
  }

  bool _isNoAuthHeaderPath(RequestOptions options) {
    final path = options.path;
    return ['/chuyen-khoa', '/dich-vu', '/nhan_vien/by-chuc-vu', '/server-time'].any((p) => path.contains(p));
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_isAuthEndpoint(options) || _isNoAuthHeaderPath(options)) {
      return handler.next(options);
    }
    final accessToken = _authService.token;
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    final errData = err.response?.data;
    String? errCode;
    if (errData is Map) {
      errCode = errData['code']?.toString();
    }
    if (errCode == 'SESSION_REVOKED') {
      _authService.notifySessionExpired();
      return handler.next(err);
    }

    final requestOptions = err.requestOptions;
    if (requestOptions.extra['retried'] == true) {
      return handler.next(err);
    }
    if (requestOptions.path.contains('/refresh-token')) {
      return handler.next(err);
    }

    final result = await _authService.refreshAccessToken();
    if (result == RefreshResult.success) {
      final newToken = _authService.token;
      if (newToken != null) {
        requestOptions.headers['Authorization'] = 'Bearer $newToken';
        requestOptions.extra['retried'] = true;
        try {
          final response = await _dio.fetch(requestOptions);
          return handler.resolve(response);
        } catch (retryError) {
          return handler.next(retryError is DioException ? retryError : err);
        }
      }
    }
    if (result == RefreshResult.invalid) {
      _authService.notifySessionExpired();
    }
    return handler.next(err);
  }
}