# 🌊 Marées — web app (PWA), à mettre sur l'iPhone en 5 min

Web app style Apple des horaires de marées (hauteur d'eau, pleines/basses mers,
coefficient, courbe), installable sur l'écran d'accueil comme une vraie app.
Données : **Météo Consult Marine** (source SHOM), sans clé API.

> L'API ne renvoie pas d'en-têtes CORS : un site statique ne peut pas l'appeler
> directement depuis le navigateur. La solution ci-dessous utilise un petit
> **Cloudflare Worker gratuit** qui sert l'app **et** relaie l'API sur le même
> domaine → aucun problème de CORS, aucun serveur à gérer.

## ⚡️ Déploiement en un clic

[![Deploy to Cloudflare](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/thibautmine-crypto/App-mar-e)

Ce bouton clone le dépôt sur ton compte, le connecte à Cloudflare et déploie
`worker.js` automatiquement (grâce à `wrangler.toml` à la racine). À chaque
`git push`, Cloudflare redéploie tout seul → les deux systèmes sont interfacés.

## 🔗 Connexion manuelle GitHub → Cloudflare (CI/CD)

1. Dashboard Cloudflare → **Workers & Pages** → **Create** → onglet **Connect to Git**.
2. Choisis ce dépôt et la branche.
3. Laisse la commande de déploiement par défaut : `npx wrangler deploy`
   (la config `wrangler.toml` fait le reste).
4. **Save and Deploy**. Chaque push sur la branche redéploie automatiquement.

## 🚀 Déploiement (Cloudflare Worker, gratuit)

1. Crée un compte sur <https://dash.cloudflare.com> (gratuit).
2. **Workers & Pages** → **Create** → **Create Worker** → **Deploy** (le worker par défaut).
3. **Edit code** : efface tout, puis colle le contenu de
   [`worker.js`](../worker.js) (à la racine du dépôt) → **Deploy**.
4. Tu obtiens une URL du type `https://marees.<ton-compte>.workers.dev`.

C'est tout : l'app est en ligne.

> `worker.js` est **généré** à partir de ce dossier `web/`.
> Pour le régénérer après une modif : `node web/build-worker.mjs`.

## 📲 Ajouter à l'écran d'accueil (iPhone)

1. Ouvre l'URL du Worker dans **Safari**.
2. Bouton **Partager** (carré avec flèche) → **Sur l'écran d'accueil**.
3. **Ajouter**. L'icône « Marées » apparaît, l'app s'ouvre en plein écran.

## Fonctionnalités

- Hauteur d'eau instantanée (interpolée) + marée montante / descendante.
- Prochaine marée avec compte à rebours et coefficient.
- Courbe de marée (fenêtre −3 h → +9 h) avec repère « maintenant ».
- Marées du jour + 5 jours suivants.
- Recherche de port (appui sur le nom du port en haut). Choix mémorisé.
- Fonctionne hors-ligne (coquille en cache) ; les marées se rafraîchissent au réseau.

## Développement local

```bash
node web/build-worker.mjs        # génère worker.js
# puis teste worker.js avec wrangler, ou sers web/ avec ton propre proxy /api
```

Le front lit `/api/search?q=` et `/api/tides?lat=&lon=` (mêmes réponses que
Météo Consult). Pour pointer ailleurs, définir `window.MAREE_API_BASE` avant le script.
