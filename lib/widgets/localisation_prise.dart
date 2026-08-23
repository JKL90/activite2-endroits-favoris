// ═══════════════════════════════════════════════════════════════════
// lib/widgets/localisation_prise.dart - Sélecteur GPS & Géocodage moderne
// ═══════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocalisationPrise extends StatefulWidget {
  const LocalisationPrise({
    super.key,
    required this.onLocalisationSelectionnee,
  });

  final void Function(double lat, double lng, String adresse)
      onLocalisationSelectionnee;

  @override
  State<LocalisationPrise> createState() => _LocalisationPriseState();
}

class _LocalisationPriseState extends State<LocalisationPrise> {
  double? _latitude;
  double? _longitude;
  String? _adresse;
  bool _chargement = false;

  // Récupération automatique de la position GPS
  Future<void> _obtenirLocalisation() async {
    setState(() => _chargement = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() => _chargement = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission de localisation refusée.'),
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      // Géocodage inverse : conversion coordonnées -> adresse lisible
      try {
        final placemarks = await placemarkFromCoordinates(
          _latitude!,
          _longitude!,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final elements = [
            if (place.street != null && place.street!.isNotEmpty) place.street,
            if (place.locality != null && place.locality!.isNotEmpty) place.locality,
            if (place.country != null && place.country!.isNotEmpty) place.country,
          ];
          _adresse = elements.isNotEmpty
              ? elements.join(', ')
              : '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}';
        } else {
          _adresse = '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}';
        }
      } catch (_) {
        _adresse = '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}';
      }

      widget.onLocalisationSelectionnee(_latitude!, _longitude!, _adresse!);
    } catch (_) {
      // Coordonnées par défaut en cas d'impossibilité / émulateur
      _latitude = 37.4220;
      _longitude = -122.0840;
      _adresse = '1600 Amphitheatre Pkwy, Mountain View, CA, États-Unis';
      widget.onLocalisationSelectionnee(_latitude!, _longitude!, _adresse!);
    } finally {
      if (mounted) {
        setState(() => _chargement = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    if (_chargement) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: primary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Recherche du signal GPS...',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_latitude != null && _longitude != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withAlpha(40)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_latitude!, _longitude!),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('pos_choisie'),
                          position: LatLng(_latitude!, _longitude!),
                        ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filledTonal(
                        onPressed: _obtenirLocalisation,
                        icon: const Icon(Icons.my_location_rounded, size: 18),
                        tooltip: 'Actualiser la position',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _adresse ?? 'Position enregistrée',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Bouton moderne d'obtention de localisation
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withAlpha(70),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: InkWell(
        onTap: _obtenirLocalisation,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_searching_rounded, size: 28, color: primary),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Détecter ma position GPS',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ajoute la carte et l\'adresse au lieu',
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withAlpha(150),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}