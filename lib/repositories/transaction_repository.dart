import '../database/database_helper.dart';
import '../models/transaction_model.dart';

/// Lớp trung gian giữa UI và DatabaseHelper.
/// Màn hình chỉ làm việc với model (TransactionRecord, CategoryRecord),
/// không đụng trực tiếp tới Map hay SQL.
class TransactionRepository {
  TransactionRepository._internal();
  static final TransactionRepository instance = TransactionRepository._internal();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ---------- CATEGORIES ----------
  Future<List<CategoryRecord>> getCategories({String? type}) async {
    final rows = await _db.getCategories(type: type);
    return rows.map((e) => CategoryRecord.fromMap(e)).toList();
  }

  // ---------- TRANSACTIONS ----------
  Future<List<TransactionRecord>> getAll() async {
    final rows = await _db.getAllTransactions();
    return rows.map((e) => TransactionRecord.fromMap(e)).toList();
  }

  Future<int> add({
    required int categoryId,
    required int amount,
    required String date, // dd/MM/yyyy
    String? note,
  }) {
    return _db.insertTransaction({
      'category_id': categoryId,
      'amount': amount,
      'date': date,
      'note': note,
    });
  }

  Future<int> update(
      int id, {
        required int categoryId,
        required int amount,
        required String date,
        String? note,
      }) {
    return _db.updateTransaction(id, {
      'category_id': categoryId,
      'amount': amount,
      'date': date,
      'note': note,
    });
  }

  Future<int> delete(int id) => _db.deleteTransaction(id);

  // ---------- TỔNG HỢP ----------
  Future<int> totalIncome() => _db.getTotalIncome();
  Future<int> totalExpense() => _db.getTotalExpense();
}