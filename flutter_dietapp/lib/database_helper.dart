import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer'; // ログ記録用のパッケージをインポート

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dietapp.db');

    return await openDatabase(
      path,
      version: 3, // バージョンを2から3に更新
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            height REAL,
            current_weight REAL,
            target_weight REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE daily_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            weight REAL,
            body_fat REAL,
            memo TEXT,
            date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE daily_records_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_id INTEGER,
            weight REAL,
            body_fat REAL,
            memo TEXT,
            date TEXT,
            updated_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS daily_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              weight REAL,
              body_fat REAL,
              memo TEXT,
              date TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS daily_records_log (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              record_id INTEGER,
              weight REAL,
              body_fat REAL,
              memo TEXT,
              date TEXT,
              updated_at TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS daily_records_log (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              record_id INTEGER,
              weight REAL,
              body_fat REAL,
              memo TEXT,
              date TEXT,
              updated_at TEXT
            )
          ''');
        }
      },
    );
  }

  Future<int> insertUserData(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('user_data', data);
  }

  Future<int> insertDailyRecord(Map<String, dynamic> data) async {
    final db = await database;
    final recordId = await db.insert('daily_records', data);
    await logDailyRecordUpdate(recordId, data); // 新しい記録をログに記録
    return recordId;
  }

  Future<Map<String, dynamic>?> getDailyRecordByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'daily_records',
      where: 'date = ?',
      whereArgs: [date],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateDailyRecord(int id, Map<String, dynamic> data) async {
    final db = await database;
    final result = await db.update(
      'daily_records',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    await logDailyRecordUpdate(id, data); // ログを1回だけ記録
    return result;
  }

  Future<int> logDailyRecordUpdate(int recordId, Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now();
    final formattedCurrentTime = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}';
    final logMessage = '''
現在時刻: $formattedCurrentTime
変更を加えた日付: ${data['date']}
体重: ${data['weight']} 体脂肪率: ${data['body_fat']}
メモ: ${data['memo']}
''';

    final logData = {
      'record_id': recordId,
      'weight': data['weight'],
      'body_fat': data['body_fat'],
      'memo': data['memo'],
      'date': data['date'],
      'updated_at': formattedCurrentTime,
    };

    log(logMessage); // print の代わりに log を使用
    return await db.insert('daily_records_log', logData);
  }
}