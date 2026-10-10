import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/transaction_filter.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

enum _Period { thisMonth, lastMonth, thisYear }

class _Slice {
  final String name;
  final Color color;
  final int amount;

  const _Slice(this.name, this.color, this.amount);
}

/// Thống kê chi tiêu theo danh mục (biểu đồ vòng) cho tháng này / tháng trước / năm nay.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _repo = TransactionRepository.instance;

  bool _isLoading = true;
  List<TransactionRecord> _all = [];
  _Period _period = _Period.thisMonth;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _all = data;
      _isLoading = false;
    });
  }

  DateTimeRange get _range {
    final now = DateTime.now();
    switch (_period) {
      case _Period.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case _Period.lastMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0),
        );
      case _Period.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
    }
  }

  List<_Slice> get _slices {
    final range = _range;
    final byCategory = <int, _Slice>{};

    for (final t in _all) {
      if (t.isIncome) continue; // chỉ thống kê chi tiêu
      final d = TransactionFilter.parseDate(t.date);
      if (d.isBefore(range.start) || d.isAfter(range.end)) continue;

      final old = byCategory[t.categoryId];
      byCategory[t.categoryId] = _Slice(
        t.categoryName,
        t.color,
        (old?.amount ?? 0) + t.amount,
      );
    }

    final list = byCategory.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  String _money(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && (s.length - i) % 3 == 0) buffer.write('.');
      buffer.write(s[i]);
    }
    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    final slices = _slices;
    final total = slices.fold<int>(0, (s, e) => s + e.amount);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Thống kê',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Row(
              children: [
                _periodChip('Tháng này', _Period.thisMonth),
                const SizedBox(width: 8),
                _periodChip('Tháng trước', _Period.lastMonth),
                const SizedBox(width: 8),
                _periodChip('Năm nay', _Period.thisYear),
              ],
            ),
            const SizedBox(height: 28),
            if (slices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text(
                    'Chưa có chi tiêu trong khoảng thời gian này.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              )
            else ...[
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(220, 220),
                        painter: _DonutPainter(slices, total),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _money(total),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tổng chi tiêu',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              for (final s in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s.name,
                            style: const TextStyle(fontSize: 15)),
                      ),
                      Text(
                        _money(s.amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                      SizedBox(
                        width: 52,
                        child: Text(
                          '${(s.amount * 100 / total).round()}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String label, _Period value) {
    final selected = _period == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _period = value),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F3F8),
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_Slice> slices;
  final int total;

  _DonutPainter(this.slices, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    const stroke = 36.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    var start = -math.pi / 2;
    for (final s in slices) {
      final sweep = s.amount / total * 2 * math.pi;
      paint.color = s.color;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices != slices || old.total != total;
}
