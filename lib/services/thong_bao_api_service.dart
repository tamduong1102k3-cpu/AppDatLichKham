import 'package:flutter/cupertino.dart';

import '../core/dio_client.dart';
import '../services/auth_service.dart';
import '../models/thong_bao_model.dart';

class ThongBaoApiService {
  static final ThongBaoApiService _instance = ThongBaoApiService._internal();
  factory ThongBaoApiService() => _instance;
  ThongBaoApiService._internal();

  final _dio = DioClient().dio;
  final _authService = AuthService();


  Future<bool> createThongBao({
    required int nguoiNhanId,
    required String loaiNguoiNhan,
    required String tieuDe,
    required String noiDung,
    String? referenceType,
    String? referenceId,
  }) async {
    try {
      final response = await _dio.post(
        '/thong-bao',
        data: {
          'nguoiNhanId': nguoiNhanId,
          'loaiNguoiNhan': loaiNguoiNhan,
          'tieuDe': tieuDe,
          'noiDung': noiDung,
          'referenceType': referenceType,
          'referenceId': referenceId,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      // [LOG] debugPrint('createThongBao error: $e');
      return false;
    }
  }


  Future<List<ThongBaoModel>> getThongBao({
    bool? chiChuaDoc,
  }) async {
    final nguoiNhanId = _authService.maTaiKhoanBn;
    // [LOG] debugPrint('ThongBaoApiService.getThongBao - maTaiKhoanBn: $nguoiNhanId, chiChuaDoc: $chiChuaDoc');
    if (nguoiNhanId == null) {
      // [LOG] debugPrint('ThongBaoApiService.getThongBao - maTaiKhoanBn is null, cannot fetch');
      return [];
    }
    return _fetchThongBao(nguoiNhanId, chiChuaDoc);
  }


  Future<List<ThongBaoModel>> _fetchThongBao(int nguoiNhanId, bool? chiChuaDoc) async {
    try {
      final queryParams = <String, dynamic>{};
      if (chiChuaDoc != null) queryParams['chiChuaDoc'] = chiChuaDoc;

      final response = await _dio.get(
        '/thong-bao/$nguoiNhanId/BENH_NHAN',
        queryParameters: queryParams,
      );

      // [LOG] debugPrint('ThongBaoApiService._fetchThongBao - nguoiNhanId: $nguoiNhanId, status: ${response.statusCode}, response: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        // [LOG] debugPrint('ThongBaoApiService._fetchThongBao - found ${data.length} notifications');
        return data.map((e) => ThongBaoModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      // [LOG] debugPrint('ThongBaoApiService._fetchThongBao - unexpected response: ${response.data}');
      return [];
    } catch (e) {
      rethrow;
    }
  }


  Future<int> getUnreadCount() async {
    final nguoiNhanId = _authService.maTaiKhoanBn;
    // [LOG] debugPrint('ThongBaoApiService.getUnreadCount - maTaiKhoanBn: $nguoiNhanId');
    if (nguoiNhanId == null) return 0;

    try {
      final response = await _dio.get('/thong-bao/$nguoiNhanId/BENH_NHAN/unread-count');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final count = (response.data['unreadCount'] as num).toInt();
        // [LOG] debugPrint('ThongBaoApiService.getUnreadCount - count: $count');
        return count;
      }
      // [LOG] debugPrint('ThongBaoApiService.getUnreadCount - unexpected response: ${response.data}');
      return 0;
    } catch (e) {
      // [LOG] debugPrint('ThongBaoApiService.getUnreadCount - ERROR: $e');
      return 0;
    }
  }


  Future<bool> markAsRead(int id) async {
    try {
      final response = await _dio.put('/thong-bao/$id/mark-read');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }


  Future<bool> markAllAsRead() async {
    final nguoiNhanId = _authService.maTaiKhoanBn;
    // [LOG] debugPrint('ThongBaoApiService.markAllAsRead - maTaiKhoanBn: $nguoiNhanId');
    if (nguoiNhanId == null) return false;

    try {
      final response = await _dio.put('/thong-bao/$nguoiNhanId/BENH_NHAN/mark-all-read');
      // [LOG] debugPrint('ThongBaoApiService.markAllAsRead - status: ${response.statusCode}, response: ${response.data}');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      // [LOG] debugPrint('ThongBaoApiService.markAllAsRead - ERROR: $e');
      return false;
    }
  }


  Future<bool> deleteNotif(int id) async {
    try {
      final response = await _dio.delete('/thong-bao/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      // [LOG] debugPrint('ThongBaoApiService.deleteNotif - ERROR: $e');
      return false;
    }
  }
}
