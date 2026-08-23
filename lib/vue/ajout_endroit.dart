// ═══════════════════════════════════════════════════════════════════
// lib/vue/ajout_endroit.dart - Ajout d'un endroit avec persistance SQLite
// ═══════════════════════════════════════════════════════════════════
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/endroits_provider.dart';
import '../widgets/image_prise.dart';
import '../widgets/localisation_prise.dart';

class AjoutEndroit extends ConsumerStatefulWidget {
  const AjoutEndroit({super.key});

  @override
  ConsumerState<AjoutEndroit> createState() => _AjoutEndroitState();
}

class _AjoutEndroitState extends ConsumerState<AjoutEndroit> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
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

  void _surPhotoSelectionnee(File image) {
    setState(() => _imageSelectionnee = image);
  }

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

  // Validation et persistance SQLite
  Future<void> _enregistrerEndroit() async {
    if (!_formKey.currentState!.validate()) return;

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
      // Insertion SQLite + copie permanente de la photo
      await ref.read(endroitsProvider.notifier).ajouterEndroit(
            nom: _nomController.text.trim(),
            imageTemporaire: _imageSelectionnee!,
            latitude: _latitude,
            longitude: _longitude,
            adresse: _adresse,
          );

      if (!mounted) return;

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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

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
              // Section 1 : Informations
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

              // Section 2 : Photo
              _SectionTitre(
                icon: Icons.photo_camera_rounded,
                titre: 'Photo du lieu',
                couleur: primary,
              ),
              const SizedBox(height: 10),
              ImagePrise(onPhotoSelectionnee: _surPhotoSelectionnee),
              const SizedBox(height: 24),

              // Section 3 : Localisation GPS
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

              // Bouton Enregistrer
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