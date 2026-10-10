import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_filter.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

/// Màn hình bộ lọc. Trả về [TransactionFilter] mới qua Navigator.pop
/// khi bấm "Áp dụng" (null nếu người dùng thoát mà không áp dụng).
class FilterScreen extends StatefulWidget {
  final TransactionFilter initial;

  const FilterScreen({super.key, required this.initial});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  static const _blue = Color(0xFF2563EB);

  final _repo = TransactionRepository.instance;

  late TransactionTypeFilter _type;
  int? _categoryId;
  late DateRangeOption _range;
  DateTimeRange? _customRange;

  List<CategoryRecord> _categories = [];

  @override
  void initState() {
    super.initState();
    _type = widget.initial.type;
    _categoryId = widget.initial.categoryId;
    _range = widget.initial.range;
    _customRange = widget.initial.customRange;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final data = await _repo.getCategories();
    if (!mounted) return;
    setState(() => _categories = data);
  }

  List<CategoryRecord> get _visibleCategories {
    if (_type == TransactionTypeFilter.all) return _categories;
    final wanted = _type == TransactionTypeFilter.expense ? 'expense' : 'income';
    return _categories.where((c) => c.type == wanted).toList();
  }

  void _setType(TransactionTypeFilter type) {
    setState(() {
      _type = type;
      // Danh mục đang chọn không còn hợp lệ với loại mới => bỏ chọn
      if (_categoryId != null &&
          !_visibleCategories.any((c) => c.id == _categoryId)) {
        _categoryId = null;
      }
    });
  }

  Future<void> _selectRange(DateRangeOption option) async {
    if (option != DateRangeOption.custom) {
      setState(() => _range = option);
      return;
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _customRange,
    );
    if (picked != null) {
      setState(() {
        _range = DateRangeOption.custom;
        _customRange = picked;
      });
    }
  }

  void _reset() {
    setState(() {
      _type = TransactionTypeFilter.all;
      _categoryId = null;
      _range = DateRangeOption.all;
      _customRange = null;
    });
  }

  void _apply() {
    final hasCustom = _range == DateRangeOption.custom && _customRange != null;
    Navigator.pop(
      context,
      TransactionFilter(
        type: _type,
        categoryId: _categoryId,
        range: (_range == DateRangeOption.custom && !hasCustom)
            ? DateRangeOption.all
            : _range,
        customRange: _customRange,
      ),
    );
  }

  String _customRangeText() {
    final r = _customRange;
    if (r == null) return '';
    final f = DateFormat('dd/MM/yyyy');
    return '${f.format(r.start)} - ${f.format(r.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Bộ lọc',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: _reset, child: const Text('Đặt lại')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const _SectionTitle('Loại giao dịch'),
          _OptionRow(
            label: 'Tất cả',
            selected: _type == TransactionTypeFilter.all,
            checkbox: true,
            onTap: () => _setType(TransactionTypeFilter.all),
          ),
          _OptionRow(
            label: 'Thu nhập',
            selected: _type == TransactionTypeFilter.income,
            checkbox: true,
            onTap: () => _setType(TransactionTypeFilter.income),
          ),
          _OptionRow(
            label: 'Chi tiêu',
            selected: _type == TransactionTypeFilter.expense,
            checkbox: true,
            onTap: () => _setType(TransactionTypeFilter.expense),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Danh mục'),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                isExpanded: true,
                value: _categoryId,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tất cả danh mục'),
                  ),
                  ..._visibleCategories.map(
                        (c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: c.color,
                            child: Icon(c.icon, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(c.name),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionTitle('Khoảng thời gian'),
          _OptionRow(
            label: 'Tất cả thời gian',
            selected: _range == DateRangeOption.all,
            onTap: () => _selectRange(DateRangeOption.all),
          ),
          _OptionRow(
            label: 'Hôm nay',
            selected: _range == DateRangeOption.today,
            onTap: () => _selectRange(DateRangeOption.today),
          ),
          _OptionRow(
            label: '7 ngày qua',
            selected: _range == DateRangeOption.last7Days,
            onTap: () => _selectRange(DateRangeOption.last7Days),
          ),
          _OptionRow(
            label: 'Tháng này',
            selected: _range == DateRangeOption.thisMonth,
            onTap: () => _selectRange(DateRangeOption.thisMonth),
          ),
          _OptionRow(
            label: 'Tùy chỉnh',
            selected: _range == DateRangeOption.custom,
            trailing: _customRange == null ? null : _customRangeText(),
            onTap: () => _selectRange(DateRangeOption.custom),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Áp dụng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    ),
  );
}

/// Một dòng lựa chọn dạng checkbox hoặc radio (tự vẽ, chỉ chọn được một dòng).
class _OptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final bool checkbox;
  final String? trailing;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.checkbox = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final IconData icon = checkbox
        ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
        : (selected ? Icons.radio_button_checked : Icons.radio_button_off);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF2563EB) : Colors.grey.shade500,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 15)),
            if (trailing != null) ...[
              const Spacer(),
              Text(trailing!,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            ],
          ],
        ),
      ),
    );
  }
}
