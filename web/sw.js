// Service worker minimal : coquille hors-ligne (app-shell), données toujours réseau.
const CACHE = "maree-v1";
const SHELL = ["./", "./index.html", "./manifest.webmanifest", "./icon-180.png", "./icon-512.png"];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const url = new URL(e.request.url);
  // Les appels API passent toujours par le réseau (jamais de cache).
  if (url.pathname.startsWith("/api/")) return;
  // App-shell : réseau d'abord, repli sur le cache hors-ligne.
  e.respondWith(
    fetch(e.request).then((r) => {
      if (e.request.method === "GET" && r.ok) {
        const clone = r.clone();
        caches.open(CACHE).then((c) => c.put(e.request, clone));
      }
      return r;
    }).catch(() => caches.match(e.request).then((m) => m || caches.match("./index.html")))
  );
});
