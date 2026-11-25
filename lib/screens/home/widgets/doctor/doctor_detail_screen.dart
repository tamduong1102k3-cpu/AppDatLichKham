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
import '../../../../services/server_time_service.dart';
import '../../../../widgets/custom_month_calendar.dart';

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
  Map<String, NgayCaLamEntity> _weekDaysByDate = {};
  String? _selectedDay;
  bool _isLoading = true;
  String? _error;

  static const List<String> _weekDayLabels = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];

  NgayCaLamEntity? get _selectedDaySchedule {
    final selectedDate = _selectedDay;
    if (selectedDate == null) return null;

    final parsedDate = DateTime.tryParse(selectedDate);
    if (parsedDate == null) return null;

    for (final day in _days) {
      if (day.ngay == selectedDate) return day;
    }
    return null;
  }

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

      final now = ServerTimeService.now();

      final today = DateTime(now.year, now.month, now.day);
      final rangeStart = today.subtract(Duration(days: today.weekday - 1));
      final rangeEnd = rangeStart.add(const Duration(days: 13));

      // Lấy lịch của các tháng mà 14 ngày đi qua (tối đa 2 tháng)
      final monthsToFetch = <Map<String, int>>[];
      var cursor = DateTime(rangeStart.year, rangeStart.month, 1);
      final lastMonth = DateTime(rangeEnd.year, rangeEnd.month, 1);
      while (!cursor.isAfter(lastMonth)) {
        monthsToFetch.add({'year': cursor.year, 'month': cursor.month});
        // next month
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }

      final scheduleFutures = monthsToFetch
          .map((m) => _phanCongRepo.getLichThang(widget.doctorId, m['year']!, m['month']!))
          .toList();

      Future<ChuyenKhoaEntity?> specialtyFuture = Future.value(null);
      if (doctor.chuyenKhoa != null) {
        specialtyFuture = _chuyenKhoaRepo
            .getById(doctor.chuyenKhoa!)
            .then<ChuyenKhoaEntity?>((value) => value)
            .catchError((_) => null);
      }

      final results = await Future.wait<dynamic>([
        ...scheduleFutures,
        specialtyFuture,
      ]);
      final specialty = results.last as ChuyenKhoaEntity?;
      final schedules = results.sublist(0, scheduleFutures.length).cast<LichThangEntity>();

      final allDays = <NgayCaLamEntity>[];
      for (final s in schedules) {
        for (final day in s.days) {
          if (day.resolved.any((shift) => !shift.isNghiPhep)) {
            allDays.add(day);
          }
        }
      }
      allDays.sort((a, b) => (a.date ?? DateTime(9999)).compareTo(b.date ?? DateTime(9999)));

      final weekDaysByDate = <String, NgayCaLamEntity>{};
      for (final day in allDays) {
        final date = day.date;
        if (date == null) continue;
        if (date.isBefore(rangeStart) || date.isAfter(rangeEnd)) continue;
        weekDaysByDate[day.ngay] = day;
      }

      String? initialSelectedDay;
      for (var offset = 0; offset < 14; offset++) {
        final date = rangeStart.add(Duration(days: offset));
        final dateKey = _formatDateYmd(date);
        if (weekDaysByDate.containsKey(dateKey)) {
          initialSelectedDay = dateKey;
          break;
        }
      }
      initialSelectedDay ??= _formatDateYmd(rangeStart);

      if (!mounted) return;
      setState(() {
        _doctor = doctor;
        _days = allDays;
        _weekDaysByDate = weekDaysByDate;
        _selectedDay = initialSelectedDay;
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

  String _formatDateDetail(DateTime? date) {
    if (date == null) return '';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
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
                    final selectedDay = _selectedDaySchedule;
                    if (selectedDay == null) {
                      ToastHelper.error(
                        context: context,
                        title: 'Vui lòng chọn ngày khám',
                      );
                      return;
                    }
                    final appointmentDate = selectedDay.date;
                    if (appointmentDate == null ||
                        appointmentDate.isBefore(
                          DateTime(
                            ServerTimeService.now().year,
                            ServerTimeService.now().month,
                            ServerTimeService.now().day,
                          ),
                        )) {
                      ToastHelper.error(
                        context: context,
                        title: 'Không thể đặt lịch vào ngày đã qua',
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
                          initialNgayKham: _selectedDay,
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
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
                      final initials = doc.hoTen.isNotEmpty
                          ? doc.hoTen[0].toUpperCase()
                          : '?';
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                  Icons.wc_rounded,
                  'Giới tính',
                  _getGenderText(doc.gioiTinh),
                ),
                const Divider(height: 1),
                _buildInfoRow(
                  Icons.school_rounded,
                  'Bằng cấp',
                  doc.bangCap ?? 'Chưa cập nhật',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Working Schedule Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthCalendar(),
                const SizedBox(height: 20),
                // Section chi tiet ngay da chon
                if (_selectedDaySchedule != null) ...[
                  _buildDayDetail(_selectedDaySchedule!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMonthCalendar() {
    final now = ServerTimeService.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = today.subtract(Duration(days: today.weekday - 1));
    final visibleMonth = DateTime(rangeStart.year, rangeStart.month);
    final calendarDays = List.generate(14, (i) {
      final d = rangeStart.add(Duration(days: i));
      final key = _formatDateYmd(d);
      return _weekDaysByDate[key] ??
          NgayCaLamEntity(ngay: key, thu: '', resolved: const []);
    });

    return CustomMonthCalendar(
      visibleMonth: visibleMonth,
      days: calendarDays,
      selectedDate: _selectedDay,
      isLoading: false,
      emptyText: 'Bác sĩ chưa có lịch trong khoảng thời gian này.',
      onDateSelected: (dateKey) {
        setState(() => _selectedDay = dateKey);
      },
    );
  }

  DateTime _weekStartOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  Widget _buildWeekSection(String title, DateTime weekStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            for (var index = 0; index < 7; index++)
              _buildWeekDayTile(
                _weekDayLabels[(weekStart.add(Duration(days: index)).weekday - 1) % 7],
                weekStart.add(Duration(days: index)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekDayTile(String label, DateTime date) {
    final dateKey = _formatDateYmd(date);
    final now = ServerTimeService.now();
    final todayOnly = DateTime(now.year, now.month, now.day);
    final isPast = date.isBefore(todayOnly);
    final isCurrentMonth = date.year == now.year && date.month == now.month;
    final day = isCurrentMonth ? _weekDaysByDate[dateKey] : null;
    final hasSchedule = day != null;
    final isSelected = _selectedDay == dateKey;
    final isDisabled = !hasSchedule || isPast;

    const double tileWidth = 60;
    const double tileHeight = 70;
    const double headerHeight = 14; // nắp đỏ


    final Color headerColor = isDisabled
        ? const Color(0xFF9CA3AF)
        : const Color(0xFFEF4444);
    final Color bodyColor = isSelected
        ? const Color(0xFF0F766E)
        : (isDisabled ? const Color(0xFFE5E7EB) : Colors.white);
    final Color dayNumberColor = isSelected
        ? Colors.white
        : (isDisabled ? const Color(0xFF6B7280) : const Color(0xFF1F2937));

    return InkWell(
      onTap: isDisabled
          ? null
          : () => setState(() => _selectedDay = dateKey),
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          height: tileHeight,
          width: tileWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF0F766E).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: isSelected
                ? Border.all(color: const Color(0xFF0F766E), width: 2)
                : Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  // Header: nắp đỏ (không chứa chữ)
                  Container(
                    height: headerHeight,
                    decoration: BoxDecoration(
                      color: headerColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                  ),
                  // Body (~70%): hiển thị tên thứ
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: bodyColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: dayNumberColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // 2 khoen lo xo o vi tri tiep giap header/body
              Positioned(
                top: headerHeight - 6,
                left: 10,
                child: Container(
                  width: 6,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                top: headerHeight - 6,
                right: 10,
                child: Container(
                  width: 6,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(3),
                  ),
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
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
