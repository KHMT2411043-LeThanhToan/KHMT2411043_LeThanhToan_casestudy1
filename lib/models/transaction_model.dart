import 'package:flutter/material.dart';

/// Model đại diện cho 1 giao dịch, đã JOIN sẵn thông tin danh mục
/// (ánh xạ trực tiếp từ kết quả DatabaseHelper.getAllTransactions()).
class TransactionRecord {
  final int id;
  final int categoryId;
  final String categoryName;
  final String categoryType; // 'expense' hoặc 'income'
  final int iconCode;
  final int colorValue;
  final int amount; // luôn lưu dạng số dương, dấu +/- suy ra từ categoryType
  final String date; // định dạng dd/MM/yyyy
  final String? note;

  TransactionRecord({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.iconCode,
    required this.colorValue,
    required this.amount,
    required this.date,
    this.note,
  });

  bool get isIncome => categoryType == 'income';

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Color get color => Color(colorValue);

  /// Giá trị có dấu, dùng khi tính tổng (thu dương, chi âm)
  int get signedAmount => isIncome ? amount : -amount;

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String,
      categoryType: map['category_type'] as String,
      iconCode: map['icon_code'] as int,
      colorValue: map['color_value'] as int,
      amount: map['amount'] as int,
      date: map['date'] as String,
      note: map['note'] as String?,
    );
  }
}

/// Model cho 1 danh mục, dùng trong dropdown chọn danh mục
class CategoryRecord {
  final int id;
  final String name;
  final String type;
  final int iconCode;
  final int colorValue;

  CategoryRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.iconCode,
    required this.colorValue,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Color get color => Color(colorValue);

  factory CategoryRecord.fromMap(Map<String, dynamic> map) {
    return CategoryRecord(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      iconCode: map['icon_code'] as int,
      colorValue: map['color_value'] as int,
    );
  }
}