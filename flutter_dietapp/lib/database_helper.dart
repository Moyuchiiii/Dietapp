import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer'; // ログ記録用のパッケージをインポート
import 'package:intl/intl.dart'; // 日付フォーマット用のパッケージをインポート

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
      version: 6, // バージョンを5から6に更新
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
            date TEXT,
            stamp TEXT
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
            updated_at TEXT,
            stamp TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE daily_stamps (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT UNIQUE,
            stamp TEXT
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
        if (oldVersion < 4) {
          await db.execute('''
            ALTER TABLE daily_records ADD COLUMN stamp TEXT
          ''');
        }
        if (oldVersion < 6) {
          await db.execute('''
            ALTER TABLE daily_records_log ADD COLUMN stamp TEXT
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

  Future<Map<String, dynamic>?> getUserData() async {
    final db = await database;
    final results = await db.query('user_data');
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getDailyRecordByDate(String date) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT dr.*
      FROM daily_records dr
      INNER JOIN (
        SELECT date, MAX(id) as max_id
        FROM daily_records
        WHERE date = ?
        GROUP BY date
      ) latest ON dr.date = latest.date AND dr.id = latest.max_id
    ''', [date]);
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
      'stamp': data['stamp'], // スタンプ情報もログに追加
      'updated_at': formattedCurrentTime,
    };

    log(logMessage); // print の代わりに log を使用
    return await db.insert('daily_records_log', logData);
  }

  Future<List<Map<String, dynamic>>> getGraphData() async {
    final db = await database;
    
    // 各日付の最新のレコードのみを取得する（サブクエリを使用）
    final results = await db.rawQuery('''
      SELECT dr.*
      FROM daily_records dr
      INNER JOIN (
        SELECT date, MAX(id) as max_id
        FROM daily_records
        WHERE weight IS NOT NULL OR body_fat IS NOT NULL
        GROUP BY date
      ) latest ON dr.date = latest.date AND dr.id = latest.max_id
      ORDER BY date ASC
    ''');

    // 日付形式の標準化
    return results.map((record) {
      final dateStr = record['date'] as String;
      try {
        // 日付形式を検証し、必要に応じて変換
        final date = DateTime.parse(dateStr.replaceAll('/', '-'));
        return {
          ...record,
          'date': DateFormat('yyyy/MM/dd').format(date),
        };
      } catch (e) {
        return record;
      }
    }).toList();
  }

  Future<bool> hasUserData() async {
    final db = await database;
    final result = await db.query('user_data');
    return result.isNotEmpty;
  }
}