// ═══════════════════════════════════════════════════════════════════
// lib/vue/endroits_interface.dart - Interface principale & Liste des Favoris
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/endroits_provider.dart';
import '../widgets/endroits_list.dart';
import 'ajout_endroit.dart';

/// Écran principal de l'application affichant la liste des lieux favoris
/// avec support de la recherche instantanée, de la bascule vue liste/grille et du pull-to-refresh.
class EndroitsInterface extends ConsumerStatefulWidget {
  const EndroitsInterface({super.key});

  @override
  ConsumerState<EndroitsInterface> createState() => _EndroitsInterfaceState();
}

class _EndroitsInterfaceState extends ConsumerState<EndroitsInterface> {
  // Indicateur d'affichage en grille (true) ou en liste (false)
  bool _estModeGrille = false;

  // Indicateur d'activation du mode recherche dans l'AppBar
  bool _modeRecherche = false;

  // Contrôleur du champ de saisie de recherche
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Écoute des providers Riverpod
    final tousLesEndroits = ref.watch(endroitsProvider);
    final endroitsAffiches = ref.watch(endroitsFiltresProvider);
    final queryRecherche = ref.watch(rechercheQueryProvider);

    return Scaffold(
      appBar: AppBar(
        // Titre dynamique : soit le champ de recherche textuel, soit le titre "Mes Endroits" avec badge
        title: _modeRecherche
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Rechercher un endroit ou une ville...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(140),
                  ),
                ),
                onChanged: (val) {
                  ref.read(rechercheQueryProvider.notifier).setQuery(val);
                },
              )
            : Row(
                children: [
                  const Text('Mes Endroits'),
                  if (tousLesEndroits.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${tousLesEndroits.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
        actions: [
          // Bouton pour ouvrir / fermer la recherche
          IconButton(
            icon: Icon(
              _modeRecherche ? Icons.close_rounded : Icons.search_rounded,
            ),
            tooltip: _modeRecherche ? 'Fermer la recherche' : 'Rechercher',
            onPressed: () {
              setState(() {
                if (_modeRecherche) {
                  _modeRecherche = false;
                  _searchController.clear();
                  ref.read(rechercheQueryProvider.notifier).effacer();
                } else {
                  _modeRecherche = true;
                }
              });
            },
          ),
          // Bouton de bascule Vue Grille / Vue Liste
          IconButton(
            icon: Icon(
              _estModeGrille
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
            ),
            tooltip: _estModeGrille ? 'Vue Liste' : 'Vue Grille',
            onPressed: () {
              setState(() {
                _estModeGrille = !_estModeGrille;
              });
            },
          ),
        ],
      ),
      // Pull-to-Refresh : Permet de rafraîchir manuellement la liste depuis SQLite
      body: RefreshIndicator(
        onRefresh: () => ref.read(endroitsProvider.notifier).recharger(),
        child: Column(
          children: [
            // Bandeau d'information si un filtre de recherche est actif
            if (queryRecherche.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: primary.withAlpha(15),
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded, size: 16, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${endroitsAffiches.length} résultat(s) pour "$queryRecherche"',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _searchController.clear();
                        ref.read(rechercheQueryProvider.notifier).effacer();
                      },
                      child: Text(
                        'Effacer',
                        style: TextStyle(
                          fontSize: 12,
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Affichage de la liste ou de la grille
            Expanded(
              child: EndroitsList(
                endroits: endroitsAffiches,
                estModeGrille: _estModeGrille,
              ),
            ),
          ],
        ),
      ),
      // Bouton d'action flottant moderne étendu pour ajouter un lieu
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AjoutEndroit(),
            ),
          );
        },
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Nouvel Endroit'),
        elevation: 3,
      ),
    );
  }
}