// ═══════════════════════════════════════════════════════════════════
// lib/vue/endroit_detail.dart - Page de détails avec SliverAppBar & Carte
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../modele/endroit.dart';
import '../providers/endroits_provider.dart';

class EndroitDetail extends ConsumerWidget {
  const EndroitDetail({super.key, required this.endroit});

  final Endroit endroit;

  // Formatage de la date d'enregistrement
  String _formaterDate(DateTime date) {
    final mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar rétractable avec image en Hero
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                endroit.nom,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'image_${endroit.id}',
                    child: Image.file(
                      endroit.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Dégradé pour lisibilité du titre
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(80),
                          Colors.transparent,
                          Colors.black.withAlpha(180),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: "Supprimer l'endroit",
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Supprimer cet endroit ?'),
                      content: Text(
                        'Voulez-vous vraiment supprimer "${endroit.nom}" de vos favoris et de la base locale ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                          onPressed: () {
                            ref
                                .read(endroitsProvider.notifier)
                                .supprimerEndroit(endroit.id);
                            Navigator.pop(ctx); // Ferme la boîte de dialogue
                            Navigator.pop(context); // Retourne à la liste
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${endroit.nom} a été supprimé.'),
                              ),
                            );
                          },
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // Contenu des détails
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte d'informations principales
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primary.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.place_rounded,
                                  color: primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      endroit.nom,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Enregistré le ${_formaterDate(endroit.dateCreation)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (endroit.adresse != null) ...[
                            const Divider(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    endroit.adresse!,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (endroit.aLocalisation) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.gps_fixed_rounded,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'GPS : ${endroit.latitude!.toStringAsFixed(5)}, ${endroit.longitude!.toStringAsFixed(5)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodySmall?.color,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section Carte Google Maps
                  if (endroit.aLocalisation) ...[
                    Row(
                      children: [
                        Icon(Icons.map_rounded, size: 20, color: primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Emplacement sur la carte',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withAlpha(40)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(endroit.latitude!, endroit.longitude!),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: const MarkerId('lieu_marker'),
                              position: LatLng(endroit.latitude!, endroit.longitude!),
                              infoWindow: InfoWindow(
                                title: endroit.nom,
                                snippet: endroit.adresse,
                              ),
                            ),
                          },
                          zoomControlsEnabled: true,
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_off_outlined, color: Colors.grey.shade500),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Aucune coordonnée GPS enregistrée pour cet endroit.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}