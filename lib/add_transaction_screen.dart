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

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isExpense = true;
  CategoryOption? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = expenseCategories.first;
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
    );

    Navigator.pop(context, transaction);
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
          'Thêm giao dịch',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // Toggle Chi tiêu / Thu nhập
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
                            child: Icon(cat.icon, size: 16, color: Colors.white),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
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