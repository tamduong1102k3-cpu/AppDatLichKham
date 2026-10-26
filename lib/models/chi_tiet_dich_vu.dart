import 'chi_so_xet_nghiem.dart';

class ChiTietDichVu {
  final int maChiTietChiDinh;
  final String tenDichVu;
  final String? loai;
  final String? trangThai;
  final String? chiSoXetNghiem;
  final String? ketQuaXetNghiem;
  final String? donViXetNghiem;
  final String? chiSoBinhThuong;
  final String? ketQuaCdha;
  final String? moTaCdha;
  final String? ketLuanCdha;
  final String? hinhAnhCdha;

  final List<String> danhSachAnhCdha;
  final String? bacSiDocKetQua;
  final String? ngayDocKetQua;

  final String? tenBsKetLuan;

  final String? tenBsCdha;

  final String? tenKyThuatVien;
  final List<ChiSoXetNghiem> chiTietChiSoXetNghiem;

  ChiTietDichVu({
    required this.maChiTietChiDinh,
    required this.tenDichVu,
    this.loai,
    this.trangThai,
    this.chiSoXetNghiem,
    this.ketQuaXetNghiem,
    this.donViXetNghiem,
    this.chiSoBinhThuong,
    this.ketQuaCdha,
    this.moTaCdha,
    this.ketLuanCdha,
    this.hinhAnhCdha,
    this.danhSachAnhCdha = const [],
    this.bacSiDocKetQua,
    this.ngayDocKetQua,
    this.tenBsKetLuan,
    this.tenBsCdha,
    this.tenKyThuatVien,
    this.chiTietChiSoXetNghiem = const [],
  });

  factory ChiTietDichVu.fromJson(Map<String, dynamic> json) {

    final chiTietChiDinh = json['chiTietChiDinh'] as Map<String, dynamic>? ?? {};

    final dichVu = json['dichVu'] as Map<String, dynamic>?;

    final ketQuaXetNghiem = json['ketQuaXetNghiem'] as Map<String, dynamic>?;

    final ketQuaCdha = json['ketQuaCdha'] as Map<String, dynamic>?;

    final chiSoXetNghiemList = json['chiSoXetNghiem'] as List<dynamic>?;


    String? combinedXnResult;
    if (ketQuaXetNghiem != null) {
      combinedXnResult = ketQuaXetNghiem['ketLuan'] as String?;
    }


    final rawGallery = ketQuaCdha?['danhSachAnh'] as List?;
    List<String> gallery = [];
    if (rawGallery != null) {
      gallery = rawGallery
          .whereType<String>()
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (gallery.isEmpty) {
      gallery = [
        ketQuaCdha?['duongDanAnh1'],
        ketQuaCdha?['duongDanAnh2']
      ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    String? hinhAnhStr = gallery.isEmpty ? null : gallery.join('\n');

    return ChiTietDichVu(
      maChiTietChiDinh: chiTietChiDinh['id'] as int? ??
          chiTietChiDinh['maChiTietChiDinh'] as int? ??
          0,
      tenDichVu: dichVu?['tenDichVu'] as String? ?? '',
      loai: dichVu?['loaiDichVu'] as String?,
      trangThai: chiTietChiDinh['trangThaiDv'] as String?,
      chiSoXetNghiem: null,
      ketQuaXetNghiem: combinedXnResult,
      donViXetNghiem: null,
      chiSoBinhThuong: null,
      ketQuaCdha: ketQuaCdha?['ketLuan'] as String?,
      moTaCdha: ketQuaCdha?['moTaHinhAnh'] as String?,
      ketLuanCdha: ketQuaCdha?['deNghi'] as String?,
      hinhAnhCdha: hinhAnhStr,
      danhSachAnhCdha: gallery,
      bacSiDocKetQua: chiTietChiDinh['maNhanVienThucHien']?.toString(),
      ngayDocKetQua: ketQuaXetNghiem?['ngayThucHien']?.toString(),
      tenBsKetLuan: json['tenBsKetLuan'] as String?,
      tenBsCdha: json['tenBsCdha'] as String?,
      tenKyThuatVien: json['tenKyThuatVien'] as String?,
      chiTietChiSoXetNghiem: chiSoXetNghiemList
              ?.map(
                  (e) => ChiSoXetNghiem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maChiTietChiDinh': maChiTietChiDinh,
      'tenDichVu': tenDichVu,
      'loai': loai,
      'trangThai': trangThai,
      'chiSoXetNghiem': chiSoXetNghiem,
      'ketQuaXetNghiem': ketQuaXetNghiem,
      'donViXetNghiem': donViXetNghiem,
      'chiSoBinhThuong': chiSoBinhThuong,
      'ketQuaCdha': ketQuaCdha,
      'moTaCdha': moTaCdha,
      'ketLuanCdha': ketLuanCdha,
      'hinhAnhCdha': hinhAnhCdha,
      'danhSachAnhCdha': danhSachAnhCdha,
      'bacSiDocKetQua': bacSiDocKetQua,
      'ngayDocKetQua': ngayDocKetQua,
      'tenBsKetLuan': tenBsKetLuan,
      'tenBsCdha': tenBsCdha,
      'tenKyThuatVien': tenKyThuatVien,
      'chiTietChiSoXetNghiem':
          chiTietChiSoXetNghiem.map((e) => e.toJson()).toList(),
    };
  }
}