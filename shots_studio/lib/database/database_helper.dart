import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'shots_studio.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        payee_name TEXT NOT NULL,
        requestor_name TEXT NOT NULL,
        amount REAL NOT NULL,
        transaction_date INTEGER NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        currency TEXT NOT NULL DEFAULT 'INR',
        payment_mode TEXT NOT NULL,
        original_message TEXT NOT NULL,
        message_hash TEXT UNIQUE NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE analysis_metadata (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_analyzed_message_date INTEGER,
        last_analysis_date INTEGER NOT NULL,
        total_messages_analyzed INTEGER NOT NULL DEFAULT 0,
        total_transactions_found INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_date ON transactions(transaction_date);
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_type ON transactions(transaction_type);
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_category ON transactions(category);
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
