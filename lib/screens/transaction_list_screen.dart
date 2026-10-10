import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import 'add_transaction_screen.dart';
import 'edit_transaction_screen.dart';

enum _TypeFilter { all, expense, income }

/// Danh sách toàn bộ giao dịch: lọc Tất cả / Chi tiêu / Thu nhập,
/// tìm theo ghi chú hoặc danh mục, chạm vào một dòng để sửa.
class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final _repo = TransactionRepository.instance;
  final _searchController = TextEditingController();

  bool _isLoading = true;
  List<TransactionRecord> _all = [];
  _TypeFilter _filter = _TypeFilter.all;
  String _query = '';

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
    final data = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _all = data;
      _isLoading = false;
    });
  }

  List<TransactionRecord> get _filtered {
    final q = _query.trim().toLowerCase();
    return _all.where((t) {
      if (_filter == _TypeFilter.expense && t.isIncome) return false;
      if (_filter == _TypeFilter.income && !t.isIncome) return false;
      if (q.isEmpty) return true;
      return t.categoryName.toLowerCase().contains(q) ||
          (t.note ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String _formatMoney(int value) {
    final abs = value.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < abs.length; i++) {
      if (i != 0 && (abs.length - i) % 3 == 0) buffer.write('.');
      buffer.write(abs[i]);
    }
    return '${value < 0 ? '-' : '+'}${buffer.toString()} đ';
  }

  Future<void> _openAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (result == true) _loadData();
  }

  Future<void> _openEdit(TransactionRecord t) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditTransactionScreen(transaction: t)),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final sum = items.fold<int>(0, (s, t) => s + t.signedAmount);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Giao dịch',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Tìm theo danh mục hoặc ghi chú',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _chip('Tất cả', _TypeFilter.all),
                const SizedBox(width: 8),
                _chip('Chi tiêu', _TypeFilter.expense),
                const SizedBox(width: 8),
                _chip('Thu nhập', _TypeFilter.income),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${items.length} giao dịch',
                    style: TextStyle(color: Colors.grey.shade600)),
                Text(
                  _formatMoney(sum),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: sum < 0
                        ? const Color(0xFFC62828)
                        : const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: items.isEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      _all.isEmpty
                          ? 'Chưa có giao dịch nào.\nBấm nút + để thêm mới.'
                          : 'Không tìm thấy giao dịch phù hợp.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                ],
              )
                  : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (_, i) => _TransactionTile(
                  transaction: items[i],
                  amountText: _formatMoney(items[i].signedAmount),
                  onTap: () => _openEdit(items[i]),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: _openAdd,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _chip(String label, _TypeFilter value) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      showCheckmark: false,
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionRecord transaction;
  final String amountText;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.amountText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final hasNote = (t.note ?? '').isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: t.color,
                child: Icon(t.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.categoryName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      hasNote ? '${t.date} • ${t.note}' : t.date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                      TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amountText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: t.isIncome
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
