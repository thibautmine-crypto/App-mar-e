// Variables used by Scriptable.
// icon-color: deep-blue; icon-glyph: water;
//
// 🌊 Widget Marées — pour l'app Scriptable (iOS), SANS Xcode ni Mac.
// Données : API publique Météo Consult Marine (source SHOM), sans clé.
//
// PARAMÈTRE DU WIDGET (appui long sur le widget → Modifier le widget → Paramètre) :
//   • un nom de port          → ex.  Brest
//   • ou "lat,lon,Nom"        → ex.  48.6539,-2.01563,Saint-Malo
//   • vide                    → Saint-Malo par défaut
//
// Familles supportées : petit / moyen / grand.

// ---------------------------------------------------------------- Réglages

const DEFAULT_PORT = { nom: "Saint-Malo", lat: 48.6539, lon: -2.01563 };

const UA =
  "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) " +
  "Chrome/146.0.0.0 Mobile Safari/537.36";

const COLORS = {
  top: new Color("#0a6ab0"),
  bottom: new Color("#04264c"),
  high: new Color("#66d9ff"),
  low: new Color("#fbe6b4"),
  white: Color.white(),
  faint: new Color("#ffffff", 0.75),
  fainter: new Color("#ffffff", 0.55),
};

// ---------------------------------------------------------------- Réseau

async function getJSON(url) {
  const req = new Request(url);
  req.headers = { "User-Agent": UA };
  req.timeoutInterval = 20;
  return await req.loadJSON();
}

async function searchPort(query) {
  const url =
    "https://ws.meteoconsult.fr/meteoconsultmarine/android/100/fr/v30/recherche.php?rech=" +
    encodeURIComponent(query);
  const json = await getJSON(url);
  const list = (json.contenu || []).filter((p) => p.presence_maree !== false);
  if (!list.length) return null;
  const p = list[0];
  return { nom: p.nom, lat: p.lat, lon: p.lon };
}

async function fetchTides(lat, lon) {
  const url =
    "https://ws.meteoconsult.fr/meteoconsultmarine/androidtab/115/fr/v30/previsionsSpot.php?lat=" +
    lat + "&lon=" + lon;
  const json = await getJSON(url);
  const days = (json.contenu && json.contenu.marees) || [];
  const tides = [];
  for (const d of days) for (const e of d.etales || []) {
    tides.push({
      date: new Date(e.datetime),              // instant réel (offset géré)
      hhmm: String(e.datetime).slice(11, 16),  // heure locale du port
      type: e.type_etale,                      // "PM" (haute) / "BM" (basse)
      hauteur: e.hauteur,
      coef: e.coef,
    });
  }
  tides.sort((a, b) => a.date - b.date);
  return tides;
}

// ---------------------------------------------------------------- Calculs

function surrounding(now, tides) {
  let prev = null, next = null;
  for (const t of tides) {
    if (t.date <= now) prev = t;
    else { next = t; break; }
  }
  return { prev, next };
}

// Hauteur d'eau interpolée (cosinus) entre deux extremums.
function heightNow(now, tides) {
  const { prev, next } = surrounding(now, tides);
  if (!prev || !next) return null;
  const span = next.date - prev.date;
  if (span <= 0) return prev.hauteur;
  const t = (now - prev.date) / span;
  const phase = (1 - Math.cos(Math.PI * t)) / 2;
  return prev.hauteur + (next.hauteur - prev.hauteur) * phase;
}

function coefficient(now, tides) {
  const { next } = surrounding(now, tides);
  if (next && next.type === "PM" && next.coef != null) return next.coef;
  const highs = tides.filter((t) => t.type === "PM" && t.coef != null);
  if (!highs.length) return null;
  highs.sort((a, b) => Math.abs(a.date - now) - Math.abs(b.date - now));
  return highs[0].coef;
}

