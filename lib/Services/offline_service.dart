import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../Models/cart_item_model.dart';

class OfflineService {
  static const _databaseName = "pos_offline.db";
  static const _databaseVersion = 1;
  static const table = 'pending_orders';

  static const columnId = 'id';
  static const columnItems = 'items';
  static const columnCreatedAt = 'created_at';

  // Make this a singleton class.
  OfflineService._privateConstructor();
  static final OfflineService instance = OfflineService._privateConstructor();

  // Only have a single app-wide reference to the database.
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // Lazily instantiate the db the first time it is accessed.
    _database = await _initDatabase();
    return _database!;
  }

  // This opens the database (and creates it if it doesn't exist).
  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // SQL code to create the database table.
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnItems TEXT NOT NULL,
            $columnCreatedAt TEXT NOT NULL
          )
          ''');
  }

  // Helper methods

  Future<void> queueOrder(List<CartItem> items) async {
    final db = await instance.database;
    await db.insert(table, {
      columnItems: jsonEncode(items.map((item) => item.toJson()).toList()),
      columnCreatedAt: DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final db = await instance.database;
    return await db.query(table, orderBy: '$columnCreatedAt ASC');
  }

  Future<void> clearPendingOrder(int id) async {
    final db = await instance.database;
    await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<void> clearAllPendingOrders() async {
    final db = await instance.database;
    await db.delete(table);
  }
}
