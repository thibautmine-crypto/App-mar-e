# 🌊 Marées — App iOS + Widget

Application iOS **SwiftUI** avec **widget WidgetKit** affichant l'horaire des marées
(pleines / basses mers, hauteur d'eau, coefficient) pour plus de 150 ports français.
UI soignée façon Apple : dégradés océan, cartes en verre dépoli, Swift Charts, mode sombre.

Les données proviennent de l'**API publique Météo Consult Marine** (source SHOM),
la même que celle utilisée par le projet Home Assistant
[`saniho/apiMareeInfo`](https://github.com/saniho/apiMareeInfo). **Aucune clé API requise.**

---

## ✨ Fonctionnalités

- **Écran principal** : hauteur d'eau instantanée, marée montante/descendante, prochaine marée
  avec compte à rebours, coefficient, courbe de marée sur 12 h, marées du jour + 5 jours suivants.
- **Widget écran d'accueil** (petit / moyen / grand) :
  - *Petit* : prochaine marée (type, heure, hauteur) + coefficient.
  - *Moyen* : état courant, hauteur, coefficient et les marées du jour.
  - *Grand* : détail complet de la journée.
- **Recherche de port** avec sélection persistée et partagée avec le widget (App Group).
- **Rafraîchissement** par tirer-pour-actualiser, timeline widget toutes les ~3 h.

---

## 🧱 Architecture

```
Sources/
├── Shared/                  # Code partagé app + widget
│   ├── Models.swift         # Port, Tide, TideType, réponses JSON, parsing ISO 8601
│   ├── MeteoConsultAPI.swift# Client réseau (recherche + prévisions)
│   ├── TideMath.swift       # Interpolation cosinus, prochaine marée, courbe, formatage
│   └── SharedStore.swift    # Port sélectionné via App Group (app ↔ widget)
├── App/                     # Cible application
│   ├── MareeApp.swift       # @main + RootView
│   ├── TideViewModel.swift  # État observable, chargement, valeurs dérivées
│   ├── TideDashboardView.swift
│   ├── TideChartView.swift  # Courbe Swift Charts
│   ├── PortSearchView.swift # Recherche (debounce)
│   ├── Theme.swift          # Palette + carte en verre
│   ├── Info.plist / App.entitlements
│   └── Assets.xcassets      # Icône + couleur d'accent
└── Widget/                  # Cible extension WidgetKit
    ├── MareeWidget.swift     # Widget + WidgetBundle (@main)
    ├── Provider.swift        # TimelineProvider
    ├── WidgetViews.swift     # Vues small / medium / large
    └── Info.plist / Widget.entitlements
```

Le projet Xcode est **généré par [XcodeGen](https://github.com/yonyz/XcodeGen)** à partir de
`project.yml` (le `.xcodeproj` n'est pas versionné pour éviter les conflits).

---

## 🚀 Installation

Prérequis : **macOS + Xcode 15+** (iOS 17 minimum).

```bash
# 1. Installer XcodeGen (une seule fois)
brew install xcodegen

# 2. Générer le projet Xcode
cd App-mar-e
xcodegen generate

# 3. Ouvrir dans Xcode
open Maree.xcodeproj
```

Dans Xcode :

1. Sélectionnez la cible **Maree** → onglet **Signing & Capabilities** → choisissez votre
   **Team** Apple Developer. Faites de même pour la cible **MareeWidgetExtension**.
2. Vérifiez que la capability **App Groups** est activée sur les deux cibles avec le
   **même** groupe : `group.com.thibautmine.appmaree`
   (modifiable dans `SharedStore.swift` et les fichiers `*.entitlements`).
3. Lancez sur simulateur ou appareil (⌘R).
4. Ajoutez le widget : appui long sur l'écran d'accueil → **+** → **Marées**.

> 💡 Le bundle identifier par défaut est `com.thibautmine.appmaree`. Changez-le
> (dans `project.yml`, les `.entitlements` et l'App Group) s'il est déjà pris.

---

## 🔌 API utilisée (Météo Consult Marine)

Aucune authentification. Un `User-Agent` de type navigateur est envoyé.

**Recherche de ports**
```
GET https://ws.meteoconsult.fr/meteoconsultmarine/android/100/fr/v30/recherche.php?rech=saint-malo
→ { "contenu": [ { "id", "nom", "lat", "lon", "time_zone", "presence_maree", … } ] }
```

**Prévisions de marées (15 jours)**
```
GET https://ws.meteoconsult.fr/meteoconsultmarine/androidtab/115/fr/v30/previsionsSpot.php?lat=48.6539&lon=-2.01563
→ { "contenu": { "marees": [
      { "datetime", "lieu",
        "etales": [ { "datetime", "type_etale": "BM"|"PM", "hauteur": 10.76, "coef": 76 } ] }
   ] } }
```

`type_etale` : `PM` = pleine mer (marée haute), `BM` = basse mer. `coef` = coefficient de marée
(présent sur les pleines mers). L'API ne fournit que les **extremums** ; la hauteur d'eau
continue et la courbe sont interpolées côté app (interpolation cosinus dans `TideMath`).

---

## 📄 Crédits & licence des données

Hauteurs d'eau diffusées par Météo Consult Marine, calculées à partir de composantes
harmoniques **IFREMER / PREVIMER** (données SHOM). Usage à titre indicatif — ne pas
utiliser pour la navigation. Ce dépôt est fourni à titre éducatif.
