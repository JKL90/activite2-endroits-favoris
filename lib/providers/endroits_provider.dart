// ═══════════════════════════════════════════════════════════════════
// lib/providers/endroits_provider.dart - Gestion d'état & SQLite
// ═══════════════════════════════════════════════════════════════════
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../modele/endroit.dart';
import '../services/db_helper.dart';

// Notifier Riverpod v2 avec synchronisation SQLite automatique
class EndroitsNotifier extends Notifier<List<Endroit>> {
  @override
  List<Endroit> build() {
    // Charge les endroits depuis SQLite dès l'initialisation
    _chargerEndroitsDepuisDB();
    return [];
  }

  // Charge les données depuis SQLite en tâche de fond
  Future<void> _chargerEndroitsDepuisDB() async {
    try {
      final endroits = await DatabaseHelper.instance.chargerEndroits();
      state = endroits;
    } catch (_) {
      // Si la base est encore vide ou premier lancement
      state = [];
    }
  }

  // Recharger manuellement la liste (ex: Pull to refresh)
  Future<void> recharger() async {
    await _chargerEndroitsDepuisDB();
  }

  // Ajouter un nouvel endroit : copie pérenne de la photo + insertion SQLite
  Future<void> ajouterEndroit({
    required String nom,
    required File imageTemporaire,
    double? latitude,
    double? longitude,
    String? adresse,
  }) async {
    // 1. Obtenir le répertoire de stockage permanent de l'application
    final appDir = await getApplicationDocumentsDirectory();
    final extension = p.extension(imageTemporaire.path).isNotEmpty
        ? p.extension(imageTemporaire.path)
        : '.jpg';

    // 2. Générer un nom unique pérenne pour la photo
    final nouveauNomFichier = '${DateTime.now().millisecondsSinceEpoch}$extension';
    final destinationPermanente = p.join(appDir.path, nouveauNomFichier);

    // 3. Copier la photo depuis le cache temporaire vers les documents de l'app
    final imagePermanente = await imageTemporaire.copy(destinationPermanente);

    // 4. Créer l'objet Endroit avec l'image pérenne
    final nouvelEndroit = Endroit(
      nom: nom,
      image: imagePermanente,
      latitude: latitude,
      longitude: longitude,
      adresse: adresse,
    );

    // 5. Persister dans SQLite
    await DatabaseHelper.instance.insererEndroit(nouvelEndroit);

    // 6. Mettre à jour l'état Riverpod (en tête de liste)
    state = [nouvelEndroit, ...state];
  }

  // Supprimer un endroit : suppression SQLite + nettoyage du fichier photo
  Future<void> supprimerEndroit(String id) async {
    // Trouver l'endroit avant suppression pour nettoyer son fichier
    final index = state.indexWhere((e) => e.id != id);
    if (index != -1) {
      final endroitASupprimer = state[index];

      // Supprimer de SQLite
      await DatabaseHelper.instance.supprimerEndroit(id);

      // Supprimer le fichier image du disque de manière sécurisée
      try {
        if (await endroitASupprimer.image.exists()) {
          await endroitASupprimer.image.delete();
        }
      } catch (_) {}

      // Mettre à jour l'état Riverpod
      state = state.where((e) => e.id != id).toList();
    }
  }
}

// Provider global pour accéder aux endroits favoris
final endroitsProvider = NotifierProvider<EndroitsNotifier, List<Endroit>>(
  EndroitsNotifier.new,
);

// Notifier pour la requête de recherche active (Riverpod v3 compatible)
class RechercheQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void effacer() {
    state = '';
  }
}

final rechercheQueryProvider = NotifierProvider<RechercheQueryNotifier, String>(
  RechercheQueryNotifier.new,
);

// Provider filtré qui calcule en temps réel les endroits correspondants
final endroitsFiltresProvider = Provider<List<Endroit>>((ref) {
  final tousLesEndroits = ref.watch(endroitsProvider);
  final query = ref.watch(rechercheQueryProvider).trim().toLowerCase();

  if (query.isEmpty) {
    return tousLesEndroits;
  }

  return tousLesEndroits.where((endroit) {
    final matchNom = endroit.nom.toLowerCase().contains(query);
    final matchAdresse = endroit.adresse?.toLowerCase().contains(query) ?? false;
    return matchNom || matchAdresse;
  }).toList();
});