function typeLabel(type) { return type === "PM" ? "Pleine mer" : "Basse mer"; }
function typeSymbol(type) { return type === "PM" ? "arrow.up.to.line" : "arrow.down.to.line"; }
function typeColor(type) { return type === "PM" ? COLORS.high : COLORS.low; }
function metres(h) { return h == null ? "—" : h.toFixed(2).replace(".", ",") + " m"; }

function durationUntil(date, now) {
  const s = Math.max(0, Math.floor((date - now) / 1000));
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
  return h > 0 ? `${h} h ${String(m).padStart(2, "0")}` : `${m} min`;
}

function todayTides(now, tides) {
  return tides.filter(
    (t) =>
      t.date.getFullYear() === now.getFullYear() &&
      t.date.getMonth() === now.getMonth() &&
      t.date.getDate() === now.getDate()
  );
}

// ---------------------------------------------------------------- UI (helpers)

// Ajoute un SF Symbol coloré (Scriptable colore les symboles via tintColor).
function addSymbol(stack, name, color, size) {
  const img = stack.addImage(SFSymbol.named(name).image);
  img.imageSize = new Size(size, size);
  img.tintColor = color;
  return img;
}

function resolvePortParam(param) {
  if (!param || !param.trim()) return { kind: "port", port: DEFAULT_PORT };
  const parts = param.split(",").map((s) => s.trim());
  const lat = parseFloat(parts[0]), lon = parseFloat(parts[1]);
  if (parts.length >= 2 && !isNaN(lat) && !isNaN(lon)) {
    return { kind: "port", port: { nom: parts[2] || "Marées", lat, lon } };
  }
  return { kind: "search", query: param.trim() };
}

function header(stack, port) {
  const h = stack.addStack();
  h.centerAlignContent();
  addSymbol(h, "water.waves", COLORS.faint, 12);
  h.addSpacer(4);
  const t = h.addText(port.nom);
  t.font = Font.semiboldSystemFont(11);
  t.textColor = COLORS.faint;
  t.lineLimit = 1;
}

function tideLine(stack, t, now, size) {
  const line = stack.addStack();
  line.centerAlignContent();
  addSymbol(line, typeSymbol(t.type), typeColor(t.type), size);
  line.addSpacer(6);
  const lab = line.addText(t.type);
  lab.font = Font.mediumSystemFont(size);
  lab.textColor = COLORS.faint;
  line.addSpacer();
  const ht = line.addText(metres(t.hauteur));
  ht.font = Font.systemFont(size - 1);
  ht.textColor = COLORS.fainter;
  line.addSpacer(8);
  const tm = line.addText(t.hhmm);
  tm.font = Font.semiboldRoundedSystemFont(size);
  tm.textColor = COLORS.white;
  if (t.date < now) { lab.textOpacity = 0.5; ht.textOpacity = 0.5; tm.textOpacity = 0.5; }
}

// ---------------------------------------------------------------- Rendu

async function buildWidget() {
  const family = config.widgetFamily || "medium";
  const now = new Date();

  // Résolution du port (paramètre du widget)
  const resolved = resolvePortParam(args.widgetParameter);
  let port = DEFAULT_PORT;
  try {
    port = resolved.kind === "search"
      ? (await searchPort(resolved.query)) || DEFAULT_PORT
      : resolved.port;
  } catch (e) { /* on garde le port par défaut */ }

  const w = new ListWidget();
  const g = new LinearGradient();
  g.colors = [COLORS.top, COLORS.bottom];
  g.locations = [0, 1];
  g.startPoint = new Point(0, 0);
  g.endPoint = new Point(1, 1);
  w.backgroundGradient = g;
  w.setPadding(14, 16, 14, 16);
  w.refreshAfterDate = new Date(Date.now() + 30 * 60 * 1000);

  let tides = [];
  try { tides = await fetchTides(port.lat, port.lon); }
  catch (e) { renderError(w, port); return w; }
  if (!tides.length) { renderError(w, port); return w; }

  if (family === "small") renderSmall(w, port, tides, now);
  else if (family === "large") renderLarge(w, port, tides, now);
  else renderMedium(w, port, tides, now);

  return w;
}

