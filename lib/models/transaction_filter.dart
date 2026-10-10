import 'package:flutter/material.dart';
import 'transaction_model.dart';

enum TransactionTypeFilter { all, income, expense }

enum DateRangeOption { all, today, last7Days, thisMonth, custom }

/// Điều kiện lọc giao dịch, dùng chung cho màn hình danh sách và màn hình bộ lọc.
class TransactionFilter {
  final TransactionTypeFilter type;
  final int? categoryId; // null = tất cả danh mục
  final DateRangeOption range;
  final DateTimeRange? customRange;

  const TransactionFilter({
    this.type = TransactionTypeFilter.all,
    this.categoryId,
    this.range = DateRangeOption.all,
    this.customRange,
  });

  TransactionFilter copyWith({
    TransactionTypeFilter? type,
    int? categoryId,
    bool clearCategory = false,
    DateRangeOption? range,
    DateTimeRange? customRange,
  }) {
    return TransactionFilter(
      type: type ?? this.type,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      range: range ?? this.range,
      customRange: customRange ?? this.customRange,
    );
  }

  /// Có đang lọc theo danh mục hoặc thời gian không (dùng để hiện chấm trên nút lọc).
  bool get hasExtraFilter => categoryId != null || resolvedRange != null;

  /// Khoảng ngày (gồm cả ngày đầu và ngày cuối) hoặc null nếu không giới hạn.
  DateTimeRange? get resolvedRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (range) {
      case DateRangeOption.all:
        return null;
      case DateRangeOption.today:
        return DateTimeRange(start: today, end: today);
      case DateRangeOption.last7Days:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );
      case DateRangeOption.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case DateRangeOption.custom:
        final c = customRange;
        if (c == null) return null;
        return DateTimeRange(
          start: DateTime(c.start.year, c.start.month, c.start.day),
          end: DateTime(c.end.year, c.end.month, c.end.day),
        );
    }
  }

  /// Chuyển chuỗi dd/MM/yyyy thành DateTime (0h00).
  static DateTime parseDate(String ddMMyyyy) {
    final p = ddMMyyyy.split('/');
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  bool matches(TransactionRecord t) {
    if (type == TransactionTypeFilter.income && !t.isIncome) return false;
    if (type == TransactionTypeFilter.expense && t.isIncome) return false;
    if (categoryId != null && t.categoryId != categoryId) return false;

    final r = resolvedRange;
    if (r != null) {
      final d = parseDate(t.date);
      if (d.isBefore(r.start) || d.isAfter(r.end)) return false;
    }
    return true;
  }
}
