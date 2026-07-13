# 🌊 Widget Marées pour Scriptable — sans Xcode ni Mac

Un **vrai widget écran d'accueil iOS** des marées, installable **directement depuis l'iPhone**,
sans ordinateur. Il utilise l'app gratuite **Scriptable** qui exécute du JavaScript et sait
créer de vrais widgets. Mêmes données que l'app native (Météo Consult Marine / SHOM, sans clé).

> Alternative « zéro Xcode » à l'app SwiftUI de ce dépôt. Pour l'app complète + widget natif,
> voir le [README principal](../README.md).

## Installation (5 min, sur l'iPhone)

1. Installe **Scriptable** depuis l'App Store (gratuit).
2. Ouvre le fichier [`Marees.js`](./Marees.js), copie **tout** son contenu.
   *(Sur GitHub : bouton « Raw » puis tout sélectionner / copier.)*
3. Dans Scriptable : bouton **＋** (en haut à droite) → colle le code →
   renomme le script en **« Marées »** (icône clé à molette en bas).
4. Reviens à l'écran d'accueil → appui long → **＋** → cherche **Scriptable** →
   choisis la taille (petit / moyen / grand) → **Ajouter le widget**.
5. Appui long sur le widget → **Modifier le widget** :
   - **Script** : `Marées`
   - **Quand interagir** : `Exécuter le script`
   - **Paramètre** : ton port (voir ci-dessous)

## Choisir le port (champ « Paramètre »)

| Paramètre | Résultat |
|---|---|
| *(vide)* | Saint-Malo par défaut |
| `Brest` | recherche le port par son nom |
| `La Rochelle` | idem |
| `48.6539,-2.01563,Saint-Malo` | coordonnées précises + nom affiché |

Astuce : pour placer plusieurs ports, ajoute plusieurs widgets Scriptable avec des
paramètres différents.

## Ce qu'affiche le widget

- **Petit** : prochaine marée (type, heure, hauteur) + coefficient.
- **Moyen** : hauteur d'eau instantanée, marée montante/descendante, prochaine marée,
  coefficient et les marées du jour.
- **Grand** : détail complet de la journée.

Rafraîchissement automatique environ toutes les 30 min (iOS décide du moment exact).

## Aperçu / debug

Ouvre le script dans Scriptable et appuie sur **▶︎** : il s'affiche en taille moyenne.
