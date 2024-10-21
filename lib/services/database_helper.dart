import 'package:myapp/models/found_object.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    String path = join(await getDatabasesPath(), 'sncf_objets_trouves.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE viewed_objects (
            id TEXT PRIMARY KEY,
            station_name TEXT,
            object_type TEXT,
            date TEXT,
            nature TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE recent_searches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            station_name TEXT,
            object_type TEXT,
            date_min TEXT,
            date_max TEXT
          )
        ''');
      },
    );
  }

  // Insérer un objet consulté
  Future<void> insertViewedObject(FoundObject object) async {
    final db = await database;
    await db.insert('viewed_objects', {
      'id': object.getUniqueId(),
      'station_name': object.stationName,
      'object_type': object.type,
      'date': object.date.toIso8601String(),
      'nature': object.nature,
    });
  }

  // Vérifier si un objet a déjà été consulté
  Future<bool> isObjectViewed(FoundObject object) async {
    final db = await database;
    final result = await db.query(
      'viewed_objects',
      where: 'id = ?',
      whereArgs: [object.getUniqueId()],
    );
    return result.isNotEmpty;
  }

  // Insérer une recherche récente
  Future<void> insertRecentSearch({
    required String stationName,
    required String objectType,
    required DateTime? dateMin,
    required DateTime? dateMax,
  }) async {
    final db = await database;
    await db.insert('recent_searches', {
      'station_name': stationName,
      'object_type': objectType,
      'date_min': dateMin?.toIso8601String(),
      'date_max': dateMax?.toIso8601String(),
    });
  }

  // Récupérer les recherches récentes
  Future<List<Map<String, dynamic>>> getRecentSearches() async {
    final db = await database;
    return await db.query('recent_searches', orderBy: 'id DESC');
  }
}
