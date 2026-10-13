import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'kcard_v1.db');

    return await openDatabase(
      path,
      version: 4, // 버전을 4로 올립니다.
      onCreate: (db, version) async {
        // 명함첩 테이블
        await db.execute('''
          CREATE TABLE cards(
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            imagePath TEXT, 
            name TEXT, 
            position TEXT, 
            phone TEXT, 
            email TEXT, 
            korCo TEXT, 
            engCo TEXT, 
            addr TEXT
          )
        ''');
        // 내 정보 테이블 (id는 0으로 고정하여 단 건만 저장)
        await db.execute('''
          CREATE TABLE my_info(
            id INTEGER PRIMARY KEY CHECK (id = 0), 
            name TEXT, 
            job TEXT, 
            company TEXT, 
            phone TEXT, 
            email TEXT, 
            address TEXT,
            imagePath TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS my_info(
              id INTEGER PRIMARY KEY CHECK (id = 0), 
              name TEXT, job TEXT, company TEXT, phone TEXT, email TEXT, address TEXT, imagePath TEXT
            )
          ''');
        }
      },
    );
  }

  // 내 정보 저장/업데이트
  Future<void> saveMyInfo(Map<String, String> info) async {
    final db = await database;
    await db.insert(
      'my_info',
      {'id': 0, ...info},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 내 정보 불러오기
  Future<Map<String, String>?> getMyInfo() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('my_info', where: 'id = 0');
    if (maps.isEmpty) return null;
    return maps.first.map((key, value) => MapEntry(key, value?.toString() ?? ""));
  }

  // 내 정보 삭제
  Future<void> deleteMyInfo() async {
    final db = await database;
    await db.delete('my_info', where: 'id = 0');
  }

  // 명함첩 관련 기존 로직
  Future<List<BusinessCard>> getCards() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('cards', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => BusinessCard.fromMap(maps[i]));
  }

  Future<void> insertCard(BusinessCard card) async {
    final db = await database;
    await db.insert('cards', card.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCards(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    await db.delete('cards', where: "id IN (${ids.join(',')})");
  }

  // database_helper.dart 에 추가
  Future<int> updateCard(BusinessCard card) async {
    final db = await database;
    return await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }
}