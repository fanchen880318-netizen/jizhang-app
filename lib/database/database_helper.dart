import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bill.dart';
import '../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'jizhang.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT DEFAULT '',
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        sort INTEGER DEFAULT 0
      )
    ''');

    // 预设三个用途
    await db.insert('categories', {'name': '网采', 'sort': 0});
    await db.insert('categories', {'name': '还款', 'sort': 1});
    await db.insert('categories', {'name': '地采', 'sort': 2});
  }

  // ============ 账单 CRUD ============

  Future<int> insertBill(Bill bill) async {
    final db = await database;
    return await db.insert('bills', bill.toMap());
  }

  Future<int> updateBill(Bill bill) async {
    final db = await database;
    return await db.update(
      'bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  Future<int> deleteBill(int id) async {
    final db = await database;
    return await db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Bill>> getBills({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(_dateToString(startDate));
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(_dateToString(endDate));
    }
    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final maps = await db.query(
      'bills',
      where: where,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC, created_at DESC',
    );

    return maps.map((map) => Bill.fromMap(map)).toList();
  }

  Future<double> getTotalAmount({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(_dateToString(startDate));
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(_dateToString(endDate));
    }
    if (category != null && category.isNotEmpty) {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    final where = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM bills${where != null ? ' WHERE $where' : ''}',
      whereArgs.isNotEmpty ? whereArgs : null,
    );

    return (result.first['total'] as num).toDouble();
  }

  // ============ 用途 CRUD ============

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query(
      'categories',
      orderBy: 'sort ASC, id ASC',
    );
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCategorySort(int id, int sort) async {
    final db = await database;
    return await db.update(
      'categories',
      {'sort': sort},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static String _dateToString(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
