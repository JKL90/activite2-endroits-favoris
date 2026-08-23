// ═══════════════════════════════════════════════════════════════════
// lib/modele/endroit.dart - Modèle Endroit avec sérialisation SQLite
// ═══════════════════════════════════════════════════════════════════
import 'dart:io';
import 'package:uuid/uuid.dart';

// Constante globale pour générer des UUID uniques
const uuid = Uuid();

class Endroit {
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

  final String id;              // Identifiant unique (UUID ou DB)
  final String nom;             // Nom du lieu
  final File image;             // Fichier photo stocké localement
  final double? latitude;       // Latitude GPS (optionnelle)
  final double? longitude;      // Longitude GPS (optionnelle)
  final String? adresse;        // Adresse textuelle formatée
  final DateTime dateCreation;  // Date d'enregistrement

  // Indique si la géolocalisation GPS est disponible
  bool get aLocalisation => latitude != null && longitude != null;

  // Convertit l'objet Endroit en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'image_path': image.path,
      'latitude': latitude,
      'longitude': longitude,
      'adresse': adresse,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  // Construit un objet Endroit à partir d'une Map SQLite
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

  // Cloner et modifier un objet Endroit
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