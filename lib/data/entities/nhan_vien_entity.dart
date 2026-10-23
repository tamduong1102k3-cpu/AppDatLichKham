class NhanVienEntity {
  final int maNhanVien;
  final String hoTen;
  final int? gioiTinh;
  final DateTime? ngaySinh;
  final String? cccd;
  final String? diaChi;
  final String? soDienThoai;
  final String? email;
  final int? chuyenKhoa;
  final String? bangCap;
  final String? chucVu;
  final DateTime? ngayVaoLam;

  NhanVienEntity({
    required this.maNhanVien,
    required this.hoTen,
    this.gioiTinh,
    this.ngaySinh,
    this.cccd,
    this.diaChi,
    this.soDienThoai,
    this.email,
    this.chuyenKhoa,
    this.bangCap,
    this.chucVu,
    this.ngayVaoLam,
  });

  factory NhanVienEntity.fromJson(Map<String, dynamic> json) {
    return NhanVienEntity(
      maNhanVien: (json['maNhanVien'] as num?)?.toInt() ?? 0,
      hoTen: (json['hoTen'] as String?)?.trim() ?? '',
      gioiTinh: (json['gioiTinh'] as num?)?.toInt(),
      ngaySinh: (json['ngaySinh'] as String?) != null && (json['ngaySinh'] as String).trim().isNotEmpty ? DateTime.tryParse((json['ngaySinh'] as String).trim()) : null,
      cccd: (json['cccd'] as String?)?.trim(),
      diaChi: (json['diaChi'] as String?)?.trim(),
      soDienThoai: (json['soDienThoai'] as String?)?.trim(),
      email: (json['email'] as String?)?.trim(),
      chuyenKhoa: (json['chuyenKhoa'] as num?)?.toInt(),
      bangCap: (json['bangCap'] as String?)?.trim(),
      chucVu: (json['chucVu'] as String?)?.trim(),
      ngayVaoLam: (json['ngayVaoLam'] as String?) != null && (json['ngayVaoLam'] as String).trim().isNotEmpty ? DateTime.tryParse((json['ngayVaoLam'] as String).trim()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maNhanVien': maNhanVien,
      'hoTen': hoTen,
      'gioiTinh': gioiTinh,
      'ngaySinh': ngaySinh?.toIso8601String(),
      'cccd': cccd,
      'diaChi': diaChi,
      'soDienThoai': soDienThoai,
      'email': email,
      'chuyenKhoa': chuyenKhoa,
      'bangCap': bangCap,
      'chucVu': chucVu,
      'ngayVaoLam': ngayVaoLam?.toIso8601String(),
    };
  }
}