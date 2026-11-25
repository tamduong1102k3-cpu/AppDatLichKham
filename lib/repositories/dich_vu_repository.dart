import 'package:dio/dio.dart';

import '../core/dio_client.dart';
import '../models/dich_vu.dart';

class DichVuRepository {
  Dio get _dio => DioClient().dio;

  /// GET /api/dich-vu
  Future<List<DichVu>> getAll({List<String>? loaiDichVu}) async {
    final queryParams = <String, dynamic>{};
    if (loaiDichVu != null && loaiDichVu.isNotEmpty) {
      queryParams['loaiDichVu'] = loaiDichVu.join(',');
    }
    final response = await _dio.get(
      '/dich-vu',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return _parseList(response.data);
  }

  /// GET /api/dich-vu/{id}
  Future<DichVu> getById(int id) async {
    try {
      final response = await _dio.get('/dich-vu/$id');
      final data =
          response.data is Map<String, dynamic> && response.data['data'] != null
          ? response.data['data']
          : response.data;
      return DichVu.fromJson(data as Map<String, dynamic>);
    } on DioException {
      throw Exception('Không tìm thấy dịch vụ với ID: $id');
    }
  }

  /// GET /api/dich-vu/chuyen-khoa/{maChuyenKhoa}
  Future<List<DichVu>> getByChuyenKhoa(int maChuyenKhoa) async {
    final response = await _dio.get('/dich-vu/chuyen-khoa/$maChuyenKhoa');
    return _parseList(response.data);
  }

  List<DichVu> _parseList(dynamic data) {
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        list = data['data'] as List<dynamic>;
      } else {
        list = [];
      }
    } else {
      list = [];
    }
    return list
        .map((json) => DichVu.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
