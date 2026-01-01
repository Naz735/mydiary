import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLHelper {
  // Open the database
  static Future<Database> _db() async {
    return openDatabase(
      join(await getDatabasesPath(), 'diary.db'),
      version: 3,
      onCreate: (db, v) async {
        await db.execute('''
        CREATE TABLE diaries(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          feeling TEXT,
          description TEXT,
          date TEXT,
          image_path TEXT)
        ''');
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 3) {
          await db.execute('ALTER TABLE diaries ADD COLUMN image_path TEXT');
        }
      },
    );
  }

  static Future<int> createDiary(String feeling, String desc, {String? imagePath}) async {
    final db = await _db();
    return db.insert('diaries', {
      'feeling': feeling,
      'description': desc,
      'date': DateTime.now().toString().substring(0, 16),
      'image_path': imagePath ?? '',
    });
  }

  static Future<int> updateDiary(int id, String feeling, String desc, {String? imagePath}) async {
    final db = await _db();
    return db.update(
      'diaries',
      {
        'feeling': feeling,
        'description': desc,
        'date': DateTime.now().toString().substring(0, 16),
        'image_path': imagePath ?? '',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> getDiaries() async {
    final db = await _db();
    return db.query('diaries', orderBy: 'id DESC');
  }

  static Future<Map<String, dynamic>> getDiary(int id) async {
    final db = await _db();
    final result = await db.query('diaries', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : {};
  }

  static Future<void> deleteDiary(int id) async {
    final db = await _db();
    await db.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearAll() async {
    final db = await _db();
    await db.delete('diaries');
  }
}
