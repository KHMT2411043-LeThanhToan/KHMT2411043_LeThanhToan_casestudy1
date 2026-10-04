import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Lớp quản lý toàn bộ thao tác với SQLite (Singleton Pattern:
/// chỉ có duy nhất 1 kết nối database trong suốt vòng đời app).
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expense_manager.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Bảng danh mục
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL
      )
    ''');

    // Bảng giao dịch, có khóa ngoại category_id tham chiếu categories.id
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
          ON DELETE CASCADE
      )
    ''');

    // Dữ liệu danh mục mặc định
    final defaultCategories = [
      {'name': 'Ăn uống', 'type': 'expense', 'icon_code': 0xe56c, 'color_value': 0xFFE91E63},
      {'name': 'Mua sắm', 'type': 'expense', 'icon_code': 0xe59c, 'color_value': 0xFF2196F3},
      {'name': 'Di chuyển', 'type': 'expense', 'icon_code': 0xe531, 'color_value': 0xFFFF9800},
      {'name': 'Hóa đơn', 'type': 'expense', 'icon_code': 0xe8b0, 'color_value': 0xFF9C27B0},
      {'name': 'Khác (Chi)', 'type': 'expense', 'icon_code': 0xe574, 'color_value': 0xFF607D8B},
      {'name': 'Lương', 'type': 'income', 'icon_code': 0xe850, 'color_value': 0xFF4CAF50},
      {'name': 'Thưởng', 'type': 'income', 'icon_code': 0xe8f6, 'color_value': 0xFF00BCD4},
      {'name': 'Khác (Thu)', 'type': 'income', 'icon_code': 0xe574, 'color_value': 0xFF607D8B},
    ];

    for (final cat in defaultCategories) {
      await db.insert('categories', cat);
    }
  }

  // ---------- CATEGORIES ----------

  Future<List<Map<String, dynamic>>> getCategories({String? type}) async {
    final db = await database;
    if (type != null) {
      return await db.query('categories', where: 'type = ?', whereArgs: [type]);
    }
    return await db.query('categories');
  }

  // ---------- TRANSACTIONS ----------

  /// Thêm giao dịch mới, trả về id vừa tạo
  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction);
  }

  /// Lấy tất cả giao dịch kèm thông tin danh mục (JOIN 2 bảng),
  /// sắp xếp theo ngày mới nhất lên đầu
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        t.id, 
        t.amount, 
        t.date, 
        t.note,
        c.id as category_id,
        c.name as category_name,
        c.type as category_type,
        c.icon_code,
        c.color_value
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      ORDER BY t.id DESC
    ''');
  }

  /// Cập nhật 1 giao dịch theo id
  Future<int> updateTransaction(int id, Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Xóa 1 giao dịch theo id
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Tính tổng thu nhập
  Future<int> getTotalIncome() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(t.amount) as total
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE c.type = 'income'
    ''');
    return (result.first['total'] as int?) ?? 0;
  }

  /// Tính tổng chi tiêu
  Future<int> getTotalExpense() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(t.amount) as total
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE c.type = 'expense'
    ''');
    return (result.first['total'] as int?) ?? 0;
  }
}