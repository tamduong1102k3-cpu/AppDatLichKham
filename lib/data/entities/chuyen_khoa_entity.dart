class ChuyenKhoaEntity {
  final int maChuyenKhoa;
  final String tenChuyenKhoa;
  final String? moTa;
  final int? soLuongToiDa;

  ChuyenKhoaEntity({
    required this.maChuyenKhoa,
    required this.tenChuyenKhoa,
    this.moTa,
    this.soLuongToiDa,
  });

  factory ChuyenKhoaEntity.fromJson(Map<String, dynamic> json) {
    return ChuyenKhoaEntity(
      maChuyenKhoa: (json['maChuyenKhoa'] as num?)?.toInt() ?? 0,
      tenChuyenKhoa: (json['tenChuyenKhoa'] as String?)?.trim() ?? '',
      moTa: (json['moTa'] as String?)?.trim(),
      soLuongToiDa: (json['soLuongToiDa'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maChuyenKhoa': maChuyenKhoa,
      'tenChuyenKhoa': tenChuyenKhoa,
      'moTa': moTa,
      'soLuongToiDa': soLuongToiDa,
    };
  }
}