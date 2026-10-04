import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'transaction_model.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTab = 0;
  bool _isBalanceVisible = true;
  int _bannerPage = 0;
  bool _isLoading = true;

  List<TransactionRecord> _transactions = [];
  int _totalIncome = 0;
  int _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final rows = await DatabaseHelper.instance.getAllTransactions();
    final income = await DatabaseHelper.instance.getTotalIncome();
    final expense = await DatabaseHelper.instance.getTotalExpense();

    setState(() {
      _transactions = rows.map((e) => TransactionRecord.fromMap(e)).toList();
      _totalIncome = income;
      _totalExpense = expense;
      _isLoading = false;
    });
  }

  String _formatMoney(int value) {
    final isNegative = value < 0;
    final abs = value.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < abs.length; i++) {
      if (i != 0 && (abs.length - i) % 3 == 0) buffer.write('.');
      buffer.write(abs[i]);
    }
    return '${isNegative ? '-' : '+'}${buffer.toString()} đ';
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openEditTransaction(TransactionRecord transaction) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(existingTransaction: transaction),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.menu, size: 26),
                  const Text(
                    'Quản lý thu chi',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none, size: 26),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_transactions.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 190,
                        child: PageView(
                          onPageChanged: (i) =>
                              setState(() => _bannerPage = i),
                          children: [
                            _buildBalanceBanner(),
                            _buildBalanceBanner(),
                            _buildBalanceBanner(),
                            _buildBalanceBanner(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            final active = i == _bannerPage;
                            return Container(
                              margin:
                              const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              bgColor: const Color(0xFFE3F5E9),
                              icon: Icons.arrow_downward,
                              iconColor: const Color(0xFF2E7D32),
                              label: 'TỔNG THU NHẬP',
                              value: _formatMoney(_totalIncome),
                              valueColor: const Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _SummaryCard(
                              bgColor: const Color(0xFFFBE4E4),
                              icon: Icons.arrow_upward,
                              iconColor: const Color(0xFFC62828),
                              label: 'TỔNG CHI TIÊU',
                              value: _formatMoney(-_totalExpense),
                              valueColor: const Color(0xFFC62828),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Giao dịch gần đây',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Xem tất cả'),
                          ),
                        ],
                      ),

                      if (_transactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              'Chưa có giao dịch nào.\nBấm nút + để thêm mới.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              for (int i = 0;
                              i < _transactions.length;
                              i++)
                                GestureDetector(
                                  onTap: () => _openEditTransaction(
                                      _transactions[i]),
                                  child: _TransactionRow(
                                    transaction: _transactions[i],
                                    showDivider:
                                    i != _transactions.length - 1,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: _openAddTransaction,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined), label: 'Giao dịch'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline), label: 'Thống kê'),
        ],
      ),
    );
  }

  Widget _buildBalanceBanner() {
    final balance = _totalIncome - _totalExpense;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B7EF5), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 10,
            child: Icon(
              Icons.account_balance_wallet,
              size: 90,
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'SỐ DƯ HIỆN TẠI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isBalanceVisible = !_isBalanceVisible),
                    child: Icon(
                      _isBalanceVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _isBalanceVisible
                    ? _formatMoney(balance).replaceFirst('+', '')
                    : '••••••••',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Color bgColor;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryCard({
    required this.bgColor,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white,
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionRecord transaction;
  final bool showDivider;

  const _TransactionRow({
    required this.transaction,
    required this.showDivider,
  });

  String _formatMoney(int value) {
    final isNegative = value < 0;
    final abs = value.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < abs.length; i++) {
      if (i != 0 && (abs.length - i) % 3 == 0) buffer.write('.');
      buffer.write(abs[i]);
    }
    return '${isNegative ? '-' : '+'}${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = transaction.note?.isNotEmpty == true
        ? transaction.note!
        : transaction.categoryName;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: transaction.color,
                child: Icon(transaction.icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          transaction.categoryName,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12.5),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          transaction.date,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatMoney(transaction.signedAmount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  color: transaction.isIncome
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
              height: 1, indent: 14, endIndent: 14, color: Colors.grey.shade200),
      ],
    );
  }
}