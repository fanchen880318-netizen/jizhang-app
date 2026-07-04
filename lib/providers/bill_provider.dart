import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../models/category.dart';
import '../database/database_helper.dart';

class BillProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Bill> _bills = [];
  List<Category> _categories = [];
  DateTimeRange? _dateRange;
  String? _filterCategory;

  bool _isLoading = false;

  List<Bill> get bills => _bills;
  List<Category> get categories => _categories;
  DateTimeRange? get dateRange => _dateRange;
  String? get filterCategory => _filterCategory;
  bool get isLoading => _isLoading;

  /// 按天分组的账单
  Map<String, List<Bill>> get groupedBills {
    final map = <String, List<Bill>>{};
    for (final bill in _bills) {
      final key = '${bill.date.year}-${bill.date.month.toString().padLeft(2, '0')}-${bill.date.day.toString().padLeft(2, '0')}';
      map.putIfAbsent(key, () => []).add(bill);
    }
    return map;
  }

  /// 总金额
  double get totalAmount {
    return _bills.fold(0, (sum, bill) => sum + bill.amount);
  }

  /// 加载所有数据
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _db.getCategories();
    _bills = await _db.getBills(
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      category: _filterCategory,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// 设置日期范围并重新加载
  Future<void> setDateRange(DateTimeRange? range) async {
    _dateRange = range;
    await loadData();
  }

  /// 设置用途筛选并重新加载
  Future<void> setFilterCategory(String? category) async {
    _filterCategory = category;
    await loadData();
  }

  /// 清除筛选
  Future<void> clearFilters() async {
    _dateRange = null;
    _filterCategory = null;
    await loadData();
  }

  // ============ 账单操作 ============

  Future<void> addBill(Bill bill) async {
    await _db.insertBill(bill);
    await loadData();
  }

  Future<void> updateBill(Bill bill) async {
    await _db.updateBill(bill);
    await loadData();
  }

  Future<void> deleteBill(int id) async {
    await _db.deleteBill(id);
    await loadData();
  }

  // ============ 用途操作 ============

  Future<bool> addCategory(String name) async {
    // 检查是否重复
    if (_categories.any((c) => c.name == name)) {
      return false;
    }
    final cat = Category(name: name, sort: _categories.length);
    await _db.insertCategory(cat);
    await loadData();
    return true;
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await loadData();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) newIndex--;
    final item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);
    for (int i = 0; i < _categories.length; i++) {
      await _db.updateCategorySort(_categories[i].id!, i);
    }
    await loadData();
  }

  // ============ 导出数据 ============

  Future<List<Bill>> getExportBills() async {
    return await _db.getBills(
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
  }

  Future<double> getExportTotal() async {
    return await _db.getTotalAmount(
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
    );
  }
}
