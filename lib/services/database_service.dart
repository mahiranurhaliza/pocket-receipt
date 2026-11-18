import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/receipt_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pocket_receipt.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS receipt_items');
          await db.execute('DROP TABLE IF EXISTS receipts');
          await _createDB(db, newVersion);
        } else if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE receipts ADD COLUMN note TEXT DEFAULT ''",
          );
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        store_name TEXT NOT NULL,
        date TEXT NOT NULL,
        total_amount REAL NOT NULL,
        category TEXT NOT NULL,
        source_of_funds TEXT DEFAULT 'Cash',
        image_path TEXT,
        note TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE receipt_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (receipt_id) REFERENCES receipts (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertReceipt(ReceiptModel receipt) async {
    final db = await instance.database;
    final receiptId = await db.insert('receipts', receipt.toMap());

    for (final item in receipt.items) {
      await db.insert('receipt_items', {
        'receipt_id': receiptId,
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price,
      });
    }
    return receiptId;
  }

  Future<List<ReceiptModel>> getAllReceipts() async {
    final db = await instance.database;
    final result = await db.query('receipts', orderBy: 'date DESC');

    final List<ReceiptModel> receipts = [];
    for (final row in result) {
      final id = row['id'] as int;
      final itemRows = await db.query(
        'receipt_items',
        where: 'receipt_id = ?',
        whereArgs: [id],
      );
      final items = itemRows.map((i) => ReceiptItem.fromMap(i)).toList();
      receipts.add(ReceiptModel.fromMap(row, items: items));
    }
    return receipts;
  }

  Future<int> updateReceipt({
    required int id,
    required String storeName,
    required double totalAmount,
    required String category,
    required String sourceOfFunds,
    required String note,
    required List<ReceiptItem> items,
  }) async {
    final db = await instance.database;
    final updated = await db.update(
      'receipts',
      {
        'store_name': storeName,
        'total_amount': totalAmount,
        'category': category,
        'source_of_funds': sourceOfFunds,
        'note': note,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await db.delete('receipt_items', where: 'receipt_id = ?', whereArgs: [id]);
    for (final item in items) {
      await db.insert('receipt_items', {
        'receipt_id': id,
        'name': item.name,
        'quantity': item.quantity,
        'price': item.price,
      });
    }
    return updated;
  }

  Future<int> deleteReceipt(int id) async {
    final db = await instance.database;
    await db.delete('receipt_items', where: 'receipt_id = ?', whereArgs: [id]);
    return await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getTotalByCategory() async {
    final receipts = await getAllReceipts();
    final Map<String, double> totals = {};
    for (var receipt in receipts) {
      totals[receipt.category] =
          (totals[receipt.category] ?? 0) + receipt.totalAmount;
    }
    return totals;
  }
}