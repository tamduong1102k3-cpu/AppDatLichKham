class DichVu {
  final int maDichVu;
  final String tenDichVu;
  final double donGia;
  final String? loaiDichVu;
  final int? maChuyenKhoa;

  DichVu({
    required this.maDichVu,
    required this.tenDichVu,
    required this.donGia,
    this.loaiDichVu,
    this.maChuyenKhoa,
  });

  factory DichVu.fromJson(Map<String, dynamic> json) {
    return DichVu(
      maDichVu: (json['maDichVu'] as num?)?.toInt() ?? 0,
      tenDichVu: (json['tenDichVu'] as String?)?.trim() ?? '',
      donGia: (json['donGia'] as num?)?.toDouble() ?? 0.0,
      loaiDichVu: json['loaiDichVu'] as String?,
      maChuyenKhoa: (json['maChuyenKhoa'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maDichVu': maDichVu,
      'tenDichVu': tenDichVu,
      'donGia': donGia,
      'loaiDichVu': loaiDichVu,
      'maChuyenKhoa': maChuyenKhoa,
    };
  }
}
