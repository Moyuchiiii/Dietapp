// SQLiteデータベースの初期化・テーブル作成・CRUD操作などをまとめたヘルパークラス。
// ユーザーデータや日々の記録、ログの管理を行います。

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer';
import 'package:intl/intl.dart';

// データベース操作のヘルパークラス
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  // データベースインスタンス取得
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // データベース初期化・テーブル作成
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dietapp.db');

    return await openDatabase(
      path,
      version: 6,
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
        // バージョンアップ時のテーブル追加・カラム追加
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

  // ユーザーデータ挿入
  Future<int> insertUserData(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('user_data', data);
  }

  // 日々の記録挿入
  Future<int> insertDailyRecord(Map<String, dynamic> data) async {
    final db = await database;
    final recordId = await db.insert('daily_records', data);
    await logDailyRecordUpdate(recordId, data);
    return recordId;
  }

  // ユーザーデータ取得
  Future<Map<String, dynamic>?> getUserData() async {
    final db = await database;
    final results = await db.query('user_data');
    return results.isNotEmpty ? results.first : null;
  }

  // 指定日付の最新記録を取得
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

  // 日々の記録更新
  Future<int> updateDailyRecord(int id, Map<String, dynamic> data) async {
    final db = await database;
    final result = await db.update(
      'daily_records',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    await logDailyRecordUpdate(id, data);
    return result;
  }

  // 記録の更新ログを保存
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
      'stamp': data['stamp'],
      'updated_at': formattedCurrentTime,
    };

    log(logMessage);
    return await db.insert('daily_records_log', logData);
  }

  // グラフ用データ取得（日付ごと最新のみ）
  Future<List<Map<String, dynamic>>> getGraphData() async {
    final db = await database;
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

    return results.map((record) {
      final dateStr = record['date'] as String;
      try {
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

  // ユーザーデータ有無判定
  Future<bool> hasUserData() async {
    final db = await database;
    final result = await db.query('user_data');
    return result.isNotEmpty;
  }
}