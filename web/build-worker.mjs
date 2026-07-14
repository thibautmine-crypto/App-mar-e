// Génère ../worker.js à partir des fichiers de web/ (assets embarqués en base64/texte).
// Usage : node web/build-worker.mjs
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");

const textAssets = {
  "/index.html": ["index.html", "text/html; charset=utf-8"],
  "/manifest.webmanifest": ["manifest.webmanifest", "application/manifest+json"],
  "/sw.js": ["sw.js", "text/javascript; charset=utf-8"],
};
const binAssets = {
  "/icon-180.png": ["icon-180.png", "image/png"],
  "/icon-512.png": ["icon-512.png", "image/png"],
  "/icon-1024.png": ["icon-1024.png", "image/png"],
};

const assets = {};
for (const [route, [file, type]] of Object.entries(textAssets)) {
  assets[route] = { type, body: readFileSync(join(here, file), "utf8"), b64: false };
}
for (const [route, [file, type]] of Object.entries(binAssets)) {
  assets[route] = { type, body: readFileSync(join(here, file)).toString("base64"), b64: true };
}

const worker = `// ⚙️ Cloudflare Worker — sert l'app Marées ET relaie l'API (même origine → pas de CORS).
// ⚠️ Fichier GÉNÉRÉ par web/build-worker.mjs — ne pas éditer à la main.
// Déploiement : dash.cloudflare.com → Workers & Pages → Create Worker → coller ce fichier → Deploy.

const ASSETS = ${JSON.stringify(assets)};

const MC_SEARCH = "https://ws.meteoconsult.fr/meteoconsultmarine/android/100/fr/v30/recherche.php";
const MC_SPOT = "https://ws.meteoconsult.fr/meteoconsultmarine/androidtab/115/fr/v30/previsionsSpot.php";
const UA = "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Mobile Safari/537.36";

function decodeB64(b64) {
  const bin = atob(b64); const arr = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  return arr;
}

async function proxy(upstream) {
  const r = await fetch(upstream, { headers: { "User-Agent": UA, "Accept": "application/json" } });
  const body = await r.text();
  return new Response(body, {
    status: r.status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "access-control-allow-origin": "*",
      "cache-control": "public, max-age=300",
    },
  });
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname;

    // API : recherche de ports
    if (path === "/api/search") {
      const q = url.searchParams.get("q") || "";
      return proxy(MC_SEARCH + "?rech=" + encodeURIComponent(q));
    }
    // API : prévisions de marées
    if (path === "/api/tides") {
      const lat = url.searchParams.get("lat"), lon = url.searchParams.get("lon");
      return proxy(MC_SPOT + "?lat=" + encodeURIComponent(lat) + "&lon=" + encodeURIComponent(lon));
    }

    // Assets statiques (index à la racine)
    const key = path === "/" ? "/index.html" : path;
    const a = ASSETS[key];
    if (a) {
      const body = a.b64 ? decodeB64(a.body) : a.body;
      return new Response(body, {
        headers: { "content-type": a.type, "cache-control": "public, max-age=3600" },
      });
    }
    return new Response("Not found", { status: 404 });
  },
};
`;

writeFileSync(join(root, "worker.js"), worker);
console.log("worker.js généré (" + worker.length + " octets)");
