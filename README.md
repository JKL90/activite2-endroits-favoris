# 📍 Application Mobile : Mes Endroits Favoris (Activité 2)

Application mobile Flutter moderne, intuitive et complète permettant d'enregistrer, géolocaliser, cartographier et conserver localement ses lieux et souvenirs préférés avec **persistance SQLite locale** et **design Material 3**.

---

## 📑 Table des Matières

1. [Présentation du Projet](#-présentation-du-projet)
2. [Fonctionnalités Principales](#-fonctionnalités-principales)
3. [Architecture & Structure du Code](#-architecture--structure-du-code)
4. [Persistance des Données (SQLite & Fichiers)](#-persistance-des-données-sqlite--fichiers)
5. [Gestion d'État Réactive (Riverpod)](#-gestion-détat-réactive-riverpod)
6. [Design & Expérience Utilisateur (UI/UX)](#-design--expérience-utilisateur-uiux)
7. [Dépendances & Technologies](#-dépendances--technologies)
8. [Guide d'Installation & Lancement](#-guide-dinstallation--lancement)
9. [Aperçu des Écrans](#-aperçu-des-écrans)

---

## 🎯 Présentation du Projet

Ce projet a été réalisé dans le cadre de l'**Activité 2** du cours de développement mobile Flutter. L'application permet à l'utilisateur de :
- Créer une collection de lieux favoris avec photos et coordonnées GPS.
- Visualiser ses endroits sous forme de **Liste interactive** ou de **Grille de photos**.
- Consulter chaque lieu sur une carte **Google Maps** interactive avec adresse postale précise.
- Conserver l'intégralité des données et des fichiers photos de manière **pérenne hors-ligne** grâce à une base de données **SQLite locale** (`sqflite`).

---

## ✨ Fonctionnalités Principales

### 📸 1. Prise et Sélection de Photo
- **Double source au choix** : Prise de vue directe avec la **Caméra 📸** ou importation depuis la **Galerie 🖼️**.
- **Stockage permanent** : Copie automatique de la photo temporaire vers le dossier sécurisé de l'application (`path_provider`), garantissant la pérennité des fichiers après fermeture ou nettoyage du cache système.
- **Aperçu haute fidélité** avec possibilité de modifier ou remplacer la photo avant enregistrement.

### 📍 2. Géolocalisation GPS & Géocodage
- **Détection GPS haute précision** via le package `geolocator`.
- **Géocodage inverse automatique** (`geocoding`) : convertit instantanément la latitude/longitude en adresse postale lisible (rue, ville, pays).
- **Mini-carte interactive intégrée** dès la sélection pour confirmer l'emplacement visuel.

### 💾 3. Persistance SQLite Complète
- Base de données relationnelle locale (`sqflite`).
- Chargement asynchrone automatique au lancement de l'application.
- Opérations CRUD complètes (Création, Lecture, Mise à jour, Suppression).
- Nettoyage automatique des fichiers photos sur le disque lors de la suppression d'un endroit.

### 🔍 4. Recherche & Filtrage en Temps Réel
- Barre de recherche interactive intégrée à l'AppBar.
- Filtrage instantané multi-critères : recherche par nom de lieu ou par adresse/ville.

### 🔀 5. Modes d'Affichage & Gestes Intuitifs
- **Bascule Vue Liste / Vue Grille** (2 colonnes) en un clic.
- **Glisser pour supprimer (*Swipe to Delete*)** : suppression fluide avec geste tactile et SnackBar de confirmation.
- **Pull-to-Refresh** : actualisation manuelle de la base par glissement vers le bas.
- **Hero Animations** : transitions fluides des photos entre la liste et l'écran de détails.

---

## 🏗️ Architecture & Structure du Code

Le projet respecte une architecture modulaire et découplée, séparant clairement la logique métier, la persistance, la gestion d'état et les composants d'interface :

```text
lib/
│
├── main.dart                      # Point d'entrée, configuration MaterialApp & thèmes Material 3
│
├── modele/                        # Modèles de données métier
│   └── endroit.dart               # Modèle Endroit (attributs, UUID, toMap/fromMap SQLite)
│
├── services/                      # Services techniques & persistance
│   └── db_helper.dart             # Singleton SQLite (Création table, requêtes CRUD)
│
├── providers/                     # Gestion d'état réactive (Riverpod v2/v3)
│   └── endroits_provider.dart     # Notifier principal, synchronisation SQLite & filtre de recherche
│
├── vue/                           # Écrans principaux de l'application
│   ├── endroits_interface.dart    # Écran d'accueil (Recherche, bascule Liste/Grille, AppBar)
│   ├── ajout_endroit.dart         # Formulaire d'ajout d'un lieu (Validation, Photo, GPS)
│   └── endroit_detail.dart        # Page de détails (SliverAppBar, Carte Google Maps, Métadonnées)
│
└── widgets/                       # Composants d'interface réutilisables
    ├── endroits_list.dart         # Rendu des cartes en mode Liste et Grille
    ├── image_prise.dart           # Sélecteur de photo (Caméra / Galerie avec modal)
    └── localisation_prise.dart    # Sélecteur GPS avec mini-carte et géocodage
```

---

## 💾 Persistance des Données (SQLite & Fichiers)

### 1. Schéma de la Table SQLite (`endroits_favoris.db`)
La persistance est assurée par la classe Singleton `DatabaseHelper` dans [`lib/services/db_helper.dart`](lib/services/db_helper.dart) :

```sql
CREATE TABLE endroits (
  id TEXT PRIMARY KEY,          -- Identifiant unique UUID v4
  nom TEXT NOT NULL,            -- Nom / Libellé de l'endroit
  image_path TEXT NOT NULL,     -- Chemin physique absolu de la photo
  latitude REAL,                -- Coordonnée GPS Latitude (optionnelle)
  longitude REAL,               -- Coordonnée GPS Longitude (optionnelle)
  adresse TEXT,                 -- Adresse textuelle formatée
  date_creation TEXT NOT NULL   -- Horodatage de création (ISO-8601)
);
```

### 2. Stratégie de Stockage des Fichiers Photos
Les photos prises par l'appareil photo ou sélectionnées dans la galerie sont initialement stockées dans le cache temporaire du système. Pour éviter toute suppression inopinée par l'OS :
1. `path_provider` récupère le répertoire interne permanent de l'application (`getApplicationDocumentsDirectory()`).
2. Le fichier est copié avec un nom unique : `${timestamp}.jpg`.
3. Le chemin absolu définitif est sauvegardé dans SQLite.
4. Lors de la suppression d'un endroit, le fichier sur le disque est automatiquement supprimé pour libérer l'espace mémoire.

---

## ⚡ Gestion d'État Réactive (Riverpod)

L'application utilise **Flutter Riverpod (v2/v3)** pour une gestion d'état unidirectionnelle et testable :

- **`ProviderScope`** : Enveloppe racine de l'arbre de widgets dans [`lib/main.dart`](lib/main.dart).
- **`endroitsProvider`** (`NotifierProvider<EndroitsNotifier, List<Endroit>>`) :
  - Charge automatiquement les données depuis SQLite lors de sa création.
  - Déclenche la reconstruction des widgets uniquement lorsque la liste change.
- **`rechercheQueryProvider`** (`NotifierProvider<RechercheQueryNotifier, String>`) : Gère la saisie de recherche textuelle.
- **`endroitsFiltresProvider`** (`Provider<List<Endroit>>`) : Provider dérivé qui recalcule automatiquement la sous-liste filtrée en temps réel.

---

## 🎨 Design & Expérience Utilisateur (UI/UX)

L'application implémente les dernières directives **Material Design 3** :
- **Palette de couleurs harmonieuse** : Teal émeraude profond (`#00897B`) avec variations lumineuses.
- **Mode Sombre & Mode Clair** : Adaptation automatique selon les préférences du système d'exploitation de l'utilisateur.
- **SliverAppBar & Dégradés** : En-tête rétractable et immersif sur la page de détails.
- **Micro-interactions & Feedbacks** : Indicateurs de progression, SnackBars flottantes avec icônes de statut et dialogues de confirmation avant suppression.

---

## 📦 Dépendances & Technologies

| Package | Version | Rôle & Justification |
| :--- | :--- | :--- |
| **`flutter_riverpod`** | `^3.3.1` | Gestion d'état réactive moderne et robuste |
| **`sqflite`** | `^2.4.2` | Moteur de base de données relationnelle SQLite locale |
| **`path_provider`** | `^2.1.5` | Accès aux répertoires de stockage permanent (documents) |
| **`path`** | `^1.9.1` | Manipulation portable des chemins de fichiers et extensions |
| **`google_maps_flutter`** | `^2.14.2` | Intégration et affichage des cartes Google Maps |
| **`geolocator`** | `^14.0.2` | Récupération des coordonnées GPS de l'appareil |
| **`geocoding`** | `^4.0.0` | Traduction des coordonnées géographiques en adresse lisible |
| **`image_picker`** | `^1.2.1` | Prise de photos via la caméra et sélection dans la galerie |
| **`uuid`** | `^4.3.3` | Génération d'identifiants uniques universels pour chaque lieu |

---

## 🚀 Guide d'Installation & Lancement

### 1. Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version 3.47+ recommandée)
- [Android Studio](https://developer.android.com/studio) avec émulateur configuré ou appareil Android physique avec débogage USB activé.

### 2. Cloner le Projet
```bash
git clone https://github.com/JKL90/activite2-endroits-favoris.git
cd activite2-endroits-favoris
```

### 3. Récupérer les Dépendances
```bash
flutter pub get
```

### 4. Lancer l'Application
```bash
flutter run --android-skip-build-dependency-validation
```

*Pour cibler un émulateur spécifique :*
```bash
flutter run -d emulator-5554 --android-skip-build-dependency-validation
```

---

## 📱 Aperçu des Écrans

- **Accueil & Liste des Endroits** : Affichage des lieux enregistrés avec photo, intitulé, badge GPS, adresse, barre de recherche et bouton d'ajout flottant.
- **Bascule Vue Grille** : Présentation visuelle en grille photo 2 colonnes avec indicateurs de géolocalisation.
- **Formulaire d'Ajout** : Saisie du nom, sélecteur Caméra/Galerie, détection GPS avec aperçu cartographique.
- **Détails du Lieu** : Image grand format rétractable, fiche complète des métadonnées, date d'enregistrement, coordonnées et carte Google Maps interactive.

---

## 👨‍💻 Auteur & Informations Académiques

- **Projet** : Activité 2 - Application des Endroits Favoris
- **Dépôt GitHub** : [https://github.com/JKL90/activite2-endroits-favoris](https://github.com/JKL90/activite2-endroits-favoris)
- **Framework** : Flutter (Dart)
- **Persistance** : SQLite (`sqflite`)
