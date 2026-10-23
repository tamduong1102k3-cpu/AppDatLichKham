class ThongBaoModel {
  final int id;
  final int nguoiNhanId;
  final String loaiNguoiNhan;
  final String tieuDe;
  final String noiDung;
  final String? referenceType;
  final String? referenceId;
  final bool daDoc;
  final String createdAt;

  ThongBaoModel({
    required this.id,
    required this.nguoiNhanId,
    required this.loaiNguoiNhan,
    required this.tieuDe,
    required this.noiDung,
    this.referenceType,
    this.referenceId,
    required this.daDoc,
    required this.createdAt,
  });


  ThongBaoModel copyWith({bool? daDoc}) {
    return ThongBaoModel(
      id: id,
      nguoiNhanId: nguoiNhanId,
      loaiNguoiNhan: loaiNguoiNhan,
      tieuDe: tieuDe,
      noiDung: noiDung,
      referenceType: referenceType,
      referenceId: referenceId,
      daDoc: daDoc ?? this.daDoc,
      createdAt: createdAt,
    );
  }

  factory ThongBaoModel.fromJson(Map<String, dynamic> json) {
    return ThongBaoModel(
      id: json['id'] as int,

      nguoiNhanId: (json['nguoiNhanId'] ?? json['maTaiKhoan'] ?? 0) as int,
      loaiNguoiNhan: json['loaiNguoiNhan'] as String? ?? 'BENH_NHAN',
      tieuDe: json['tieuDe'] as String,
      noiDung: json['noiDung'] as String,
      referenceType: json['referenceType'] as String?,
      referenceId: json['referenceId'] as String?,
      daDoc: json['daDoc'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
    );
  }


  int? get referenceIdAsInt {
    if (referenceId == null) return null;
    return int.tryParse(referenceId!);
  }

  String get timeAgo {
    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays < 7) return '${diff.inDays} ngày trước';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return createdAt;
    }
  }
}