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
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS receipt_items');
          await db.execute('DROP TABLE IF EXISTS receipts');
          await _createDB(db, newVersion);
        }
      },
    );
}

  Future<int> updateReceiptSourceOfFunds(int id, String newSource) async {
  final db = await instance.database;
  return await db.update(
    'receipts',
    {'source_of_funds': newSource},
    where: 'id = ?',
    whereArgs: [id],
  );
}

  Future<int> updateReceipt({
    required int id,
    required String storeName,
    required double totalAmount,
    required String category,
    required String sourceOfFunds,
  }) async {
    final db = await instance.database;
    return await db.update(
      'receipts',
      {
        'store_name': storeName,
        'total_amount': totalAmount,
        'category': category,
        'source_of_funds': sourceOfFunds,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteReceipt(int id) async {
    final db = await instance.database;
    await db.delete(
      'receipt_items',
      where: 'receipt_id = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
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
      image_path TEXT
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

  // 1. Simpan struk baru (Untuk fitur Scan / Input Struk)
  Future<int> insertReceipt(ReceiptModel receipt) async {
    final db = await instance.database;
    return await db.insert('receipts', receipt.toMap());
  }

  // 2. Ambil semua riwayat struk terbaru (Untuk Home & History)
  Future<List<ReceiptModel>> getAllReceipts() async {
    final db = await instance.database;
    final result = await db.query('receipts', orderBy: 'date DESC');
    return result.map((json) => ReceiptModel.fromMap(json)).toList();
  }

  // 3. Hitung total pengeluaran per kategori (Untuk Pie Chart / Portfolio)
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