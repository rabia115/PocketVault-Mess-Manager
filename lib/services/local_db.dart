
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      'pocketvault.db',
    );

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {

        // LOCAL MEMBERS CACHE

        await db.execute('''
          CREATE TABLE members (
            id TEXT PRIMARY KEY,
            full_name TEXT NOT NULL,
            email TEXT,
            phone TEXT,
            status TEXT DEFAULT 'active'
          )
        ''');

        // LOCAL TRANSACTIONS CACHE

        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            transaction_type TEXT NOT NULL,
            transaction_date TEXT NOT NULL
          )
        ''');

        // LOCAL INVENTORY CACHE

        await db.execute('''
          CREATE TABLE inventory (
            id TEXT PRIMARY KEY,
            item_name TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  // INSERT MEMBER

  static Future<void> insertMember(
      Map<String, dynamic> member,
      ) async {
    final db = await database;

    await db.insert(
      'members',
      member,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // GET MEMBERS

  static Future<List<Map<String, dynamic>>>
  getMembers() async {
    final db = await database;

    return await db.query('members');
  }

  // INSERT TRANSACTION

  static Future<void> insertTransaction(
      Map<String, dynamic> transaction,
      ) async {
    final db = await database;

    await db.insert(
      'transactions',
      transaction,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // GET TRANSACTIONS

  static Future<List<Map<String, dynamic>>>
  getTransactions() async {
    final db = await database;

    return await db.query(
      'transactions',
      orderBy: 'transaction_date DESC',
    );
  }

  // INSERT INVENTORY ITEM

  static Future<void> insertInventory(
      Map<String, dynamic> item,
      ) async {
    final db = await database;

    await db.insert(
      'inventory',
      item,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // GET INVENTORY

  static Future<List<Map<String, dynamic>>>
  getInventory() async {
    final db = await database;

    return await db.query('inventory');
  }

  // CLOSE DATABASE

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
