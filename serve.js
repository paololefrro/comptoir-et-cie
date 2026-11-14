// serve.js — petit serveur local pour tester le site généré dans docs/
// Utilisation : node serve.js   puis ouvrir http://localhost:3090
const http = require('http');
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, 'docs');
const types = { '.html': 'text/html; charset=utf-8', '.svg': 'image/svg+xml', '.txt': 'text/plain; charset=utf-8', '.xml': 'application/xml', '.json': 'application/json', '.css': 'text/css', '.js': 'text/javascript' };

http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  if (p.endsWith('/')) p += 'index.html';
  const file = path.join(dir, path.normalize(p));
  if (!file.startsWith(dir)) { res.writeHead(403); res.end(); return; }
  fs.readFile(file, (err, data) => {
    if (err) {
      fs.readFile(path.join(dir, '404.html'), (e2, d2) => { res.writeHead(404, { 'Content-Type': types['.html'] }); res.end(d2 || 'Introuvable'); });
      return;
    }
    res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' });
    res.end(data);
  });
}).listen(3090, () => console.log('Site local : http://localhost:3090'));
