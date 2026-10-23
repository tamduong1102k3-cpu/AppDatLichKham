import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import '../data/entities/lich_kham_entity.dart';

class LichKhamRepository {
  Dio get _dio => DioClient().dio;

  // ==================== LẤY DANH SÁCH ====================

  /// Lấy tất cả lịch khám
  Future<List<LichKhamEntity>> getAll() async {
    final response = await _dio.get('/lich-kham');
    final data = response.data as List<dynamic>;
    return data.map((json) => LichKhamEntity.fromJson(json)).toList();
  }

  /// Lấy lịch khám theo ID
  Future<LichKhamEntity> getById(int id) async {
    final response = await _dio.get('/lich-kham/$id');
    return LichKhamEntity.fromJson(response.data);
  }

  // ==================== THÊM / SỬA / XÓA ====================

  /// Tạo lịch khám mới (cần JWT - tự động lấy mã bệnh nhân từ token)
  ///
  /// Backend trả về `{ success: true, data: {...}, warning?: "..." }`.
  /// [CreateLichKhamResult.warning] != null khi bệnh nhân đã vắng mặt đúng ngưỡng (3 lần):
  /// lịch VẪN được tạo thành công, chỉ cần hiển thị cảnh báo cho người dùng.
  Future<CreateLichKhamResult> create(LichKhamEntity entity) async {
    final response = await _dio.post('/lich-kham', data: entity.toJson());
    return CreateLichKhamResult(
      lichKham: LichKhamEntity.fromJson(response.data['data']),
      warning: response.data['warning'] as String?,
    );
  }

  /// Cập nhật lịch khám (cần JWT - chỉ chủ sở hữu mới được sửa)
  Future<LichKhamEntity> update(int id, LichKhamEntity entity) async {
    final response = await _dio.put('/lich-kham/$id', data: entity.toJson());
    return LichKhamEntity.fromJson(response.data['data']);
  }

  /// Xóa lịch khám
  Future<void> delete(int id) async {
    await _dio.delete('/lich-kham/$id');
  }

  // ==================== LẤY THEO ĐIỀU KIỆN ====================

  /// Lấy lịch khám theo bệnh nhân
  Future<List<LichKhamEntity>> getByBenhNhan(int maBenhNhan) async {
    final response = await _dio.get('/lich-kham/benh-nhan/$maBenhNhan');
    final data = response.data as List<dynamic>;
    return data.map((json) => LichKhamEntity.fromJson(json)).toList();
  }

  /// Lấy lịch khám theo bác sĩ
  Future<List<LichKhamEntity>> getByBacSi(int maBacSi) async {
    final response = await _dio.get('/lich-kham/bac-si/$maBacSi');
    final data = response.data as List<dynamic>;
    return data.map((json) => LichKhamEntity.fromJson(json)).toList();
  }

  /// Lấy lịch khám theo ngày
  Future<List<LichKhamEntity>> getByNgayKham(String ngayKham) async {
    final response = await _dio.get('/lich-kham/ngay', queryParameters: {'ngayKham': ngayKham});
    final data = response.data as List<dynamic>;
    return data.map((json) => LichKhamEntity.fromJson(json)).toList();
  }

  /// Lấy lịch khám theo chuyên khoa
  Future<List<LichKhamEntity>> getByChuyenKhoa(int maChuyenKhoa) async {
    final response = await _dio.get('/lich-kham/chuyen-khoa/$maChuyenKhoa');
    final data = response.data as List<dynamic>;
    return data.map((json) => LichKhamEntity.fromJson(json)).toList();
  }

  /// Lấy lịch khám theo trạng thái
  Future<List<LichKhamEntity>> getByTrangThai(String trangThai) async {
    final response = await _dio.get('/lich-kham/trang-thai/$trangThai');
    final data = response.data as List<dynamic>;
    return data.map((json) => LichKhamEntity.fromJson(json)).toList();
  }

