// build.js — fabrique le site prêt à héberger dans le dossier docs/
// Utilisation :  node build.js            (version en ligne)
//                node build.js --preview  (montre les emplacements de pub vides)
const fs = require('fs');
const path = require('path');

const root = __dirname;
const cfg = JSON.parse(fs.readFileSync(path.join(root, 'config.json'), 'utf8'));
const src = fs.readFileSync(path.join(root, 'src', 'jeu.html'), 'utf8');
const AUDIENCE_JS = fs.readFileSync(path.join(root, 'src', 'audience.js'), 'utf8');
const STATS_SRC = fs.readFileSync(path.join(root, 'src', 'stats.html'), 'utf8');
const out = path.join(root, 'docs');
fs.mkdirSync(out, { recursive: true });

const preview = process.argv.includes('--preview') || !!cfg.adPreview;
const esc = s => String(s == null ? '' : s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const url = String(cfg.siteUrl || '').trim().replace(/\/+$/, '');
const client = String(cfg.adsenseClient || '').trim();
const cloudUrl = String(cfg.supabaseUrl || '').trim().replace(/\/+$/, '');
const cloudKey = String(cfg.supabaseAnonKey || '').trim();
const cloud = !!(cloudUrl && cloudKey);
const CLOUD_HEAD = cloud ? '<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js"></script>' : '';
const year = new Date().getFullYear();
const todo = txt => `<mark>[à compléter : ${txt}]</mark>`;

// ---------- 1. Découpe du jeu : la feuille de style va dans <head>, le reste dans <body>
const styleMatch = src.match(/<style>[\s\S]*?<\/style>/);
if (!styleMatch) throw new Error('Aucune balise <style> trouvée dans src/jeu.html');
const gameStyle = styleMatch[0];
const gameBody = src.slice(src.indexOf(gameStyle) + gameStyle.length).trim();

// ---------- 2. Morceaux communs
const FONTS = `<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Lilita+One&family=Nunito:wght@500;700;800;900&family=Pacifico&display=swap">`;

const ADS_HEAD = client ? `<meta name="google-adsense-account" content="${esc(client)}">
<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${encodeURIComponent(client)}" crossorigin="anonymous"></script>` : '';

function head(title, desc, canonPath) {
  const canon = url ? url + canonPath : '';
  return `<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${esc(title)}</title>
<meta name="description" content="${esc(desc)}">
${canon ? `<link rel="canonical" href="${esc(canon)}">\n<meta property="og:url" content="${esc(canon)}">` : ''}
<meta property="og:type" content="website">
<meta property="og:locale" content="fr_FR">
<meta property="og:site_name" content="${esc(cfg.siteName)}">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(desc)}">
<meta name="twitter:card" content="summary">
<meta name="theme-color" content="#2f5e45">
<link rel="icon" href="favicon.svg" type="image/svg+xml">
${FONTS}
${ADS_HEAD}`;
}

const SITE_CSS = `<style>
html,body{margin:0}
:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}
[hidden]{display:none!important}
mark{background:#ffe08a;color:#2b1d16;padding:0 4px;border-radius:4px}
.ad-slot{text-align:center;min-width:0}
.ad-label{display:block;font:800 .68rem var(--font-body);letter-spacing:1.2px;text-transform:uppercase;color:var(--ink-2);margin-bottom:4px}
.ad-ph{display:grid;place-items:center;min-height:90px;border:2px dashed var(--line);border-radius:16px;color:var(--ink-2);font:800 .85rem var(--font-body);background:var(--card-2)}
.site-content{max-width:860px;margin:0 auto;padding-block:20px 8px;padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px));font-family:var(--font-body);color:var(--ink);line-height:1.6}
.site-content h2{font-family:var(--font-display);font-weight:400;font-size:1.7rem;margin:30px 0 8px;text-wrap:balance}
.site-content h3{font-size:1.05rem;margin:18px 0 2px}
.site-content p,.site-content li{font-size:1rem;max-width:68ch}
.site-content p{margin:6px 0}
.site-content ol,.site-content ul{padding-left:22px}
.site-content li{margin:4px 0}
.site-content .ad-slot{margin:24px 0}
.site-footer{max-width:1380px;margin:16px auto 0;padding-block:20px 28px;padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px));font:700 .88rem var(--font-body);color:var(--ink-2);display:flex;flex-wrap:wrap;gap:8px 18px;justify-content:center;border-top:2px dashed var(--line)}
.site-footer a{color:var(--accent)}
.site-footer button{font:inherit;color:var(--accent);background:none;border:0;padding:0;cursor:pointer;text-decoration:underline}
</style>`;

// Feuille de style des pages simples (confidentialité, mentions légales, 404)
const PAGE_CSS = `<style>
:root{--bg:#e4eedd;--card:#fbfdf8;--line:#d0dfc4;--ink:#2b1d16;--ink-2:#67584d;--accent:#b82f51;--font-display:"Lilita One","Arial Rounded MT Bold",system-ui,sans-serif;--font-body:"Nunito","Segoe UI",system-ui,sans-serif}
@media (prefers-color-scheme: dark){:root{--bg:#121915;--card:#1c2520;--line:#33443a;--ink:#f3ece1;--ink-2:#bcb0a3;--accent:#ff6f90;color-scheme:dark}}
*{box-sizing:border-box}
html,body{margin:0}
body{background:var(--bg);color:var(--ink);font-family:var(--font-body);line-height:1.65}
.page{max-width:780px;margin:0 auto;padding-block:28px 40px;padding-left:max(16px,env(safe-area-inset-left,0px));padding-right:max(16px,env(safe-area-inset-right,0px))}
.page h1{font-family:var(--font-display);font-weight:400;font-size:2.1rem;line-height:1.1;margin:10px 0 6px}
.page h2{font-family:var(--font-display);font-weight:400;font-size:1.3rem;margin:26px 0 4px}
.page p,.page li{max-width:68ch}
.page a{color:var(--accent)}
.back{display:inline-block;font-weight:800;text-decoration:none}
.card{background:var(--card);border:2px solid var(--line);border-radius:18px;padding:4px 20px 16px}
mark{background:#ffe08a;color:#2b1d16;padding:0 4px;border-radius:4px}
.btn{font:800 .9rem var(--font-body);color:var(--ink);background:var(--bg);border:2px solid var(--line);border-radius:999px;padding:7px 14px;cursor:pointer}
.btn:focus-visible{outline:3px solid var(--accent);outline-offset:2px}
</style>`;

const FOOTER = `<footer class="site-footer">
  <span>© ${year} ${esc(cfg.siteName)}</span>
  <a href="confidentialite.html">Confidentialité</a>
  <a href="mentions-legales.html">Mentions légales</a>
  ${cloud ? '<button type="button" data-suggest>💡 Proposer une idée</button>' : ''}
  ${client ? '<button type="button" id="cookiePrefs">Gérer mes cookies</button>' : ''}
</footer>`;

const SITE_CONFIG = { adsenseClient: client, adSlots: cfg.adSlots || {}, adPreview: preview, cloud: cloud ? { url: cloudUrl, key: cloudKey } : null };

const AD_SCRIPT = `<script>
(function(){
  var C=window.SITE_CONFIG||{},slots=C.adSlots||{};
  document.querySelectorAll('.ad-slot').forEach(function(el){
    var key=el.id.replace('ad-',''),slot=slots[key];
    if(C.adsenseClient&&slot){
      el.innerHTML='<span class="ad-label">Publicité</span><ins class="adsbygoogle" style="display:block" data-ad-client="'+C.adsenseClient+'" data-ad-slot="'+slot+'" data-ad-format="auto" data-full-width-responsive="true"></ins>';
      el.hidden=false;try{(window.adsbygoogle=window.adsbygoogle||[]).push({});}catch(e){}
    }else if(C.adPreview){
      el.innerHTML='<div class="ad-ph">Emplacement publicitaire « '+key+' »</div>';el.hidden=false;
    }
  });
  var b=document.getElementById('cookiePrefs');
  if(b)b.addEventListener('click',function(){window.googlefc=window.googlefc||{};googlefc.callbackQueue=googlefc.callbackQueue||[];googlefc.callbackQueue.push({'CONSENT_DATA_READY':function(){googlefc.showRevocationMessage();}});});
})();
</script>`;

const ABOUT = `<section class="site-content" id="a-propos" aria-labelledby="about-title">
  <h2 id="about-title">${esc(cfg.siteName)}, le jeu de gestion de café</h2>
  <p>Tu reprends un minuscule café de quartier à Paris avec 150 € en caisse. Sers tes premiers clients, règle tes prix, gère ton stock et ton équipe, puis transforme ta petite adresse en une chaîne connue dans toute la France. Le jeu est gratuit, sans inscription, et fonctionne sur ordinateur comme sur téléphone.</p>

  <h2>Comment jouer</h2>
  <ol>
    <li><b>Ouvre le café.</b> Les clients entrent, font la queue et commandent. Clique sur une commande au comptoir pour la préparer plus vite.</li>
    <li><b>Surveille la file d’attente.</b> Un client qui attend trop longtemps repart fâché et fait baisser ta réputation. Clique sur lui pour le faire patienter.</li>
    <li><b>Commande ton stock le soir.</b> Les livraisons arrivent à l’ouverture. En cas de rupture, le coursier express dépanne, mais il coûte cher.</li>
    <li><b>Règle tes prix.</b> Trop bas, tu perds de la marge. Trop haut, les clients repartent. L’indicateur te dit si ton prix est juste.</li>
    <li><b>Investis.</b> Tables, déco, machine espresso, terrasse : chaque amélioration se voit dans la salle et attire plus de monde.</li>
    <li><b>Grandis.</b> Crée ta société, rachète tes concurrents, ouvre de nouvelles adresses, puis lance ta franchise dans toute la France et à l’étranger.</li>
  </ol>

  <h2>Astuces pour bien démarrer</h2>
  <ul>
    <li>Recrute une première personne dès que la file dépasse 4 clients : tu doubles ta capacité de service.</li>
    <li>Regarde la météo du lendemain : les boissons fraîches partent par beau temps, les boissons chaudes quand il pleut ou qu’il fait froid.</li>
    <li>Ne remplis pas trop la réserve de pâtisseries : une partie des invendus part à la poubelle chaque nuit.</li>
    <li>Réponds aux avis négatifs sur les réseaux : un avis sans réponse fait baisser ta réputation.</li>
    <li>Réussis les 3 missions du jour pour ouvrir le coffre bonus, et reviens chaque jour pour la récompense de connexion.</li>
  </ul>

  <div class="ad-slot" id="ad-content" hidden></div>

  <h2>Questions fréquentes</h2>
  <h3>Le jeu est-il gratuit ?</h3>
  <p>Oui, entièrement. Le site est financé par la publicité affichée autour du jeu.</p>
  <h3>Faut-il créer un compte ?</h3>
  <p>Non. Tu joues directement dans ton navigateur.</p>
  <h3>Ma partie est-elle sauvegardée ?</h3>
  <p>Oui, automatiquement, dans ton navigateur. Pour la mettre à l’abri ou la continuer sur un autre appareil, ouvre le bouton « 💾 Sauvegarde » en bas du panneau de gestion : tu peux copier un code ou télécharger un fichier, puis le recharger quand tu veux.${cloud ? ' Tu peux aussi te connecter avec ton e-mail pour retrouver ta partie en ligne sur tous tes appareils.' : ''}</p>
  <h3>Le jeu marche-t-il sur téléphone ?</h3>
  <p>Oui. La salle du café et le panneau de gestion s’adaptent à la taille de l’écran.</p>
  <h3>Puis-je jouer plus vite ?</h3>
  <p>Oui : les boutons ×2, ×3 et ×5 accélèrent la journée. Plus tard, le « Bras droit » enchaîne même les journées tout seul.</p>
</section>`;

// ---------- 3. Page du jeu
const index = `<!doctype html>
<html lang="fr">
<head>
${head(cfg.title || cfg.siteName, cfg.description, '/')}
<script>window.SITE_CONFIG=${JSON.stringify(SITE_CONFIG)};</script>
${cloud ? `<script>\n${AUDIENCE_JS.trim()}\n</script>` : ''}
${CLOUD_HEAD}
${gameStyle}
${SITE_CSS}
</head>
<body>
${gameBody}
${ABOUT}
${FOOTER}
${AD_SCRIPT}
</body>
</html>
`;

// ---------- 4. Pages légales
const editor = cfg.editorName ? esc(cfg.editorName) : todo('ton nom ou ta raison sociale');
const contact = cfg.contactEmail ? `<a href="mailto:${esc(cfg.contactEmail)}">${esc(cfg.contactEmail)}</a>` : todo('une adresse e-mail de contact');

function page(title, desc, file, inner) {
  return `<!doctype html>
<html lang="fr">
<head>
${head(title + ' · ' + cfg.siteName, desc, '/' + file)}
<meta name="robots" content="noindex, follow">
${PAGE_CSS}
</head>
<body>
<main class="page">
<a class="back" href="./">← Retour au jeu</a>
<h1>${esc(title)}</h1>
<div class="card">
${inner}
</div>
</main>
</body>
</html>
`;
}

const privacy = page('Politique de confidentialité', 'Comment ' + cfg.siteName + ' traite tes données.', 'confidentialite.html', `
<h2>En bref</h2>
${cloud ? `<p>Le jeu se joue sans compte : ta partie est enregistrée dans ton navigateur. La sauvegarde en ligne avec ton e-mail est facultative. Le site compte les visites de façon anonyme, sans cookie, et tu peux refuser ce comptage plus bas.</p>` : `<p>Le jeu ne te demande aucune information personnelle et n’a pas de compte utilisateur. Ta partie est enregistrée uniquement dans ton navigateur.</p>`}
<h2>Responsable du traitement</h2>
<p>${editor}. Contact : ${contact}.</p>
<h2>Sauvegarde de ta partie</h2>
<p>Ta progression est enregistrée dans le stockage local de ton navigateur (« localStorage »). Ces données restent sur ton appareil et servent uniquement à faire fonctionner le jeu. Tu peux les effacer avec le bouton « Nouvelle partie » ou en vidant les données du site dans ton navigateur.</p>
${cloud ? `<h2>Sauvegarde en ligne (facultative)</h2>
<p>Si tu choisis de te connecter pour sauvegarder ta partie en ligne, nous conservons ton adresse e-mail (pour t’envoyer le lien de connexion) et les données de ta partie. Elles sont hébergées par Supabase et ne servent qu’à te permettre de retrouver ta partie. Tu peux supprimer ta sauvegarde en ligne à tout moment depuis la fenêtre « 💾 Sauvegarde ». Pour supprimer aussi ton compte, écris-nous à l’adresse ci-dessus.</p>
<h2>Boîte à idées</h2>
<p>Quand tu proposes une idée, nous enregistrons ton message, son type, le pseudo facultatif que tu choisis, ainsi que le jour et le niveau de ta partie. Ces suggestions, hébergées par Supabase, servent uniquement à améliorer le jeu et ne sont jamais affichées publiquement. N’y écris pas d’informations personnelles.</p>` : ''}
${cloud ? `<h2>Mesure d’audience</h2>
<p>Pour savoir combien de personnes jouent et améliorer le jeu, le site compte les visites de façon anonyme, sans cookie. Ton navigateur reçoit un identifiant tiré au hasard, gardé dans son stockage local pendant 13 mois au plus. À chaque visite, nous enregistrons cet identifiant, la durée de la visite, le type d’appareil (téléphone, tablette ou ordinateur), le site d’où tu arrives, ainsi que le jour et le niveau de ta partie. Nous n’enregistrons ni ton adresse IP ni ton nom.</p>
<p>Ces données ne servent qu’à produire des statistiques sur la fréquentation du jeu. Elles ne sont pas croisées avec d’autres données ni transmises à des tiers. Elles sont hébergées par Supabase et effacées au bout de 25 mois.</p>
<p><button type="button" class="btn" id="auditToggle" hidden></button> <span id="auditState" role="status"></span></p>
<script>
(function(){
  var b=document.getElementById('auditToggle'),st=document.getElementById('auditState'),ls;
  try{ls=window.localStorage;ls.getItem('x');}catch(e){st.textContent='Ton navigateur bloque le stockage local : tes visites ne sont pas comptées.';return;}
  function show(){var off=ls.getItem('cc-noaudit')==='1';b.textContent=off?'Accepter à nouveau le comptage':'Ne plus compter mes visites';st.textContent=off?'Tes visites ne sont plus comptées sur ce navigateur.':'Tes visites sont comptées de façon anonyme.';b.hidden=false;}
  b.addEventListener('click',function(){if(ls.getItem('cc-noaudit')==='1')ls.removeItem('cc-noaudit');else{ls.setItem('cc-noaudit','1');ls.removeItem('cc-vid');}show();});
  show();
})();
</script>` : ''}
<h2>Publicité</h2>
<p>Le site affiche des annonces fournies par Google AdSense. Google et ses partenaires peuvent utiliser des cookies pour afficher des annonces, éventuellement personnalisées en fonction de tes visites sur ce site et sur d’autres sites. Lors de ta première visite, un message te permet d’accepter ou de refuser ces cookies. Tu peux changer d’avis à tout moment avec le lien « Gérer mes cookies » en bas de la page du jeu.</p>
<p>Pour en savoir plus sur l’utilisation des données par Google : <a href="https://policies.google.com/technologies/partner-sites" rel="noopener" target="_blank">policies.google.com/technologies/partner-sites</a>. Tu peux aussi gérer la personnalisation des annonces sur <a href="https://adssettings.google.com" rel="noopener" target="_blank">adssettings.google.com</a>.</p>
<h2>Polices d’écriture</h2>
<p>Les polices du jeu sont chargées depuis Google Fonts. Ton navigateur contacte alors les serveurs de Google, qui reçoivent ton adresse IP.</p>
<h2>Hébergement</h2>
<p>Le site est hébergé par ${esc(cfg.hostName)}, qui peut enregistrer des journaux techniques (dont l’adresse IP) pour assurer la sécurité du service.</p>
<h2>Tes droits</h2>
<p>Conformément au RGPD, tu disposes d’un droit d’accès, de rectification, d’effacement et d’opposition. Écris-nous à l’adresse ci-dessus. Tu peux aussi adresser une réclamation à la CNIL (<a href="https://www.cnil.fr" rel="noopener" target="_blank">cnil.fr</a>).</p>
<p><small>Dernière mise à jour : ${new Date().toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })}.</small></p>
`);

const legal = page('Mentions légales', 'Informations légales sur ' + cfg.siteName + '.', 'mentions-legales.html', `
<h2>Éditeur du site</h2>
<p>${editor}<br>Contact : ${contact}</p>
<h2>Directeur de la publication</h2>
<p>${editor}</p>
<h2>Hébergeur</h2>
<p>${esc(cfg.hostName)}<br>${esc(cfg.hostAddress)}</p>
<h2>Propriété intellectuelle</h2>
<p>Le jeu ${esc(cfg.siteName)}, ses textes, graphismes et son code sont la propriété de l’éditeur. Toute reproduction sans autorisation est interdite.</p>
<h2>Données personnelles</h2>
<p>Voir la <a href="confidentialite.html">politique de confidentialité</a>.</p>
`);

const notFound = page('Page introuvable', 'Cette page n’existe pas.', '404.html', `
<p>Oups, cette page s’est perdue entre deux commandes.</p>
<p><a href="./">Retourner au comptoir →</a></p>
`);

const FAVICON = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="16" fill="#e2456b"/><path d="M15 27h27v9a13.5 13.5 0 0 1-27 0z" fill="#fffaf0"/><path d="M42 30h4a6 6 0 0 1 0 12h-5" fill="none" stroke="#fffaf0" stroke-width="4"/><path d="M23 13c-2.5 3 2.5 5 0 8.5M31 11c-2.5 3 2.5 5 0 8.5" fill="none" stroke="#fffaf0" stroke-width="3" stroke-linecap="round"/></svg>`;

// ---------- 5. Écriture des fichiers
const write = (f, c) => fs.writeFileSync(path.join(out, f), c);
write('index.html', index);
write('confidentialite.html', privacy);
write('mentions-legales.html', legal);
write('404.html', notFound);
const LEVEL_NAMES = [...((src.match(/const LEVELS=\[([\s\S]*?)\];/) || [])[1] || '').matchAll(/name:'([^']+)'/g)].map(m => m[1]);
if (cloud) write('stats.html', STATS_SRC.replace('__CLOUD__', JSON.stringify({ url: cloudUrl, key: cloudKey })).replace('__LEVELS__', JSON.stringify(LEVEL_NAMES)));
else if (fs.existsSync(path.join(out, 'stats.html'))) fs.unlinkSync(path.join(out, 'stats.html'));
write('favicon.svg', FAVICON);
write('.nojekyll', '');
write('robots.txt', `User-agent: *\nAllow: /\n${url ? `Sitemap: ${url}/sitemap.xml\n` : ''}`);
if (url) {
  const d = new Date().toISOString().slice(0, 10);
  write('sitemap.xml', `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n  <url><loc>${url}/</loc><lastmod>${d}</lastmod><priority>1.0</priority></url>\n  <url><loc>${url}/confidentialite.html</loc><lastmod>${d}</lastmod><priority>0.2</priority></url>\n  <url><loc>${url}/mentions-legales.html</loc><lastmod>${d}</lastmod><priority>0.2</priority></url>\n</urlset>\n`);
  const host = new URL(url).hostname;
  if (!host.endsWith('github.io')) write('CNAME', host + '\n');
}
if (client) write('ads.txt', `google.com, ${client.replace(/^ca-/, '')}, DIRECT, f08c47fec0942fa0\n`);

// ---------- 6. Rappels
const warn = [];
if (!url) warn.push('siteUrl est vide : renseigne ton adresse (ex. https://www.mon-jeu.fr) pour le référencement.');
if (!cfg.editorName) warn.push('editorName est vide : les mentions légales affichent « à compléter ».');
if (!cfg.contactEmail) warn.push('contactEmail est vide : les pages légales affichent « à compléter ».');
if (!client) warn.push('adsenseClient est vide : aucune publicité ne sera affichée (normal avant la validation AdSense).');
console.log(`Site généré dans docs/ (${Math.round(index.length / 1024)} Ko pour index.html)${preview ? ' — mode aperçu des pubs' : ''}`);
warn.forEach(w => console.log('  ⚠ ' + w));
