import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../data/entities/bang_phan_cong_ca_lam_entity.dart';
import '../data/entities/lich_thang_entity.dart';

class BangPhanCongRepository {
  Dio get _dio => DioClient().dio;

  Future<Map<int, List<String>>> getSummaryTuan(
    List<int> maNhanViens,
    List<String> dsThu,
  ) async {
    if (maNhanViens.isEmpty || dsThu.isEmpty) return {};
    final response = await _dio.get(
      '/lich-bac-si/summary-tuan',
      queryParameters: {
        'maNhanViens': maNhanViens.join(','),
        'dsThu': dsThu.join(','),
      },
    );
    final data = response.data as List<dynamic>;
    return {
      for (final item in data)
        (item['maNhanVien'] as int):
            (item['dsThu'] as List<dynamic>).cast<String>(),
    };
  }

  /// GET /api/phan-cong/by-nhan-vien/{maNhanVien}
  Future<List<BangPhanCongCaLamEntity>> getByNhanVien(int maNhanVien) async {
    final response = await _dio.get('/phan-cong/by-nhan-vien/$maNhanVien');
    final List<dynamic> data = response.data;
    return data.map((json) => BangPhanCongCaLamEntity.fromJson(json)).toList();
  }

  /// GET /api/lich-bac-si/thang?maNhanVien=&nam=&thang=
  Future<LichThangEntity> getLichThang(
    int maNhanVien,
    int nam,
    int thang,
  ) async {
    final response = await _dio.get(
      '/lich-bac-si/thang',
      queryParameters: {
        'maNhanVien': maNhanVien,
        'nam': nam,
        'thang': thang,
      },
    );
    return LichThangEntity.fromJson(response.data as Map<String, dynamic>);
  }

  /// GET /api/phan-cong/working-today
  Future<List<BangPhanCongCaLamEntity>> getWorkingToday() async {
    final response = await _dio.get('/phan-cong/working-today');
    final List<dynamic> data = response.data;
    return data.map((json) => BangPhanCongCaLamEntity.fromJson(json)).toList();
  }

  /// GET /api/phan-cong
  Future<List<BangPhanCongCaLamEntity>> getAll() async {
    final response = await _dio.get('/phan-cong');
    final List<dynamic> data = response.data;
    return data.map((json) => BangPhanCongCaLamEntity.fromJson(json)).toList();
  }
}