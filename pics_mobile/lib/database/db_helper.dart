import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;
  static const String _dbName = 'pics_mobile.db';
  static const int _dbVersion = 1;

  // Table name
  static const String tablePendingSubmissions = 'pending_submissions';

  // Columns
  static const String colId = 'id';
  static const String colIdSchedule = 'id_schedule';
  static const String colPartOfCheck = 'part_of_check';
  static const String colInspector = 'inspector';
  static const String colItemsJson = 'items_json';
  static const String colCreatedAt = 'created_at';
  static const String colSyncStatus = 'sync_status';
  static const String colSyncAttempts = 'sync_attempts';
  static const String colLastError = 'last_error';

  // Sync status constants
  static const String statusPending = 'pending';
  static const String statusSynced = 'synced';
  static const String statusError = 'error';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePendingSubmissions (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colIdSchedule TEXT NOT NULL,
        $colPartOfCheck TEXT NOT NULL,
        $colInspector TEXT NOT NULL,
        $colItemsJson TEXT NOT NULL,
        $colCreatedAt TEXT NOT NULL,
        $colSyncStatus TEXT NOT NULL DEFAULT '$statusPending',
        $colSyncAttempts INTEGER NOT NULL DEFAULT 0,
        $colLastError TEXT
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_schedule_status 
      ON $tablePendingSubmissions ($colIdSchedule, $colSyncStatus)
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle future database migrations here
  }

  /// Close the database
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete all data (for testing purposes)
  static Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
