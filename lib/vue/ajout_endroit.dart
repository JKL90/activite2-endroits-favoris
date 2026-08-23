// ═══════════════════════════════════════════════════════════════════
// lib/vue/ajout_endroit.dart - Formulaire d'ajout avec SQLite & GPS
// ═══════════════════════════════════════════════════════════════════
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/endroits_provider.dart';
import '../widgets/image_prise.dart';
import '../widgets/localisation_prise.dart';

/// Écran permettant à l'utilisateur de créer un nouvel endroit favori
/// en saisissant un nom, en prenant/sélectionnant une photo et en obtenant sa géolocalisation.
class AjoutEndroit extends ConsumerStatefulWidget {
  const AjoutEndroit({super.key});

  @override
  ConsumerState<AjoutEndroit> createState() => _AjoutEndroitState();
}

class _AjoutEndroitState extends ConsumerState<AjoutEndroit> {
  // Clé globale pour la validation du formulaire
  final _formKey = GlobalKey<FormState>();

  // Contrôleur pour le champ texte du nom
  final _nomController = TextEditingController();

  // Variables d'état local
  File? _imageSelectionnee;
  double? _latitude;
  double? _longitude;
  String? _adresse;
  bool _enCoursEnregistrement = false;

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  /// Callback exécuté lors de la sélection d'une photo dans [ImagePrise]
  void _surPhotoSelectionnee(File image) {
    setState(() => _imageSelectionnee = image);
  }

  /// Callback exécuté lors de l'obtention des coordonnées GPS dans [LocalisationPrise]
  void _surLocalisationSelectionnee(
    double lat,
    double lng,
    String adresse,
  ) {
    setState(() {
      _latitude = lat;
      _longitude = lng;
      _adresse = adresse;
    });
  }

  /// Valide les champs et enregistre le lieu en base de données SQLite
  Future<void> _enregistrerEndroit() async {
    // 1. Validation du champ texte
    if (!_formKey.currentState!.validate()) return;

    // 2. Vérification de la présence d'une photo
    if (_imageSelectionnee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Veuillez ajouter une photo du lieu.'),
            ],
          ),
          backgroundColor: Colors.amber.shade900,
        ),
      );
      return;
    }

    setState(() => _enCoursEnregistrement = true);

    try {
      // 3. Appel du provider pour copie de l'image et insertion SQLite
      await ref.read(endroitsProvider.notifier).ajouterEndroit(
            nom: _nomController.text.trim(),
            imageTemporaire: _imageSelectionnee!,
            latitude: _latitude,
            longitude: _longitude,
            adresse: _adresse,
          );

      if (!mounted) return;

      // 4. Feedback utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text('${_nomController.text.trim()} enregistré en base locale !'),
            ],
          ),
          backgroundColor: Colors.teal.shade700,
        ),
      );

      // 5. Fermeture de l'écran d'ajout
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'enregistrement : $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _enCoursEnregistrement = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvel Endroit'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Section 1 : Intitulé du lieu ───
              _SectionTitre(
                icon: Icons.title_rounded,
                titre: "Nom de l'endroit",
                couleur: primary,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nomController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Ex: Jardin du Luxembourg, Café de Flore...',
                  prefixIcon: Icon(Icons.place_rounded),
                ),
                validator: (valeur) {
                  if (valeur == null || valeur.trim().isEmpty) {
                    return 'Veuillez saisir un nom pour cet endroit';
                  }
                  if (valeur.trim().length < 2) {
                    return 'Le nom doit contenir au moins 2 caractères';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ─── Section 2 : Sélection de Photo ───
              _SectionTitre(
                icon: Icons.photo_camera_rounded,
                titre: 'Photo du lieu',
                couleur: primary,
              ),
              const SizedBox(height: 10),
              ImagePrise(onPhotoSelectionnee: _surPhotoSelectionnee),
              const SizedBox(height: 24),

              // ─── Section 3 : Localisation GPS & Carte ───
              _SectionTitre(
                icon: Icons.map_rounded,
                titre: 'Localisation & Adresse',
                couleur: primary,
              ),
              const SizedBox(height: 10),
              LocalisationPrise(
                onLocalisationSelectionnee: _surLocalisationSelectionnee,
              ),
              const SizedBox(height: 32),

              // ─── Bouton de Validation & Sauvegarde ───
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _enCoursEnregistrement ? null : _enregistrerEndroit,
                  child: _enCoursEnregistrement
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded),
                            SizedBox(width: 10),
                            Text('Enregistrer cet endroit'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget réutilisable pour afficher un titre de section stylisé avec icône
class _SectionTitre extends StatelessWidget {
  const _SectionTitre({
    required this.icon,
    required this.titre,
    required this.couleur,
  });

  final IconData icon;
  final String titre;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: couleur),
        const SizedBox(width: 8),
        Text(
          titre,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}