  /// Lấy danh sách lịch khám trong ngày (loại bỏ trạng thái HUY, QUA_HEN)
  Future<List<LichKhamEntity>> getAppointmentsByDate(String ngayKham) async {
    final response = await _dio.get('/lich-kham/today', queryParameters: {'ngayKham': ngayKham});
    final data = response.data as List<dynamic>;
    return data.map((json) => LichKhamEntity.fromJson(json)).toList();
  }

  /// Lấy lịch khám theo bác sĩ và ngày
  Future<List<LichKhamEntity>> getByDoctorAndDate(int maBacSi, String ngayKham) async {
    final response = await _dio.get('/lich-kham/bac-si/$maBacSi/ngay', queryParameters: {'ngayKham': ngayKham});
    final data = response.data as List<dynamic>;
    return data.map((json) => LichKhamEntity.fromJson(json)).toList();
  }

  /// Lấy lịch khám trong khoảng thời gian
  Future<List<LichKhamEntity>> getBetweenDates(String startDate, String endDate) async {
    final response = await _dio.get('/lich-kham/khoang-thoi-gian', queryParameters: {
      'startDate': startDate,
      'endDate': endDate,
    });
    final data = response.data as List<dynamic>;
    return data.map((json) => LichKhamEntity.fromJson(json)).toList();
  }

  // ==================== THAY ĐỔI TRẠNG THÁI ====================

  /// Cập nhật trạng thái lịch khám
  Future<LichKhamEntity> updateTrangThai(int id, String trangThai) async {
    final response = await _dio.put('/lich-kham/$id/trang-thai', data: {'trangThai': trangThai});
    return LichKhamEntity.fromJson(response.data);
  }

  // ==================== TÌM KIẾM / LỌC ====================

  /// Tìm kiếm lịch khám theo nhiều điều kiện (tất cả đều optional)
  /// - [trangThai]: "CHUA_DEN", "DA_CHECK_IN", "HOAN_THANH", "HUY", "QUA_HEN"
  /// - [maChuyenKhoa]: mã chuyên khoa
  /// - [maDichVu]: mã dịch vụ
  /// - [ngayKham]: ngày khám (yyyy-MM-dd), nếu null thì tìm tất cả các ngày
  /// - [todayOnly]: nếu true, tự động lọc theo ngày hiện tại
  Future<List<LichKhamEntity>> searchAppointments({
    String? trangThai,
    int? maChuyenKhoa,
    int? maDichVu,
    String? ngayKham,
    bool todayOnly = false,
  }) async {
    final queryParams = <String, dynamic>{};

    if (todayOnly) {
      final now = DateTime.now();
      ngayKham =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }

    if (trangThai != null && trangThai.isNotEmpty) {
      queryParams['trangThai'] = trangThai;
    }
    if (maChuyenKhoa != null && maChuyenKhoa > 0) {
      queryParams['maChuyenKhoa'] = maChuyenKhoa.toString();
    }
    if (maDichVu != null && maDichVu > 0) {
      queryParams['maDichVu'] = maDichVu.toString();
    }
    if (ngayKham != null && ngayKham.isNotEmpty) {
      queryParams['ngayKham'] = ngayKham;
    }

    final response = await _dio.get('/lich-kham/search', queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final data = response.data as List<dynamic>;
    return data.map((json) => LichKhamEntity.fromJson(json)).toList();
  }
}

/// Kết quả tạo lịch khám: lịch vừa tạo + cảnh báo (nếu có).
///
/// Backend trả kèm `warning` khi bệnh nhân đã vắng mặt 3 lần trong tháng
/// (ngưỡng chặn là > 3). Khi đó lịch VẪN được tạo thành công, chỉ cần hiển thị cảnh báo.
class CreateLichKhamResult {
  final LichKhamEntity lichKham;
  final String? warning;

  const CreateLichKhamResult({required this.lichKham, this.warning});
}