function renderSmall(w, port, tides, now) {
  header(w, port);
  w.addSpacer();

  const { next } = surrounding(now, tides);
  if (next) {
    addSymbol(w, typeSymbol(next.type), typeColor(next.type), 22);
    w.addSpacer(2);
    const lbl = w.addText(typeLabel(next.type));
    lbl.font = Font.mediumSystemFont(12);
    lbl.textColor = COLORS.faint;
    const time = w.addText(next.hhmm);
    time.font = Font.boldRoundedSystemFont(30);
    time.textColor = COLORS.white;
    const ht = w.addText(metres(next.hauteur));
    ht.font = Font.systemFont(11);
    ht.textColor = COLORS.fainter;
  }

  w.addSpacer();
  const coef = coefficient(now, tides);
  if (coef != null) {
    const c = w.addText("Coef. " + coef);
    c.font = Font.semiboldSystemFont(11);
    c.textColor = COLORS.faint;
  }
}

function renderMedium(w, port, tides, now) {
  const row = w.addStack();

  // Colonne gauche : état courant
  const left = row.addStack();
  left.layoutVertically();
  header(left, port);
  left.addSpacer();

  const { next } = surrounding(now, tides);
  const h = heightNow(now, tides);
  if (next) {
    const tag = left.addText(next.type === "PM" ? "↑ Montante" : "↓ Descendante");
    tag.font = Font.mediumSystemFont(11);
    tag.textColor = COLORS.faint;
  }
  const big = left.addText(metres(h));
  big.font = Font.boldRoundedSystemFont(30);
  big.textColor = COLORS.white;
  if (next) {
    const nx = left.addText(`${next.type} à ${next.hhmm} · ${durationUntil(next.date, now)}`);
    nx.font = Font.mediumSystemFont(11);
    nx.textColor = COLORS.faint;
  }

  row.addSpacer(14);

  // Colonne droite : coef + marées du jour
  const right = row.addStack();
  right.layoutVertically();
  const coef = coefficient(now, tides);
  if (coef != null) {
    const c = right.addText("Coef. " + coef);
    c.font = Font.boldSystemFont(13);
    c.textColor = COLORS.white;
    right.addSpacer(4);
  }
  for (const t of todayTides(now, tides).slice(0, 4)) {
    tideLine(right, t, now, 11);
  }
  right.addSpacer();
}

function renderLarge(w, port, tides, now) {
  const top = w.addStack();
  top.centerAlignContent();
  header(top, port);
  top.addSpacer();
  const coef = coefficient(now, tides);
  if (coef != null) {
    const c = top.addText("Coef. " + coef);
    c.font = Font.boldSystemFont(13);
    c.textColor = COLORS.white;
  }
  w.addSpacer(8);

  const h = heightNow(now, tides);
  const { next } = surrounding(now, tides);
  const big = w.addText(metres(h) + (next ? (next.type === "PM" ? "  ↑" : "  ↓") : ""));
  big.font = Font.boldRoundedSystemFont(34);
  big.textColor = COLORS.white;
  w.addSpacer(10);

  for (const t of todayTides(now, tides)) {
    tideLine(w, t, now, 14);
    w.addSpacer(4);
  }
  w.addSpacer();
}

function renderError(w, port) {
  header(w, port);
  w.addSpacer();
  addSymbol(w, "wifi.exclamationmark", COLORS.faint, 24);
  w.addSpacer(6);
  const t = w.addText("Marées indisponibles");
  t.font = Font.mediumSystemFont(12);
  t.textColor = COLORS.faint;
  w.addSpacer();
}

// ---------------------------------------------------------------- Entrée

const widget = await buildWidget();
if (config.runsInWidget) {
  Script.setWidget(widget);
} else {
  await widget.presentMedium(); // aperçu quand on lance le script dans l'app
}
Script.complete();
