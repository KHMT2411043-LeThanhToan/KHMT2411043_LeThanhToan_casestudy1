import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class CategoryOption {
  final String name;
  final IconData icon;
  final Color color;
  const CategoryOption(this.name, this.icon, this.color);
}

const List<CategoryOption> expenseCategories = [
  CategoryOption('Ăn uống', Icons.restaurant, Color(0xFFE91E63)),
  CategoryOption('Mua sắm', Icons.shopping_cart, Color(0xFF2196F3)),
  CategoryOption('Di chuyển', Icons.directions_car, Color(0xFFFF9800)),
  CategoryOption('Hóa đơn', Icons.receipt_long, Color(0xFF9C27B0)),
  CategoryOption('Khác', Icons.category, Color(0xFF607D8B)),
];

const List<CategoryOption> incomeCategories = [
  CategoryOption('Lương', Icons.account_balance_wallet, Color(0xFF4CAF50)),
  CategoryOption('Thưởng', Icons.card_giftcard, Color(0xFF00BCD4)),
  CategoryOption('Khác', Icons.category, Color(0xFF607D8B)),
];

/// Kết quả trả về khi bấm Lưu (thêm mới/cập nhật) hoặc Xóa (chỉ ở chế độ sửa)
class TransactionFormResult {
  final Transaction? transaction; // null nếu người dùng chọn Xóa
  final bool isDelete;
  TransactionFormResult({this.transaction, this.isDelete = false});
}

class AddTransactionScreen extends StatefulWidget {
  /// Nếu [existingTransaction] được truyền vào => màn hình chạy ở chế độ SỬA.
  /// Nếu để null => chạy ở chế độ THÊM MỚI.
  final Transaction? existingTransaction;

  const AddTransactionScreen({super.key, this.existingTransaction});

  bool get isEditMode => existingTransaction != null;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late bool _isExpense;
  CategoryOption? _selectedCategory;
  late DateTime _selectedDate;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final existing = widget.existingTransaction;

    if (existing != null) {
      // Chế độ SỬA: điền sẵn dữ liệu cũ
      _isExpense = existing.amount < 0;
      _selectedDate = _parseDate(existing.date);
      _amountController.text = _formatNumber(existing.amount.abs());
      _noteController.text = existing.note ?? '';

      final list = _isExpense ? expenseCategories : incomeCategories;
      _selectedCategory = list.firstWhere(
            (c) => c.name == existing.title,
        orElse: () => list.first,
      );
    } else {
      // Chế độ THÊM MỚI
      _isExpense = true;
      _selectedDate = DateTime.now();
      _selectedCategory = expenseCategories.first;
    }
  }

  DateTime _parseDate(String ddMMyyyy) {
    final parts = ddMMyyyy.split('/');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  String _formatNumber(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i != 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<CategoryOption> get _currentCategories =>
      _isExpense ? expenseCategories : incomeCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _save() {
    final rawAmount = _amountController.text.replaceAll('.', '').trim();
    final amount = int.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    final transaction = Transaction(
      title: _selectedCategory!.name,
      date: DateFormat('dd/MM/yyyy').format(_selectedDate),
      amount: _isExpense ? -amount : amount,
      icon: _selectedCategory!.icon,
      iconBg: _selectedCategory!.color,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    Navigator.pop(context, TransactionFormResult(transaction: transaction));
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giao dịch'),
        content: const Text('Bạn có chắc muốn xóa giao dịch này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // đóng dialog
              Navigator.pop(
                context,
                TransactionFormResult(isDelete: true),
              ); // đóng màn hình sửa, trả kết quả xóa
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEditMode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          isEdit ? 'Sửa giao dịch' : 'Thêm giao dịch',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ToggleButton(
                    label: 'Chi tiêu',
                    selected: _isExpense,
                    color: const Color(0xFFE11D48),
                    onTap: () => setState(() {
                      _isExpense = true;
                      _selectedCategory = expenseCategories.first;
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ToggleButton(
                    label: 'Thu nhập',
                    selected: !_isExpense,
                    color: const Color(0xFF16A34A),
                    onTap: () => setState(() {
                      _isExpense = false;
                      _selectedCategory = incomeCategories.first;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('Danh mục',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CategoryOption>(
                  isExpanded: true,
                  value: _selectedCategory,
                  items: _currentCategories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: cat.color,
                            child:
                            Icon(cat.icon, size: 16, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(cat.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Số tiền',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Nhập số tiền',
                suffixText: 'đ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Ngày giao dịch',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Ghi chú',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Nhập ghi chú (tùy chọn)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Lưu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}