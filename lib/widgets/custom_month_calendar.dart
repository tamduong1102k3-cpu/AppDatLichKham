import 'package:flutter/material.dart';

import '../data/entities/lich_thang_entity.dart';
import '../services/server_time_service.dart';

class CustomMonthCalendar extends StatelessWidget {
  final DateTime visibleMonth;
  final List<NgayCaLamEntity> days;
  final String? selectedDate;
  final ValueChanged<String>? onDateSelected;
  final bool isLoading;
  final String emptyText;

  const CustomMonthCalendar({
    super.key,
    required this.visibleMonth,
    required this.days,
    this.selectedDate,
    this.onDateSelected,
    this.isLoading = false,
    this.emptyText = 'Không có lịch trong khoảng thời gian này.',
  });

  String _formatDateYmd(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0F766E);
    const cardColor = Colors.white;
    const foregroundColor = Color(0xFF1E293B);
    const mutedForeground = Color(0xFF64748B);
    const borderColor = Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            alignment: Alignment.center,
            child: Text(
              'Tháng ${visibleMonth.month}/${visibleMonth.year}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : days.isEmpty
                    ? Text(
                        emptyText,
                        style: TextStyle(fontSize: 13, color: mutedForeground),
                      )
                    : Column(
                        children: [
                          Row(
                            children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                                .map(
                                  (w) => Expanded(
                                    child: Center(
                                      child: Text(
                                        w,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: mutedForeground,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: days.length,
                            itemBuilder: (context, index) {
                              final day = days[index];
                              final date = day.date ?? ServerTimeService.now();
                              final now = ServerTimeService.now();
                              final todayOnly =
                                  DateTime(now.year, now.month, now.day);
                              final isPast = DateTime(
                                      date.year, date.month, date.day)
                                  .isBefore(todayOnly);
                              final hasShifts = day.resolved.isNotEmpty;
                              final dateKey = day.date != null
                                  ? _formatDateYmd(day.date!)
                                  : day.ngay;
                              final isSelected = selectedDate == dateKey;
                              final clickable = hasShifts && !isPast;

                              Color bg;
                              Color textColor;
                              Color cellBorderColor;
                              if (isSelected) {
                                bg = primaryColor;
                                textColor = Colors.white;
                                cellBorderColor = primaryColor;
                              } else if (hasShifts && !isPast) {
                                bg = cardColor;
                                textColor = foregroundColor;
                                cellBorderColor = borderColor;
                              } else {
                                bg = Colors.transparent;
                                textColor =
                                    mutedForeground.withValues(alpha: 0.45);
                                cellBorderColor = Colors.transparent;
                              }

                              return InkWell(
                                onTap: clickable
                                    ? () => onDateSelected?.call(dateKey)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: cellBorderColor, width: 1),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}