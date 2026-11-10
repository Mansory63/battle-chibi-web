// Ausschalter für den alten Offline-Speicher: Früher wurde das Spiel als installierbare App mit Service Worker
// veröffentlicht. Geräte, die ihn noch haben, bekamen dadurch dauerhaft eine alte Version. Diese Datei ersetzt ihn,
// löscht alle gespeicherten Spieldateien, meldet sich selbst ab und lädt offene Seiten neu.
self.addEventListener('install', function () { self.skipWaiting(); });
self.addEventListener('activate', function (event) {
  event.waitUntil((async function () {
    try {
      var keys = await caches.keys();
      await Promise.all(keys.map(function (k) { return caches.delete(k); }));
    } catch (e) {}
    try { await self.registration.unregister(); } catch (e) {}
    try {
      var list = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
      list.forEach(function (c) { try { c.navigate(c.url); } catch (e) {} });
    } catch (e) {}
  })());
});
// Bis zur Abmeldung nichts mehr aus dem Speicher liefern: alles direkt aus dem Netz
self.addEventListener('fetch', function (event) { event.respondWith(fetch(event.request, { cache: 'no-store' })); });
