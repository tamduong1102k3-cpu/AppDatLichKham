import 'package:flutter/material.dart';
import '../../../../data/entities/bang_phan_cong_ca_lam_entity.dart';
import '../../../../data/entities/chuyen_khoa_entity.dart';
import '../../../../data/entities/lich_thang_entity.dart';
import '../../../../data/entities/nhan_vien_entity.dart';
import '../../../../repositories/bang_phan_cong_repository.dart';
import '../../../../repositories/chuyen_khoa_repository.dart';
import '../../../../repositories/nhan_vien_repository.dart';
import '../../../../utils/auth_guard.dart';
import '../../../../utils/toast_helper.dart';
import '../../../appointment/appointment_booking_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final int doctorId;

  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  final NhanVienRepository _nhanVienRepo = NhanVienRepository();
  final BangPhanCongRepository _phanCongRepo = BangPhanCongRepository();
  final ChuyenKhoaRepository _chuyenKhoaRepo = ChuyenKhoaRepository();

  NhanVienEntity? _doctor;
  ChuyenKhoaEntity? _specialty;
  List<NgayCaLamEntity> _days = [];
  NgayCaLamEntity? _selectedDay;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });


      final doctor = await _nhanVienRepo.getById(widget.doctorId);

      final now = DateTime.now();


      final scheduleFuture = _phanCongRepo.getLichThang(
        widget.doctorId,
        now.year,
        now.month,
      );

      Future<ChuyenKhoaEntity?> specialtyFuture = Future.value(null);
      if (doctor.chuyenKhoa != null) {
        specialtyFuture = _chuyenKhoaRepo
            .getById(doctor.chuyenKhoa!)
            .then<ChuyenKhoaEntity?>((value) => value)
            .catchError((_) => null);
      }

      final results = await Future.wait([scheduleFuture, specialtyFuture]);
      final monthSchedule = results[0] as LichThangEntity;
      final specialty = results[1] as ChuyenKhoaEntity?;


      final days = [
        for (final day in monthSchedule.days)
          if (day.resolved.any((schedule) => !schedule.isNghiPhep)) day,
      ];
      days.sort((a, b) {
        final dateCompare = (a.date ?? DateTime(9999)).compareTo(b.date ?? DateTime(9999));
        return dateCompare;
      });

      if (!mounted) return;
      setState(() {
        _doctor = doctor;
        _days = days;
        _selectedDay = null;
        _specialty = specialty;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }


  String _getAvatarAsset(int? gioiTinh) {
    return gioiTinh == 1
        ? 'assets/images/employee/doctor male.png'
        : 'assets/images/employee/doctor female.png';
  }

  String _getGenderText(int? gioiTinh) {
    if (gioiTinh == null) return 'Chưa cập nhật';
    return gioiTinh == 1 ? 'Nam' : 'Nữ';
  }

  String _formatGioDisplay(String? time) {
    if (time == null || time.length < 5) return '';
    return time.substring(0, 5);
  }


  String _displayThu(String? thu) {
    switch (thu) {
      case 'Thứ 2':
      case 'THU_2':
        return 'Thứ 2';
      case 'Thứ 3':
      case 'THU_3':
        return 'Thứ 3';
      case 'Thứ 4':
      case 'THU_4':
        return 'Thứ 4';
      case 'Thứ 5':
      case 'THU_5':
        return 'Thứ 5';
      case 'Thứ 6':
      case 'THU_6':
        return 'Thứ 6';
      case 'Thứ 7':
      case 'THU_7':
        return 'Thứ 7';
      case 'Chủ Nhật':
      case 'Chủ nhật':
      case 'CHU_NHAT':
        return 'Chủ Nhật';
      default:
        return thu ?? '';
    }
  }


  String _shortThu(String? thu) {
    switch (thu) {
      case 'Thứ 2':
      case 'THU_2':
        return 'T2';
      case 'Thứ 3':
      case 'THU_3':
        return 'T3';
      case 'Thứ 4':
      case 'THU_4':
        return 'T4';
      case 'Thứ 5':
      case 'THU_5':
        return 'T5';
      case 'Thứ 6':
      case 'THU_6':
        return 'T6';
      case 'Thứ 7':
      case 'THU_7':
        return 'T7';
      case 'Chủ Nhật':
      case 'Chủ nhật':
      case 'CHU_NHAT':
        return 'CN';
      default:
        return thu ?? '';
    }
  }


  String _formatDateDetail(DateTime? date) {
    if (date == null) return '';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }


  int _countCa(NgayCaLamEntity day) {
    return day.resolved.where((s) => !s.isNghiPhep).length;
  }


  String _formatDateYmd(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Thông tin bác sĩ',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _buildBody(),
      bottomNavigationBar: _doctor == null || _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_selectedDay == null) {
                      ToastHelper.error(
                        context: context,
                        title: 'Vui lòng chọn ngày khám',
                      );
                      return;
                    }

                    final loggedIn = await requireLogin(context);
                    if (!loggedIn || !context.mounted) return;

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppointmentBookingScreen(
                          initialChuyenKhoa: _specialty,
                          initialBacSi: _doctor,
                          initialNgayKham: _formatDateYmd(_selectedDay!.date!),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ĐẶT LỊCH HẸN NGAY',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blue),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Lỗi khi tải thông tin: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDoctorData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_doctor == null) {
      return const Center(child: Text('Không tìm thấy thông tin bác sĩ.'));
    }

    final doc = _doctor!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Avatar + Name + Specialty)
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                ClipOval(
                  child: Image.asset(
                    _getAvatarAsset(doc.gioiTinh),
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      final initials = doc.hoTen.isNotEmpty ? doc.hoTen[0].toUpperCase() : '?';
                      return Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0F2FE),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  doc.hoTen,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  doc.chucVu ?? 'Bác sĩ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                if (_specialty != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _specialty!.tenChuyenKhoa,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Details Information Section
          _buildSectionTitle('Thông tin chi tiết'),
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildInfoRow(
                    Icons.wc_rounded, 'Giới tính', _getGenderText(doc.gioiTinh)),
                const Divider(height: 1),
                _buildInfoRow(Icons.school_rounded, 'Bằng cấp',
                    doc.bangCap ?? 'Chưa cập nhật'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Working Schedule Section
          _buildSectionTitle('Lịch làm việc'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _days.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có lịch khám được phân công',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grid các ngày có ca
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final day in _days)
                            _buildDayTile(day),
                        ],
                      ),
                      // Section chi tiết ngày đã chọn
                      if (_selectedDay != null) ...[
                        const SizedBox(height: 20),
                        _buildDayDetail(_selectedDay!),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Ô vuông 64x64 trong grid
  Widget _buildDayTile(NgayCaLamEntity day) {
    final date = day.date!;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final isPast = date.isBefore(todayOnly);
    final isSelected = _selectedDay?.ngay == day.ngay;
    final weekday = _shortThu(day.thu);

    return InkWell(
      onTap: isPast ? null : () => setState(() => _selectedDay = day),
      borderRadius: BorderRadius.circular(10),
      child: Opacity(
        opacity: isPast ? 0.4 : 1.0,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F766E)
                : (isPast ? Colors.grey.shade100 : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0F766E)
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$weekday/${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isPast ? Colors.grey : const Color(0xFF1E293B)),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${day.resolved.length} ca',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected
                      ? Colors.white70
                      : (isPast
                          ? Colors.grey.shade500
                          : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section chi tiết ngày đã chọn
  Widget _buildDayDetail(NgayCaLamEntity day) {
    final shifts = day.resolved.where((s) => !s.isNghiPhep).toList();
    if (shifts.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết ngày ${_formatDateDetail(day.date)} — ${_displayThu(day.thu)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          for (final sched in shifts) ...[
            _buildShiftRow(sched),
            if (sched != shifts.last) const Divider(height: 16),
          ],
        ],
      ),
    );
  }

  /// Một ca trong section chi tiết
  Widget _buildShiftRow(BangPhanCongCaLamEntity sched) {
    final ca = sched.ca;
    if (ca == null) return const SizedBox.shrink();

    final start = ca.gioBatDauHhmm;
    final end = _formatGioDisplay(ca.gioKetThuc);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDFA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            size: 18,
            color: Color(0xFF0F766E),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ca.tenCaDisplay,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$start - $end',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[400]),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}