// Mesure d'audience anonyme de Comptoir & Cie, sans cookie.
// Compte les visites, leur durée et la progression dans le jeu. Rien ne permet d'identifier la personne.
// Désactivable depuis la page Confidentialité (clé « cc-noaudit » du stockage local).
(function () {
  var C = window.SITE_CONFIG && window.SITE_CONFIG.cloud;
  if (!C || !window.fetch || !window.JSON) return;
  var host = location.hostname;
  // Pas de comptage en local, sauf pour tester avec ?track=1
  if (/^(localhost|127\.|\[::1\]$)|\.localhost$/.test(host) && !/[?&]track=1\b/.test(location.search)) return;
  var ua = navigator.userAgent || '';
  if (/bot|crawl|spider|slurp|headless|lighthouse|preview|facebookexternalhit/i.test(ua)) return;
  var ls;
  try { ls = window.localStorage; if (ls.getItem('cc-noaudit') === '1') return; } catch (e) { return; }

  function uid() {
    if (window.crypto && crypto.randomUUID) return crypto.randomUUID();
    var b = new Uint8Array(16);
    (window.crypto || window.msCrypto).getRandomValues(b);
    b[6] = (b[6] & 15) | 64; b[8] = (b[8] & 63) | 128;
    var x = Array.prototype.map.call(b, function (v) { return (v + 256).toString(16).slice(1); }).join('');
    return x.slice(0, 8) + '-' + x.slice(8, 12) + '-' + x.slice(12, 16) + '-' + x.slice(16, 20) + '-' + x.slice(20);
  }

  // Identifiant du navigateur, renouvelé au bout de 13 mois (durée maximale conseillée par la CNIL)
  var now = Date.now(), vid = null, saved = null;
  try { saved = JSON.parse(ls.getItem('cc-vid') || 'null'); } catch (e) {}
  if (saved && saved.id && now - saved.t < 395 * 864e5) vid = saved.id;
  else { vid = uid(); try { ls.setItem('cc-vid', JSON.stringify({ id: vid, t: now })); } catch (e) {} }
  var visit = uid();

  var dev = (/iPad|Tablet/i.test(ua) || (/Android/i.test(ua) && !/Mobile/i.test(ua)) || (/Macintosh/.test(ua) && navigator.maxTouchPoints > 1))
    ? 'tablette' : (/Mobi|iPhone|iPod|Android/i.test(ua) ? 'mobile' : 'ordinateur');

  // Provenance : ?ref=… ou ?utm_source=… dans le lien partagé, sinon le site précédent
  var ref = '', m = location.search.match(/[?&](?:ref|utm_source)=([^&#]+)/i);
  if (m) { try { ref = decodeURIComponent(m[1]); } catch (e) { ref = m[1]; } }
  else if (document.referrer) {
    try {
      var rh = new URL(document.referrer).hostname.replace(/^www\./, '');
      if (rh && rh !== host.replace(/^www\./, '')) ref = rh;
    } catch (e) {}
  }
  ref = ref.toLowerCase().replace(/[^a-z0-9._-]/g, '').slice(0, 80);

  var sec = 0, days = 0, game = {}, lastBody = '', tick = 0;
  window.addEventListener('cc-stats', function (e) {
    var d = e.detail || {};
    if (d.kind === 'day') days++;
    game = d;
  });

  function send(final) {
    var body = JSON.stringify({
      p_id: visit, p_visitor: vid, p_seconds: sec, p_device: dev, p_referrer: ref || null,
      p_days: days, p_day: game.day || null, p_level: game.level || null
    });
    if (body === lastBody) return;
    lastBody = body;
    try {
      fetch(C.url + '/rest/v1/rpc/track_visit', {
        method: 'POST', keepalive: !!final,
        headers: { 'apikey': C.key, 'Content-Type': 'application/json' },
        body: body
      }).catch(function () {});
    } catch (e) {}
  }

  // Le temps n'avance que lorsque la page est affichée à l'écran
  setInterval(function () {
    if (document.visibilityState !== 'visible') return;
    sec = Math.min(sec + 5, 86400);
    tick += 5;
    if (tick >= 60) { tick = 0; send(false); }
  }, 5000);
  setTimeout(function () { send(false); }, 1500);
  document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'hidden') send(true); });
  window.addEventListener('pagehide', function () { send(true); });
})();
