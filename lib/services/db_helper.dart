// ═══════════════════════════════════════════════════════════════════
// lib/services/db_helper.dart - Service de persistance SQLite (Singleton)
// ═══════════════════════════════════════════════════════════════════
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../modele/endroit.dart';

/// Classe utilitaire encapsulant toutes les interactions avec la base de données locale SQLite.
/// Utilise le design pattern Singleton pour garantir une unique connexion à la base.
class DatabaseHelper {
  // Constructeur privé pour interdire l'instanciation directe
  DatabaseHelper._();

  /// Instance unique (Singleton) partagée dans toute l'application
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  // Constantes pour le nom de fichier et la table
  static const String _dbName = 'endroits_favoris.db';
  static const String _tableName = 'endroits';

  /// Getter asynchrone retournant l'instance de la base ouverte (avec initialisation paresseuse).
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialise la base de données et crée la table si elle n'existe pas encore.
  Future<Database> _initDatabase() async {
    // Récupère le répertoire système dédié aux bases de données sur Android/iOS
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    // Ouvre la base de données (déclenche onCreate lors du premier lancement)
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Définition du schéma de la table SQL 'endroits'
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

  // ─────────────────────────────────────────────────────────────────
  // OPÉRATIONS CRUD (Create, Read, Update, Delete)
  // ─────────────────────────────────────────────────────────────────

  /// Insère un nouvel endroit dans la base de données.
  /// Si un enregistrement avec le même identifiant existe, il est remplacé (ConflictAlgorithm.replace).
  Future<void> insererEndroit(Endroit endroit) async {
    final db = await database;
    await db.insert(
      _tableName,
      endroit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère la liste complète de tous les endroits stockés en SQLite,
  /// triés par date de création décroissante (du plus récent au plus ancien).
  Future<List<Endroit>> chargerEndroits() async {
    final db = await database;
    final resultat = await db.query(
      _tableName,
      orderBy: 'date_creation DESC',
    );

    final endroits = <Endroit>[];
    for (final map in resultat) {
      endroits.add(Endroit.fromMap(map));
    }
    return endroits;
  }

  /// Supprime un endroit de la table SQLite via son identifiant unique.
  Future<void> supprimerEndroit(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Met à jour les informations d'un endroit existant.
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
