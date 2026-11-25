import 'package:dio/dio.dart';

import '../core/dio_client.dart';
import '../models/patient_exam_history.dart';

class PatientExamHistoryService {
  Dio get _dio => DioClient().dio;

  Future<List<VisitedSpecialty>> getVisitedSpecialties(int maBenhNhan) async {
    try {
      final response = await _dio.get(
        '/benh-nhan/lich-su-kham/chuyen-khoa',
        queryParameters: {'maBenhNhan': maBenhNhan},
      );
      return (response.data as List<dynamic>)
          .map((item) => VisitedSpecialty.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(
        'Không thể tải danh sách chuyên khoa đã khám (${error.response?.statusCode ?? 'lỗi kết nối'})',
      );
    }
  }

  Future<List<ExamHistoryEntry>> getExaminations({
    required int maBenhNhan,
    required int maChuyenKhoa,
  }) async {
    try {
      final response = await _dio.get(
        '/benh-nhan/lich-su-kham/phieu-kham',
        queryParameters: {
          'maBenhNhan': maBenhNhan,
          'maChuyenKhoa': maChuyenKhoa,
        },
      );
      return (response.data as List<dynamic>)
          .map((item) => ExamHistoryEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(
        'Không thể tải phiếu khám (${error.response?.statusCode ?? 'lỗi kết nối'})',
      );
    }
  }

  Future<List<ExamHistoryResult>> getResults({
    required int maBenhNhan,
    required int maPhieuKham,
  }) async {
    try {
      final response = await _dio.get(
        '/benh-nhan/lich-su-kham/ket-qua',
        queryParameters: {
          'maBenhNhan': maBenhNhan,
          'maPhieuKham': maPhieuKham,
        },
      );
      return (response.data as List<dynamic>)
          .map((item) => ExamHistoryResult.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw Exception(
        'Không thể tải kết quả khám (${error.response?.statusCode ?? 'lỗi kết nối'})',
      );
    }
  }
}
