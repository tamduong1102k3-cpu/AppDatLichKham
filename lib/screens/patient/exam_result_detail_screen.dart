import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/patient_exam_history.dart';
import '../../screens/patient/ca_kham_detail_screen.dart';
import '../../services/patient_exam_history_service.dart';
import '../../widgets/zoomable_image_viewer.dart';

class ExamResultDetailScreen extends StatefulWidget {
  final int maBenhNhan;
  final ExamHistoryEntry examination;

  const ExamResultDetailScreen({
    super.key,
    required this.maBenhNhan,
    required this.examination,
  });

  @override
  State<ExamResultDetailScreen> createState() => _ExamResultDetailScreenState();
}

class _ExamResultDetailScreenState extends State<ExamResultDetailScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryColor = Color(0xFF00796B);
  static const Color _foregroundColor = Color(0xFF1E293B);
  static const Color _mutedForeground = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final _service = PatientExamHistoryService();
  late final Future<List<ExamHistoryResult>> _future;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _future = _service.getResults(
      maBenhNhan: widget.maBenhNhan,
      maPhieuKham: widget.examination.maPhieuKham,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không rõ ngày';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Chi tiết phiếu khám'),
        backgroundColor: Colors.white,
        foregroundColor: _foregroundColor,
        elevation: 0,
      ),
      body: FutureBuilder<List<ExamHistoryResult>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không thể tải kết quả khám: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final results = snapshot.data ?? const <ExamHistoryResult>[];
          final clinicalResults = results
              .where(
                (result) =>
                    result.loaiKetQua != 'XET_NGHIEM' &&
                    result.loaiKetQua != 'CDHA',
              )
              .toList();
          final labResults = results
              .where((result) => result.loaiKetQua == 'XET_NGHIEM')
              .toList();
          final imagingResults = results
              .where((result) => result.loaiKetQua == 'CDHA')
              .toList();

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildHeader(results),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _borderColor),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        indicatorColor: _primaryColor,
                        indicatorWeight: 3,
                        labelColor: _primaryColor,
                        unselectedLabelColor: _mutedForeground,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        tabs: [
                          _buildTab(
                            Icons.medical_services_outlined,
                            'Khám lâm sàng',
                            clinicalResults.length,
                          ),
                          _buildTab(
                            Icons.biotech_outlined,
                            'Xét nghiệm',
                            labResults.length,
                          ),
                          _buildTab(
                            Icons.image_search_outlined,
                            'Chẩn đoán hình ảnh',
                            imagingResults.length,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildClinicalTab(clinicalResults),
                          _buildResultTab(
                            labResults,
                            emptyText: 'Chưa có kết quả xét nghiệm',
                            icon: Icons.science_outlined,
                            title: 'Xét nghiệm',
                          ),
                          _buildResultTab(
                            imagingResults,
                            emptyText: 'Chưa có kết quả chẩn đoán hình ảnh',
                            icon: Icons.image_outlined,
                            title: 'Chẩn đoán hình ảnh',
                            isImaging: true,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CaKhamDetailScreen(
                                  maPhieuKham: widget.examination.maPhieuKham,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_outlined),
                          label: const Text('Xem chi tiết ca khám'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: const BorderSide(color: _primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(List<ExamHistoryResult> results) {
    final doctor = results
        .map((result) => result.tenNhanVien)
        .whereType<String>()
        .firstWhere((name) => name.trim().isNotEmpty, orElse: () => '');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phiếu khám #${widget.examination.maPhieuKham}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _headerInfo(
                Icons.calendar_today_outlined,
                'Ngày khám: ${_formatDate(widget.examination.ngayKham)}',
              ),
              if (doctor.isNotEmpty)
                _headerInfo(Icons.person_outline, 'Bác sĩ: $doctor'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _mutedForeground),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            softWrap: true,
            style: const TextStyle(fontSize: 13, color: _mutedForeground),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(IconData icon, String title, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 7),
          Text(title),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClinicalTab(List<ExamHistoryResult> results) {
    if (results.isEmpty) {
      return _buildEmptyState(
        'Chưa có thông tin khám lâm sàng',
        Icons.medical_services_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 16),
      children: [
        for (final result in results)
          _resultCard(
            title: 'Khám lâm sàng',
            icon: Icons.medical_services_outlined,
            result: result,
            sections: [
              if (_hasText(result.chuanDoanSoBo))
                _ResultSection(
                  'Chẩn đoán sơ bộ',
                  result.chuanDoanSoBo!,
                  highlighted: true,
                ),
              if (_hasText(result.khamLamSang))
                _ResultSection(
                  'Lý do khám / Khám lâm sàng',
                  result.khamLamSang!,
                ),
              if (_hasText(result.ghiChuThem))
                _ResultSection('Ghi chú', result.ghiChuThem!),
              if (_hasText(result.ketLuan))
                _ResultSection('Kết luận', result.ketLuan!, highlighted: true),
              if (_hasText(result.loiDanBacSi))
                _ResultSection('Lời dặn bác sĩ', result.loiDanBacSi!),
            ],
          ),
      ],
    );
  }

  Widget _buildResultTab(
    List<ExamHistoryResult> results, {
    required String emptyText,
    required IconData icon,
    required String title,
    bool isImaging = false,
  }) {
    if (results.isEmpty) return _buildEmptyState(emptyText, icon);

    return ListView(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 16),
      children: [
        for (final result in results)
          _resultCard(
            title: title,
            icon: icon,
            result: result,
            sections: [
              if (_hasText(result.ketLuan))
                _ResultSection('Kết luận', result.ketLuan!, highlighted: true),
              if (_hasText(result.chuanDoanSoBo))
                _ResultSection('Chẩn đoán sơ bộ', result.chuanDoanSoBo!),
              if (_hasText(result.khamLamSang))
                _ResultSection('Chi tiết', result.khamLamSang!),
              if (_hasText(result.moTaHinhAnh))
                _ResultSection(
                  isImaging ? 'Mô tả hình ảnh' : 'Mô tả',
                  result.moTaHinhAnh!,
                ),
              if (_hasText(result.ghiChuThem))
                _ResultSection('Ghi chú', result.ghiChuThem!),
              if (_hasText(result.deNghi))
                _ResultSection('Đề nghị', result.deNghi!),
              if (_hasText(result.loiDanBacSi))
                _ResultSection('Lời dặn bác sĩ', result.loiDanBacSi!),
            ],
            images: isImaging ? result.hinhAnh : const [],
          ),
      ],
    );
  }

  Widget _resultCard({
    required String title,
    required IconData icon,
    required ExamHistoryResult result,
    required List<_ResultSection> sections,
    List<String> images = const [],
  }) {
    final cleanedImages = images
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: _primaryColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _foregroundColor,
                  ),
                ),
              ),
            ],
          ),
          if (_hasText(result.tenNhanVien)) ...[
            const SizedBox(height: 12),
            _headerInfo(Icons.person_outline, result.tenNhanVien!),
          ],
          if (sections.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (int i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _buildSection(sections[i]),
            ],
          ],
          if (cleanedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'HÌNH ẢNH (${cleanedImages.length})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _mutedForeground,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 9),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = math.min(220.0, constraints.maxWidth);
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (int i = 0; i < cleanedImages.length; i++)
                      _imageThumbnail(context, cleanedImages, i, tileWidth),
                  ],
                );
              },
            ),
          ],
          if (sections.isEmpty && cleanedImages.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Chưa có thông tin chi tiết',
                style: TextStyle(color: _mutedForeground, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(_ResultSection section) {
    final background = section.highlighted
        ? const Color(0xFFE0F2F1)
        : Colors.transparent;
    return Container(
      width: double.infinity,
      padding: section.highlighted ? const EdgeInsets.all(12) : EdgeInsets.zero,
      decoration: section.highlighted
          ? BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFB2DFDB)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: section.highlighted ? _primaryColor : _mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            section.value,
            style: const TextStyle(
              fontSize: 14,
              color: _foregroundColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageThumbnail(
    BuildContext context,
    List<String> images,
    int index,
    double width,
  ) {
    return GestureDetector(
      onTap: () => ZoomableImageViewer.show(
        context: context,
        images: images,
        initialIndex: index,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFFF1F5F9),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: _mutedForeground,
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const ColoredBox(
                    color: Color(0xFFF1F5F9),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.zoom_in, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _mutedForeground, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasText(String? value) => value?.trim().isNotEmpty == true;
}

class _ResultSection {
  final String title;
  final String value;
  final bool highlighted;

  const _ResultSection(this.title, this.value, {this.highlighted = false});
}
