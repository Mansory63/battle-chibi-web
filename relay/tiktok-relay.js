// UNGEPRÜFT: Verbindet sich mit einem TikTok-Live und schickt Ereignisse per WebSocket ans Spiel.
// Benötigt Node.js (nodejs.org) und:  npm install tiktok-live-connector ws
// Start:  node tiktok-relay.js DEIN_TIKTOK_NAME
// Das Spiel dann öffnen mit:  https://mansory63.github.io/battle-chibi-web/?live=1&ws=ws://localhost:8765
// Hinweis: tiktok-live-connector ist ein inoffizielles Werkzeug, TikTok kann es jederzeit blockieren.
const { WebcastPushConnection } = require('tiktok-live-connector');
const { WebSocketServer } = require('ws');
const user = process.argv[2];
if (!user) { console.log('Bitte TikTok-Namen angeben: node tiktok-relay.js NAME'); process.exit(1); }
const wss = new WebSocketServer({ port: 8765 });
const send = (o) => { const s = JSON.stringify(o); wss.clients.forEach(c => c.readyState === 1 && c.send(s)); };
const tt = new WebcastPushConnection(user);
tt.connect().then(() => console.log('Verbunden mit', user)).catch(e => console.log('Fehler:', e));
tt.on('chat', d => send({ event: 'chat', data: { nickname: d.nickname, comment: d.comment } }));
tt.on('like', d => send({ event: 'like', data: { nickname: d.nickname, likeCount: d.likeCount } }));
tt.on('follow', d => send({ event: 'follow', data: { nickname: d.nickname } }));
tt.on('share', d => send({ event: 'share', data: { nickname: d.nickname } }));
tt.on('gift', d => {
  // Serien-Geschenke erst am Ende der Serie zählen
  if (d.giftType === 1 && !d.repeatEnd) return;
  send({ event: 'gift', data: { nickname: d.nickname, giftName: d.giftName, diamondCount: d.diamondCount, repeatCount: d.repeatCount || 1 } });
});
console.log('WebSocket läuft auf ws://localhost:8765');
