import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'receipt_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  static const String _dbName = 'pocket_receipt.db';
  static const int _dbVersion = 5;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_name TEXT NOT NULL,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'Makanan',
        source_of_funds TEXT NOT NULL DEFAULT 'Cash',
        image_path TEXT,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE receipt_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        price REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (receipt_id) REFERENCES receipts (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS receipt_items');
      await db.execute('DROP TABLE IF EXISTS receipts');
      await _createDB(db, newVersion);
      return;
    }

    if (oldVersion < 4) {
      await db.execute(
        "ALTER TABLE receipts ADD COLUMN note TEXT NOT NULL DEFAULT ''",
      );
    }

    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE receipts ALTER COLUMN category SET DEFAULT 'Makanan'",
      ).catchError((_) async {});
    }
  }

  Future<int> insertReceipt(ReceiptModel receipt) async {
    final db = await database;

    return db.transaction((txn) async {
      final receiptId = await txn.insert('receipts', receipt.toMap());
      for (final item in receipt.items) {
        await txn.insert('receipt_items', item.toMap(receiptId: receiptId));
      }
      return receiptId;
    });
  }

  Future<List<ReceiptModel>> getAllReceipts() async {
    final db = await database;
    final rows = await db.query('receipts', orderBy: 'date DESC, id DESC');

    final List<ReceiptModel> receipts = [];
    for (final row in rows) {
      final id = row['id'] as int;
      final itemRows = await db.query(
        'receipt_items',
        where: 'receipt_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      );
      final items = itemRows.map(ReceiptItem.fromMap).toList();
      receipts.add(ReceiptModel.fromMap(row, items: items));
    }
    return receipts;
  }

  Future<List<ReceiptModel>> getReceiptsByMonth({
    required int year,
    required int month,
  }) async {
    final all = await getAllReceipts();
    return all
        .where((r) => r.date.year == year && r.date.month == month)
        .toList();
  }

  Future<int> updateReceipt({
    int? id,
    String? storeName,
    double? totalAmount,
    String? category,
    String? sourceOfFunds,
    String? note,
    String? imagePath,
    List<ReceiptItem>? items,
    ReceiptModel? model,
  }) async {
    final targetId = model?.id ?? id;
    if (targetId == null) return 0;

    final db = await database;
    final resolvedStore = model?.storeName ?? storeName;
    final resolvedTotal = model?.totalAmount ?? totalAmount;
    final resolvedCategory = model?.category ?? category;
    final resolvedSource = model?.sourceOfFunds ?? sourceOfFunds;
    final resolvedNote = model?.note ?? note;
    final resolvedImage = model?.imagePath ?? imagePath;
    final resolvedItems = model?.items ?? items;

    return db.transaction((txn) async {
      final values = <String, Object?>{
        'store_name': ?resolvedStore,
        'total_amount': ?resolvedTotal,
        'category': ?resolvedCategory,
        'source_of_funds': ?resolvedSource,
        'note': ?resolvedNote,
        'image_path': ?resolvedImage,
      };

      int updated = 0;
      if (values.isNotEmpty) {
        updated = await txn.update(
          'receipts',
          values,
          where: 'id = ?',
          whereArgs: [targetId],
        );
      }

      if (resolvedItems != null) {
        await txn.delete(
          'receipt_items',
          where: 'receipt_id = ?',
          whereArgs: [targetId],
        );

        for (final item in resolvedItems) {
          await txn.insert('receipt_items', item.toMap(receiptId: targetId));
        }
      }

      return updated;
    });
  }

  Future<int> deleteReceipt(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      await txn.delete(
        'receipt_items',
        where: 'receipt_id = ?',
        whereArgs: [id],
      );
      return txn.delete(
        'receipts',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<Map<String, double>> getTotalByCategory() async {
    final receipts = await getAllReceipts();
    final Map<String, double> totals = {};
    for (final receipt in receipts) {
      totals[receipt.category] =
          (totals[receipt.category] ?? 0.0) + receipt.totalAmount;
    }
    return totals;
  }
}