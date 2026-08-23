// ═══════════════════════════════════════════════════════════════════
// lib/providers/endroits_provider.dart - Gestion d'État Riverpod & Persistance
// ═══════════════════════════════════════════════════════════════════
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../modele/endroit.dart';
import '../services/db_helper.dart';

/// Notifier Riverpod (v2/v3) gérant la liste des endroits en mémoire
/// et synchronisant automatiquement les modifications avec la base locale SQLite.
class EndroitsNotifier extends Notifier<List<Endroit>> {
  /// Méthode d'initialisation de l'état.
  /// Lance immédiatement le chargement asynchrone des données depuis SQLite.
  @override
  List<Endroit> build() {
    _chargerEndroitsDepuisDB();
    return [];
  }

  /// Charge tous les endroits sauvegardés dans la base SQLite locale.
  Future<void> _chargerEndroitsDepuisDB() async {
    try {
      final endroits = await DatabaseHelper.instance.chargerEndroits();
      state = endroits;
    } catch (_) {
      state = [];
    }
  }

  /// Permet de recharger manuellement la liste (utilisé pour le Pull-to-Refresh).
  Future<void> recharger() async {
    await _chargerEndroitsDepuisDB();
  }

  /// Ajoute un nouvel endroit :
  /// 1. Copie la photo temporaire dans le stockage interne permanent de l'application.
  /// 2. Crée l'objet métier [Endroit] avec le chemin définitif de l'image.
  /// 3. Enregistre l'enregistrement dans la table SQLite.
  /// 4. Met à jour l'état réactif Riverpod (en tête de liste).
  Future<void> ajouterEndroit({
    required String nom,
    required File imageTemporaire,
    double? latitude,
    double? longitude,
    String? adresse,
  }) async {
    // 1. Récupération du dossier interne permanent de l'application
    final appDir = await getApplicationDocumentsDirectory();
    final extension = p.extension(imageTemporaire.path).isNotEmpty
        ? p.extension(imageTemporaire.path)
        : '.jpg';

    // 2. Génération d'un nom de fichier unique basé sur le timestamp
    final nouveauNomFichier = '${DateTime.now().millisecondsSinceEpoch}$extension';
    final destinationPermanente = p.join(appDir.path, nouveauNomFichier);

    // 3. Copie physique du fichier vers le stockage permanent
    final imagePermanente = await imageTemporaire.copy(destinationPermanente);

    // 4. Instanciation du modèle Endroit
    final nouvelEndroit = Endroit(
      nom: nom,
      image: imagePermanente,
      latitude: latitude,
      longitude: longitude,
      adresse: adresse,
    );

    // 5. Persistance en base SQLite locale
    await DatabaseHelper.instance.insererEndroit(nouvelEndroit);

    // 6. Mise à jour de l'état (notification automatique de tous les widgets abonnés)
    state = [nouvelEndroit, ...state];
  }

  /// Supprime un endroit par son identifiant :
  /// 1. Supprime la ligne correspondante dans la base SQLite.
  /// 2. Supprime physiquement le fichier image associé sur le disque pour libérer l'espace.
  /// 3. Met à jour l'état réactif Riverpod.
  Future<void> supprimerEndroit(String id) async {
    final index = state.indexWhere((e) => e.id != id);
    if (index != -1) {
      final endroitASupprimer = state[index];

      // 1. Suppression SQLite
      await DatabaseHelper.instance.supprimerEndroit(id);

      // 2. Suppression propre du fichier image
      try {
        if (await endroitASupprimer.image.exists()) {
          await endroitASupprimer.image.delete();
        }
      } catch (_) {}

      // 3. Mise à jour de l'état
      state = state.where((e) => e.id != id).toList();
    }
  }
}

/// Provider principal permettant aux widgets de lire et d'observer la liste des endroits.
final endroitsProvider = NotifierProvider<EndroitsNotifier, List<Endroit>>(
  EndroitsNotifier.new,
);

/// Notifier gérant la chaîne de caractères de recherche saisie par l'utilisateur.
class RechercheQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  /// Définit le texte de recherche actif
  void setQuery(String query) {
    state = query;
  }

  /// Réinitialise la recherche
  void effacer() {
    state = '';
  }
}

/// Provider pour la gestion réactive de la barre de recherche
final rechercheQueryProvider = NotifierProvider<RechercheQueryNotifier, String>(
  RechercheQueryNotifier.new,
);

/// Provider calculé (dérivé) qui filtre la liste des endroits en temps réel
/// selon le nom du lieu ou l'adresse correspondante.
final endroitsFiltresProvider = Provider<List<Endroit>>((ref) {
  final tousLesEndroits = ref.watch(endroitsProvider);
  final query = ref.watch(rechercheQueryProvider).trim().toLowerCase();

  // Si aucune recherche, retourner la liste intégrale
  if (query.isEmpty) {
    return tousLesEndroits;
  }

  // Filtrage combiné sur le nom ou l'adresse
  return tousLesEndroits.where((endroit) {
    final matchNom = endroit.nom.toLowerCase().contains(query);
    final matchAdresse = endroit.adresse?.toLowerCase().contains(query) ?? false;
    return matchNom || matchAdresse;
  }).toList();
});