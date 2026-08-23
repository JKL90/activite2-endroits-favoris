// ═══════════════════════════════════════════════════════════════════
// lib/widgets/image_prise.dart - Sélecteur de photo moderne (Caméra / Galerie)
// ═══════════════════════════════════════════════════════════════════
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget interactif permettant à l'utilisateur de prendre une photo via la caméra
/// ou de la sélectionner depuis la galerie de l'appareil.
class ImagePrise extends StatefulWidget {
  const ImagePrise({super.key, required this.onPhotoSelectionnee});

  /// Callback transmettant le fichier image sélectionné au widget parent
  final void Function(File image) onPhotoSelectionnee;

  @override
  State<ImagePrise> createState() => _ImagePriseState();
}

class _ImagePriseState extends State<ImagePrise> {
  // Fichier photo sélectionné en local
  File? _photoSelectionnee;

  /// Déclenche le sélecteur d'image selon la source demandée (Caméra ou Galerie)
  Future<void> _choisirImage(ImageSource source) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: source,
      maxWidth: 1024, // Limite la largeur pour optimiser la mémoire et la taille du fichier
      imageQuality: 85, // Compression raisonnable sans perte visible de qualité
    );

    // Si l'utilisateur annule la sélection
    if (photo == null) return;

    final imageFile = File(photo.path);
    setState(() {
      _photoSelectionnee = imageFile;
    });

    // Transmission au parent (AjoutEndroit)
    widget.onPhotoSelectionnee(imageFile);
  }

  /// Affiche une feuille modale (ModalBottomSheet) pour laisser le choix entre Caméra et Galerie
  void _afficherMenuSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée visuelle de glissement
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ajouter une photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Option 1 : Appareil photo
                  _OptionSource(
                    icon: Icons.camera_alt_rounded,
                    label: 'Caméra',
                    couleur: Theme.of(context).colorScheme.primary,
                    onTap: () {
                      Navigator.pop(ctx);
                      _choisirImage(ImageSource.camera);
                    },
                  ),
                  // Option 2 : Galerie d'images
                  _OptionSource(
                    icon: Icons.photo_library_rounded,
                    label: 'Galerie',
                    couleur: Colors.deepPurple,
                    onTap: () {
                      Navigator.pop(ctx);
                      _choisirImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // ─── Cas 1 : Aucune photo sélectionnée ───
    if (_photoSelectionnee == null) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primary.withAlpha(70),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: InkWell(
          onTap: _afficherMenuSelection,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_a_photo_rounded,
                  size: 36,
                  color: primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Prendre une photo ou choisir dans la galerie',
                style: TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Appuyez pour sélectionner',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ─── Cas 2 : Photo sélectionnée avec bouton de modification ───
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _photoSelectionnee!,
            width: double.infinity,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: FilledButton.tonalIcon(
            onPressed: _afficherMenuSelection,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black.withAlpha(160),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('Changer', style: TextStyle(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

/// Bouton d'option avec icône ronde et libellé pour la sélection de source
class _OptionSource extends StatelessWidget {
  const _OptionSource({
    required this.icon,
    required this.label,
    required this.couleur,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: couleur.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: couleur),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}