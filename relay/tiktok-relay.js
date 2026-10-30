// UNGEPRÜFT: Verbindet sich mit einem TikTok-Live und schickt Ereignisse per WebSocket ans Spiel.
// Benötigt Node.js (nodejs.org) und:  npm install tiktok-live-connector ws
// Start:  node tiktok-relay.js DEIN_TIKTOK_NAME
// Das Spiel dann öffnen mit:  https://mansory63.github.io/battle-chibi-web/?live=1&ws=ws://127.0.0.1:8765
// Hinweis: tiktok-live-connector ist ein inoffizielles Werkzeug, TikTok kann es jederzeit blockieren.
const { WebcastPushConnection } = require('tiktok-live-connector');
const { WebSocketServer } = require('ws');
const https = require('https');
const http = require('http');
const user = process.argv[2];
if (!user) { console.log('Bitte TikTok-Namen angeben: node tiktok-relay.js NAME'); process.exit(1); }
// Nur lokal erreichbar (127.0.0.1), damit andere Geräte im Netzwerk nicht mitlesen können
const wss = new WebSocketServer({ host: '127.0.0.1', port: 8765 });
const send = (o) => { const s = JSON.stringify(o); wss.clients.forEach(c => c.readyState === 1 && c.send(s)); };
// Profilbilder: einmal pro Zuschauer laden, als Base64 an das Spiel schicken (nur lokal auf dem PC, daher kein CORS-Problem)
const avatarSent = new Set();
const fetchAvatar = (url) => new Promise((resolve) => {
  const lib = url.startsWith('https') ? https : http;
  const req = lib.get(url, { timeout: 4000 }, (res) => {
    if (res.statusCode !== 200) return resolve(null);
    const chunks = []; let size = 0;
    res.on('data', (c) => { size += c.length; if (size > 300000) { res.destroy(); return resolve(null); } chunks.push(c); });
    res.on('end', () => {
      const type = (res.headers['content-type'] || 'image/jpeg').split(';')[0];
      resolve('data:' + type + ';base64,' + Buffer.concat(chunks).toString('base64'));
    });
  });
  // Hängt der Download, wird der Avatar übersprungen statt das Ereignis zu verzögern
  req.on('timeout', () => { req.destroy(); resolve(null); });
  req.on('error', () => resolve(null));
});
const withAvatar = async (d, payload) => {
  const url = d.profilePictureUrl || (d.user && d.user.profilePictureUrl);
  if (url && !avatarSent.has(d.nickname)) {
    avatarSent.add(d.nickname);
    const img = await fetchAvatar(Array.isArray(url) ? url[0] : url);
    if (img) payload.avatar = img;
  }
  return payload;
};
const tt = new WebcastPushConnection(user);
tt.connect().then(() => console.log('Verbunden mit', user)).catch(e => console.log('Fehler:', e));
tt.on('chat', async d => send({ event: 'chat', data: await withAvatar(d, { nickname: d.nickname, comment: d.comment }) }));
tt.on('like', async d => send({ event: 'like', data: await withAvatar(d, { nickname: d.nickname, likeCount: d.likeCount }) }));
tt.on('follow', async d => send({ event: 'follow', data: await withAvatar(d, { nickname: d.nickname }) }));
tt.on('share', async d => send({ event: 'share', data: await withAvatar(d, { nickname: d.nickname }) }));
tt.on('gift', d => {
  // Serien-Geschenke erst am Ende der Serie zählen
  if (d.giftType === 1 && !d.repeatEnd) return;
  withAvatar(d, { nickname: d.nickname, giftName: d.giftName, diamondCount: d.diamondCount, repeatCount: d.repeatCount || 1 }).then(p => send({ event: 'gift', data: p }));
});
console.log('WebSocket läuft auf ws://127.0.0.1:8765');
