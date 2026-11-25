import 'package:flutter/material.dart';

import '../../../models/patient_exam_history.dart';
import '../../../screens/patient/exam_result_detail_screen.dart';
import '../../../services/patient_exam_history_service.dart';

class VisitedSpecialtiesSection extends StatefulWidget {
  final int? maBenhNhan;

  const VisitedSpecialtiesSection({super.key, required this.maBenhNhan});

  @override
  State<VisitedSpecialtiesSection> createState() =>
      _VisitedSpecialtiesSectionState();
}

class _VisitedSpecialtiesSectionState extends State<VisitedSpecialtiesSection> {
  static const Color _primaryColor = Color(0xFF0F766E);
  static const Color _foregroundColor = Color(0xFF1E293B);
  static const Color _mutedForeground = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final _service = PatientExamHistoryService();
  bool _isLoading = true;
  String? _error;
  List<VisitedSpecialty> _specialties = [];
  final Map<int, List<ExamHistoryEntry>> _examinations = {};
  final Set<int> _loadingSpecialties = {};
  final Map<int, String> _specialtyErrors = {};

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    if (widget.maBenhNhan == null) {
      setState(() {
        _error = 'Không tìm thấy mã bệnh nhân trong phiên đăng nhập.';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final specialties = await _service.getVisitedSpecialties(
        widget.maBenhNhan!,
      );
      if (!mounted) return;
      setState(() {
        _specialties = specialties;
        _isLoading = false;
      });
      for (final specialty in specialties) {
        _loadExaminations(specialty.maChuyenKhoa);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExaminations(int maChuyenKhoa) async {
    if (_examinations.containsKey(maChuyenKhoa) ||
        _loadingSpecialties.contains(maChuyenKhoa)) {
      return;
    }
    setState(() {
      _loadingSpecialties.add(maChuyenKhoa);
      _specialtyErrors.remove(maChuyenKhoa);
    });
    try {
      final examinations = await _service.getExaminations(
        maBenhNhan: widget.maBenhNhan!,
        maChuyenKhoa: maChuyenKhoa,
      );
      if (!mounted) return;
      setState(() => _examinations[maChuyenKhoa] = examinations);
    } catch (error) {
      if (!mounted) return;
      setState(() => _specialtyErrors[maChuyenKhoa] = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingSpecialties.remove(maChuyenKhoa));
      }
    }
  }

  void _showResults(ExamHistoryEntry examination) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExamResultDetailScreen(
          maBenhNhan: widget.maBenhNhan!,
          examination: examination,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không rõ ngày';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.medical_information_outlined,
                  color: _primaryColor,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Các chuyên khoa đã khám',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  const Text(
                    'Chưa có lịch sử khám bệnh',
                    style: TextStyle(color: _mutedForeground),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  TextButton.icon(
                    onPressed: _loadSpecialties,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          else if (_specialties.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Text(
                'Chưa có lịch sử khám bệnh',
                style: TextStyle(color: _mutedForeground),
              ),
            )
          else
            ..._specialties.map(_buildSpecialtyTile),
        ],
      ),
    );
  }

  Widget _buildSpecialtyTile(VisitedSpecialty specialty) {
    final id = specialty.maChuyenKhoa;
    final isLoading = _loadingSpecialties.contains(id);
    final exams = _examinations[id]
        ?.where((t) => t.trangThai == 'HOAN_THANH')
        .toList();
    final error = _specialtyErrors[id];
    final latestDate = exams == null || exams.isEmpty
        ? null
        : exams
            .map((exam) => exam.ngayKham)
            .whereType<DateTime>()
            .fold<DateTime?>(
              null,
              (latest, date) => latest == null || date.isAfter(latest)
                  ? date
                  : latest,
            );
    final count = exams?.length ?? 0;
    final subtitle = exams == null
        ? 'Đang tải...'
        : count == 0
            ? 'Chưa có phiếu khám'
            : 'Lần khám cuối: ${_formatDate(latestDate)} • $count phiếu';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('visited-specialty-$id'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: const Icon(
            Icons.medical_services_outlined,
            color: _primaryColor,
          ),
          title: Text(
            specialty.tenChuyenKhoa,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _foregroundColor,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: _mutedForeground,
              ),
            ),
          ),
          trailing: const Icon(
            Icons.expand_more,
            color: _mutedForeground,
          ),
          onExpansionChanged: (expanded) {
            if (expanded) _loadExaminations(id);
          },
          children: [
            Container(
              margin: const EdgeInsets.only(left: 24, right: 12, bottom: 12),
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (error != null)
                    ListTile(
                      title: Text(
                        error,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          _examinations.remove(id);
                          _loadExaminations(id);
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                    )
                  else if (exams == null || exams.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Không có phiếu khám trong chuyên khoa này.',
                        style: TextStyle(
                          color: _mutedForeground,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    ...exams.map(
                      (exam) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.description_outlined,
                          color: _mutedForeground,
                          size: 20,
                        ),
                        title: Text(
                          'Phiếu khám ${exam.maPhieuKham} ngày ${_formatDate(exam.ngayKham)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _mutedForeground,
                          ),
                        ),
                        onTap: () => _showResults(exam),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
