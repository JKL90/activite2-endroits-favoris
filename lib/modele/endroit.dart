// ═══════════════════════════════════════════════════════════════════
// lib/modele/endroit.dart - Modèle de données Endroit & Sérialisation SQLite
// ═══════════════════════════════════════════════════════════════════
import 'dart:io';
import 'package:uuid/uuid.dart';

/// Instance globale pour la génération d'identifiants uniques universels (UUID v4)
const uuid = Uuid();

/// Modèle métier représentant un lieu ou un endroit favori enregistré par l'utilisateur.
class Endroit {
  /// Constructeur principal.
  /// Si l'identifiant n'est pas fourni (nouveau lieu), un UUID v4 est généré.
  /// Si la date de création n'est pas fournie, la date actuelle est utilisée.
  Endroit({
    String? id,
    required this.nom,
    required this.image,
    this.latitude,
    this.longitude,
    this.adresse,
    DateTime? dateCreation,
  })  : id = id ?? uuid.v4(),
        dateCreation = dateCreation ?? DateTime.now();

  /// Identifiant unique (Clé primaire SQLite)
  final String id;

  /// Nom ou intitulé du lieu
  final String nom;

  /// Référence au fichier photo stocké de façon pérenne sur l'appareil
  final File image;

  /// Coordonnée GPS : Latitude (optionnelle)
  final double? latitude;

  /// Coordonnée GPS : Longitude (optionnelle)
  final double? longitude;

  /// Adresse postale textuelle obtenue par géocodage inverse
  final String? adresse;

  /// Date et heure de création de l'enregistrement
  final DateTime dateCreation;

  /// Propriété calculée indiquant si des coordonnées GPS valides sont associées
  bool get aLocalisation => latitude != null && longitude != null;

  /// ─────────────────────────────────────────────────────────────────
  /// SÉRIALISATION SQLITE
  /// ─────────────────────────────────────────────────────────────────

  /// Convertit l'instance [Endroit] en une Map clé-valeur pour l'insertion SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'image_path': image.path, // Chemin d'accès au fichier sur le disque
      'latitude': latitude,
      'longitude': longitude,
      'adresse': adresse,
      'date_creation': dateCreation.toIso8601String(), // Format standard ISO-8601
    };
  }

  /// Reconstruit une instance [Endroit] à partir d'une ligne extraite de la table SQLite.
  factory Endroit.fromMap(Map<String, dynamic> map) {
    return Endroit(
      id: map['id'] as String,
      nom: map['nom'] as String,
      image: File(map['image_path'] as String),
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      adresse: map['adresse'] as String?,
      dateCreation: map['date_creation'] != null
          ? DateTime.tryParse(map['date_creation'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Permet de dupliquer un objet [Endroit] en modifiant certains de ses attributs.
  Endroit copyWith({
    String? id,
    String? nom,
    File? image,
    double? latitude,
    double? longitude,
    String? adresse,
    DateTime? dateCreation,
  }) {
    return Endroit(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      image: image ?? this.image,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      adresse: adresse ?? this.adresse,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}