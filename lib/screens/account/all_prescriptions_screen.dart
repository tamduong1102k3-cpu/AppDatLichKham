import 'package:flutter/material.dart';
import '../../services/benh_nhan_service.dart';
import '../../models/toa_thuoc_chi_tiet.dart';
import '../../widgets/shimmer_loading.dart';

class AllPrescriptionsScreen extends StatefulWidget {
  const AllPrescriptionsScreen({super.key});

  @override
  State<AllPrescriptionsScreen> createState() => _AllPrescriptionsScreenState();
}

class _AllPrescriptionsScreenState extends State<AllPrescriptionsScreen> {
  final _benhNhanService = BenhNhanService();
  List<ToaThuocChiTiet> _prescriptions = [];
  bool _isLoading = true;
  String? _error;
  final Set<int> _expandedCards = {};

  // Filters
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const Color _primaryColor = Color(0xFF0891B2);
  static const Color _foregroundColor = Color(0xFF1E293B);
  static const Color _mutedForeground = Color(0xFF64748B);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _mutedColor = Color(0xFFF1F5F9);
  static const Color _tealColor = Color(0xFF0F766E);
  static const Color _highlightBg = Color(0xFFFFFBEB);

  List<ToaThuocChiTiet> get _filteredList {
    return _prescriptions.where((prescription) {
      // Filter by date range
      if (_fromDate != null || _toDate != null) {
        final ngay = prescription.ngayKeToa ?? '';
        if (ngay.length >= 10) {
          final dateStr = ngay.substring(0, 10);
          final dateParts = dateStr.split('-');
          if (dateParts.length == 3) {
            try {
              final pkDate = DateTime(
                int.parse(dateParts[0]),
                int.parse(dateParts[1]),
                int.parse(dateParts[2]),
              );
              if (_fromDate != null && pkDate.isBefore(_fromDate!)) return false;
              if (_toDate != null) {
                final toDateEnd = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
                if (pkDate.isAfter(toDateEnd)) return false;
              }
            } catch (_) {}
          }
        }
      }

      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final id = prescription.maToaThuoc.toString();
        final ghiChu = (prescription.ghiChu ?? '').toLowerCase();
        final drugNames = prescription.chiTietThuoc
            .map((t) => t.tenThuoc.toLowerCase())
            .join(' ');
        if (!id.contains(q) && !drugNames.contains(q) && !ghiChu.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawList = await _benhNhanService.getToaThuocByPatient();
      if (mounted) {
        setState(() {
          _prescriptions = rawList
              .map((e) => ToaThuocChiTiet.fromJson(e as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }



  String _formatDate(DateTime? date) {
    if (date == null) return '...';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _tealColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _selectToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _tealColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Tất cả toa thuốc',
          style: TextStyle(fontWeight: FontWeight.w600, color: _foregroundColor, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: _cardColor,
        foregroundColor: _foregroundColor,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: _foregroundColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: _isLoading ? _mutedForeground : _primaryColor),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoading();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFDC2626)),
              ),
              const SizedBox(height: 16),
              const Text('Không thể tải dữ liệu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _foregroundColor)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _mutedForeground, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Filter container
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search pill
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm (mã toa, tên thuốc...)',
                    hintStyle: const TextStyle(fontSize: 13, color: _mutedForeground),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _mutedForeground),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: _mutedForeground),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: _mutedColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Date buttons row
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(
                        label: 'Từ ngày',
                        date: _fromDate,
                        onTap: _selectFromDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateButton(
                        label: 'Đến ngày',
                        date: _toDate,
                        onTap: _selectToDate,
                      ),
                    ),
                    if (_fromDate != null || _toDate != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() {
                          _fromDate = null;
                          _toDate = null;
                        }),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _mutedColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded, size: 18, color: _mutedForeground),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _mutedColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_rounded, size: 14, color: _tealColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                date == null ? label : _formatDate(date),
                style: const TextStyle(fontSize: 12, color: _foregroundColor, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final filtered = _filteredList;

    if (filtered.isEmpty) {
      // Nếu có bộ lọc tìm kiếm/ngày và danh sách gốc không rỗng → kết quả lọc không khớp
      final isFilteredEmpty = _prescriptions.isNotEmpty && (_searchQuery.isNotEmpty || _fromDate != null || _toDate != null);
      return RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: _mutedColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFilteredEmpty ? Icons.inbox_rounded : Icons.medication_outlined,
                      size: 48,
                      color: _mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isFilteredEmpty
                        ? 'Không tìm thấy toa thuốc'
                        : 'Bệnh nhân chưa khám nên chưa có dữ liệu',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _foregroundColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFilteredEmpty
                        ? (_searchQuery.isNotEmpty ? 'Thử thay đổi từ khóa tìm kiếm' : 'Không có toa thuốc phù hợp')
                        : 'Các toa thuốc được kê khi khám bệnh sẽ hiển thị tại đây.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: _mutedForeground),
                  ),
                  if (!isFilteredEmpty) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Thử lại'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final prescription = filtered[index];
          return _buildPrescriptionCard(prescription);
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(ToaThuocChiTiet prescription) {
    final isExpanded = _expandedCards.contains(prescription.maToaThuoc);
    String formattedNgay = prescription.ngayKeToa ?? '';
    if (formattedNgay.length >= 10) {
      formattedNgay = formattedNgay.substring(0, 10);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedCards.remove(prescription.maToaThuoc);
            } else {
              _expandedCards.add(prescription.maToaThuoc);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _tealColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication_rounded, color: _tealColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toa thuốc #${prescription.maToaThuoc}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _foregroundColor),
                        ),
                        if (formattedNgay.isNotEmpty)
                          Text(
                            'Ngày kê: $formattedNgay',
                            style: const TextStyle(fontSize: 12, color: _mutedForeground),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tealColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${prescription.chiTietThuoc.length} loại',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _tealColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: _mutedForeground,
                    size: 22,
                  ),
                ],
              ),

              // Ghi chú
              if ((prescription.ghiChu ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _mutedColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(prescription.ghiChu!, style: const TextStyle(fontSize: 12, color: _mutedForeground, fontStyle: FontStyle.italic)),
                ),
              ],

              // Danh sách thuốc (expandable)
              if (isExpanded && prescription.chiTietThuoc.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(height: 1, color: _borderColor),
                const SizedBox(height: 8),
                ...prescription.chiTietThuoc.map((thuoc) => _buildDrugItem(thuoc)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrugItem(dynamic thuoc) {
    final hasShortInfo = (thuoc.hamLuong != null && thuoc.hamLuong!.isNotEmpty) ||
        (thuoc.dangBaoChe != null && thuoc.dangBaoChe!.isNotEmpty) ||
        (thuoc.donViTinh != null && thuoc.donViTinh!.isNotEmpty);

    final hasHighlight = (thuoc.lieuDung != null && thuoc.lieuDung!.isNotEmpty) ||
        (thuoc.cachDung != null && thuoc.cachDung!.isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _mutedColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên thuốc
          Row(
            children: [
              const Icon(Icons.medication_liquid_rounded, size: 18, color: _tealColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  thuoc.tenThuoc,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _tealColor),
                ),
              ),
            ],
          ),

          // Thông tin ngắn: Hàm lượng, Dạng bào chế, Đơn vị tính
          if (hasShortInfo) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (thuoc.hamLuong != null && thuoc.hamLuong!.isNotEmpty)
                  _buildLabelValue('Hàm lượng:', thuoc.hamLuong!),
                if (thuoc.dangBaoChe != null && thuoc.dangBaoChe!.isNotEmpty)
                  _buildLabelValue('Dạng bào chế:', thuoc.dangBaoChe!),
                if (thuoc.donViTinh != null && thuoc.donViTinh!.isNotEmpty)
                  _buildLabelValue('Đơn vị tính:', thuoc.donViTinh!),
              ],
            ),
          ],

          // Tần suất
          if (thuoc.tanSuat != null && thuoc.tanSuat!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildLabelValueRow('Tần suất:', thuoc.tanSuat!),
          ],

          // Liều dùng & Cách dùng (highlight)
          if (hasHighlight) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _highlightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thuoc.lieuDung != null && thuoc.lieuDung!.isNotEmpty)
                    _buildLabelValueRow('Liều dùng:', thuoc.lieuDung!, bold: true),
                  if (thuoc.lieuDung != null && thuoc.lieuDung!.isNotEmpty &&
                      thuoc.cachDung != null && thuoc.cachDung!.isNotEmpty)
                    const SizedBox(height: 4),
                  if (thuoc.cachDung != null && thuoc.cachDung!.isNotEmpty)
                    _buildLabelValueRow('Cách dùng:', thuoc.cachDung!, bold: true),
                ],
              ),
            ),
          ],

          // Ghi chú
          if (thuoc.ghiChu != null && thuoc.ghiChu!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildLabelValueRow('Ghi chú:', thuoc.ghiChu!),
          ],
        ],
      ),
    );
  }

  Widget _buildLabelValue(String label, String value) {
    final isLongValue = value.length > 20 || value.contains('\n');
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isLongValue) {
          return SizedBox(
            width: constraints.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: _mutedForeground),
                ),
                Text(
                  value,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _foregroundColor,
                  ),
                ),
              ],
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: _mutedForeground),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _foregroundColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabelValueRow(String label, String value, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: _mutedForeground, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: _foregroundColor,
            ),
          ),
        ),
      ],
    );
  }
}
