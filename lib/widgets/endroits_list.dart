// ═══════════════════════════════════════════════════════════════════
// lib/widgets/endroits_list.dart - Affichage Liste et Grille des Endroits
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modele/endroit.dart';
import '../providers/endroits_provider.dart';
import '../vue/ajout_endroit.dart';
import '../vue/endroit_detail.dart';

/// Widget réutilisable présentant la collection des endroits
/// sous forme de liste défilante ou de grille à 2 colonnes.
class EndroitsList extends ConsumerWidget {
  const EndroitsList({
    super.key,
    required this.endroits,
    this.estModeGrille = false,
  });

  /// Liste des endroits à afficher (peut être filtrée par la recherche)
  final List<Endroit> endroits;

  /// Mode d'affichage actif : true pour grille, false pour liste
  final bool estModeGrille;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // ─── Vue État Vide (Aucun endroit enregistré ou aucun résultat) ───
    if (endroits.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aucun endroit favori',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enregistrez vos lieux préférés avec photos et coordonnées GPS conservés en base SQLite locale.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withAlpha(180),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AjoutEndroit()),
                  );
                },
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('Ajouter un premier endroit'),
              ),
            ],
          ),
        ),
      );
    }

    // ─── Vue en Grille (2 colonnes) ───
    if (estModeGrille) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.78,
        ),
        itemCount: endroits.length,
        itemBuilder: (context, index) {
          final endroit = endroits[index];
          return _EndroitGridCard(endroit: endroit);
        },
      );
    }

    // ─── Vue en Liste (Cartes avec Swipe-to-Delete) ───
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: endroits.length,
      itemBuilder: (context, index) {
        final endroit = endroits[index];

        return Dismissible(
          key: Key(endroit.id),
          direction: DismissDirection.endToStart,
          // Arrière-plan rouge lors du glissement pour supprimer
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent.shade400,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Supprimer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
              ],
            ),
          ),
          onDismissed: (_) {
            // Suppression en base SQLite et de l'état
            ref.read(endroitsProvider.notifier).supprimerEndroit(endroit.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${endroit.nom} supprimé.'),
                duration: const Duration(seconds: 4),
              ),
            );
          },
          child: _EndroitListCard(endroit: endroit),
        );
      },
    );
  }
}

/// Carte individuelle pour le mode d'affichage en Liste
class _EndroitListCard extends StatelessWidget {
  const _EndroitListCard({required this.endroit});

  final Endroit endroit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Navigation vers l'écran de détails
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EndroitDetail(endroit: endroit),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo de l'endroit avec transition Hero
              Hero(
                tag: 'image_${endroit.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    endroit.image,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Informations textuelles & badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      endroit.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (endroit.adresse != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              endroit.adresse!,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        if (endroit.aLocalisation)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.gps_fixed, size: 10, color: primary),
                                const SizedBox(width: 4),
                                Text(
                                  'GPS actif',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.grey.withAlpha(150),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte individuelle pour le mode d'affichage en Grille
class _EndroitGridCard extends StatelessWidget {
  const _EndroitGridCard({required this.endroit});

  final Endroit endroit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EndroitDetail(endroit: endroit),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vignette immersive avec badge GPS en superposition
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'image_${endroit.id}',
                    child: Image.file(
                      endroit.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (endroit.aLocalisation)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(140),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Nom et adresse sous l'image
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endroit.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    endroit.adresse ?? 'Sans coordonnées',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodySmall?.color?.withAlpha(160),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}