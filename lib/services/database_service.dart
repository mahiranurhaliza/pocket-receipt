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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receipts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        storeName TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        imagePath TEXT,
        items TEXT
      )
    ''');
    return null;
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

  // 4. Hapus struk berdasarkan ID
  Future<int> deleteReceipt(int id) async {
    final db = await instance.database;
    return await db.delete('receipts', where: 'id = ?', whereArgs: [id]);
  }
}