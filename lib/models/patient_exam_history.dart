class VisitedSpecialty {
  final int maChuyenKhoa;
  final String tenChuyenKhoa;

  const VisitedSpecialty({
    required this.maChuyenKhoa,
    required this.tenChuyenKhoa,
  });

  factory VisitedSpecialty.fromJson(Map<String, dynamic> json) {
    return VisitedSpecialty(
      maChuyenKhoa: _readInt(json['maChuyenKhoa']),
      tenChuyenKhoa: json['tenChuyenKhoa']?.toString() ?? '',
    );
  }
}

class ExamHistoryEntry {
  final int maPhieuKham;
  final DateTime? ngayKham;
  final String? trangThai;

  const ExamHistoryEntry({
    required this.maPhieuKham,
    this.ngayKham,
    this.trangThai,
  });

  factory ExamHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ExamHistoryEntry(
      maPhieuKham: _readInt(json['maPhieuKham']),
      ngayKham: DateTime.tryParse(json['ngayKham']?.toString() ?? ''),
      trangThai: json['trangThai']?.toString(),
    );
  }
}

class ExamHistoryResult {
  final String loaiKetQua;
  final String? chuanDoanSoBo;
  final String? khamLamSang;
  final String? loiDanBacSi;
  final String? ketLuan;
  final String? ghiChuThem;
  final String? moTaHinhAnh;
  final String? deNghi;
  final String? tenNhanVien;
  final int? maBacSiThucHien;
  final List<String> hinhAnh;

  const ExamHistoryResult({
    required this.loaiKetQua,
    this.chuanDoanSoBo,
    this.khamLamSang,
    this.loiDanBacSi,
    this.ketLuan,
    this.ghiChuThem,
    this.moTaHinhAnh,
    this.deNghi,
    this.tenNhanVien,
    this.maBacSiThucHien,
    this.hinhAnh = const [],
  });

  factory ExamHistoryResult.fromJson(Map<String, dynamic> json) {
    return ExamHistoryResult(
      loaiKetQua: json['loaiKetQua']?.toString() ?? '',
      chuanDoanSoBo: json['chuanDoanSoBo']?.toString(),
      khamLamSang: json['khamLamSang']?.toString(),
      loiDanBacSi: json['loiDanBacSi']?.toString(),
      ketLuan: json['ketLuan']?.toString(),
      ghiChuThem: json['ghiChuThem']?.toString(),
      moTaHinhAnh: json['moTaHinhAnh']?.toString(),
      deNghi: json['deNghi']?.toString(),
      tenNhanVien: json['tenNhanVien']?.toString(),
      maBacSiThucHien: _readNullableInt(json['maBacSiThucHien']),
      hinhAnh: (json['hinhAnh'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

int _readInt(dynamic value) {
  final result = _readNullableInt(value);
  if (result == null) {
    throw const FormatException('Thiếu mã trong dữ liệu lịch sử khám');
  }
  return result;
}

int? _readNullableInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
