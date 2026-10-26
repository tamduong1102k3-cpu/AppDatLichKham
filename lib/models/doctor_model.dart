import '../data/entities/bang_phan_cong_ca_lam_entity.dart';
import '../data/entities/nhan_vien_entity.dart';

class DoctorModel {
  final int id;
  final String name;
  final String title;
  final String specialty;
  final int? chuyenKhoaId;
  final String price;
  final double rating;
  final int reviews;
  final int? gioiTinh;
  final List<BangPhanCongCaLamEntity> schedules;
  final List<String> weeklyDays;

  DoctorModel({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    this.chuyenKhoaId,
    this.price = '150.000đ',
    this.rating = 5.0,
    this.reviews = 0,
    this.gioiTinh,
    this.schedules = const [],
    this.weeklyDays = const [],
  });

  factory DoctorModel.fromNhanVien(NhanVienEntity entity) {
    return DoctorModel(
      id: entity.maNhanVien,
      name: entity.hoTen,
      title: entity.chucVu ?? 'Bác sĩ',
      specialty: '',
      chuyenKhoaId: entity.chuyenKhoa,
      price: '150.000đ',
      gioiTinh: entity.gioiTinh,
    );
  }


  List<BangPhanCongCaLamEntity> get todaySchedules {
    final now = DateTime.now();
    final thuHienTai = _getThuFromDate(now);
    return schedules.where((s) => s.thu == thuHienTai).toList();
  }


  static String _getThuFromDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Thứ 2';
      case DateTime.tuesday:
        return 'Thứ 3';
      case DateTime.wednesday:
        return 'Thứ 4';
      case DateTime.thursday:
        return 'Thứ 5';
      case DateTime.friday:
        return 'Thứ 6';
      case DateTime.saturday:
        return 'Thứ 7';
      case DateTime.sunday:
        return 'Chủ nhật';
      default:
        return 'Thứ 2';
    }
  }


  static String _shortThu(String thu) {
    switch (thu) {
      case 'Thứ 2': return 'T2';
      case 'Thứ 3': return 'T3';
      case 'Thứ 4': return 'T4';
      case 'Thứ 5': return 'T5';
      case 'Thứ 6': return 'T6';
      case 'Thứ 7': return 'T7';
      case 'Chủ nhật': return 'CN';
      default: return thu;
    }
  }


  String get scheduleSummary {
    if (schedules.isEmpty) return 'Chưa có lịch';

    // Thứ tự trong tuần (tiếng Việt)
    final weekOrder = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];

    final buffer = StringBuffer();
    for (final thu in weekOrder) {
      final ds = schedules.where((s) => s.thu == thu).toList();
      if (ds.isEmpty) continue;

      if (buffer.isNotEmpty) buffer.write(' | ');
      buffer.write(_shortThu(thu));

      final first = ds.first;
      if (first.gioLam != null && first.gioKetThuc != null) {
        final gioBatDau = first.gioLam!.length >= 5 ? first.gioLam!.substring(0, 5) : first.gioLam!;
        final gioKetThuc = first.gioKetThuc!.length >= 5 ? first.gioKetThuc!.substring(0, 5) : first.gioKetThuc!;
        buffer.write(' $gioBatDau-$gioKetThuc');
      }
    }
    return buffer.toString();
  }
}