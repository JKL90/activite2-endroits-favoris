// ═══════════════════════════════════════════════════════════════════
// lib/services/db_helper.dart - Service de persistance SQLite
// ═══════════════════════════════════════════════════════════════════
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../modele/endroit.dart';

class DatabaseHelper {
  // Constructeur privé pour le pattern Singleton
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  // Nom de la base et table
  static const String _dbName = 'endroits_favoris.db';
  static const String _tableName = 'endroits';

  // Accès asynchrone à l'instance de la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialisation et création de la base de données SQLite
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            nom TEXT NOT NULL,
            image_path TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            adresse TEXT,
            date_creation TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // Insérer ou mettre à jour un endroit
  Future<void> insererEndroit(Endroit endroit) async {
    final db = await database;
    await db.insert(
      _tableName,
      endroit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Récupérer la liste de tous les endroits (triés par date décroissante)
  Future<List<Endroit>> chargerEndroits() async {
    final db = await database;
    final resultat = await db.query(
      _tableName,
      orderBy: 'date_creation DESC',
    );

    // Ne conserver que les endroits dont le fichier image existe encore
    final endroits = <Endroit>[];
    for (final map in resultat) {
      endroits.add(Endroit.fromMap(map));
    }
    return endroits;
  }

  // Supprimer un endroit par son identifiant unique
  Future<void> supprimerEndroit(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mettre à jour un endroit existant
  Future<void> mettreAJourEndroit(Endroit endroit) async {
    final db = await database;
    await db.update(
      _tableName,
      endroit.toMap(),
      where: 'id = ?',
      whereArgs: [endroit.id],
    );
  }
}
