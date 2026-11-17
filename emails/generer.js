// Génère les e-mails de connexion de Supabase aux couleurs de Comptoir & Cie.
// Lancer : node emails/generer.js  → crée connexion.html, confirmation-adresse.html, inscription.html et apercu.html
// Les fichiers .html (sauf apercu.html) se collent tels quels dans Supabase → Authentication → Emails → Templates.
const fs = require('fs');
const path = require('path');

const C = { bg: '#e4eedd', card: '#fbfdf8', line: '#d0dfc4', ink: '#2b1d16', ink2: '#67584d', text: '#4a3c32',
  accent: '#e2456b', accent2: '#b82f51', gold: '#f0ad3c', goldSoft: '#fbecce', frame: '#2f5e45' };
const DISPLAY = "'Lilita One','Arial Rounded MT Bold','Trebuchet MS',Arial,sans-serif";
const BODY = "Nunito,'Segoe UI',Helvetica,Arial,sans-serif";
const URL = '{{ .ConfirmationURL }}';

function email({ preheader, eyebrow, title, text, button, info }) {
  return `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="color-scheme" content="light">
<meta name="supported-color-schemes" content="light">
<title>Comptoir &amp; Cie</title>
<link href="https://fonts.googleapis.com/css2?family=Lilita+One&amp;family=Nunito:wght@600;800&amp;display=swap" rel="stylesheet">
</head>
<body style="margin:0;padding:0;background:${C.bg};">
<div style="display:none;max-height:0;overflow:hidden;opacity:0;mso-hide:all;">${preheader}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:${C.bg};font-family:${BODY};color:${C.ink};">
<tr><td align="center" style="padding:28px 12px 32px;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width:520px;">
    <tr><td align="center" style="padding:0 0 16px;">
      <table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
        <td align="center" valign="middle" width="58" height="58" style="width:58px;height:58px;background:${C.accent};border-radius:18px;font-size:30px;line-height:58px;text-align:center;">☕</td>
      </tr></table>
      <div style="font-family:${DISPLAY};font-size:27px;line-height:1.2;color:${C.frame};margin-top:8px;">Comptoir &amp; Cie</div>
      <div style="font-size:13px;font-weight:800;color:${C.ink2};margin-top:2px;">Le jeu de gestion de café</div>
    </td></tr>
    <tr><td style="background:${C.card};border:2px solid ${C.line};border-radius:22px;padding:28px 26px 26px;">
      <div style="font-size:12.5px;font-weight:800;color:${C.accent};text-transform:uppercase;letter-spacing:1.2px;">${eyebrow}</div>
      <h1 style="margin:6px 0 12px;font-family:${DISPLAY};font-size:30px;font-weight:400;line-height:1.15;color:${C.ink};">${title}</h1>
      <p style="margin:0 0 22px;font-size:16px;line-height:1.55;font-weight:600;color:${C.text};">${text}</p>
      <table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="margin:0 auto 22px;"><tr>
        <td align="center" style="background:${C.accent};border-radius:16px;border-bottom:4px solid ${C.accent2};">
          <a href="${URL}" style="display:inline-block;padding:15px 30px;font-family:${DISPLAY};font-size:20px;line-height:1.2;color:#ffffff;text-decoration:none;border-radius:16px;">${button}</a>
        </td>
      </tr></table>
      <div style="text-align:center;margin:0 0 20px;">
        <div style="font-size:13.5px;line-height:1.45;font-weight:800;color:${C.ink2};">📱 Ou tape ce code dans le jeu (💾 Sauvegarde) :</div>
        <div style="display:inline-block;margin-top:8px;padding:10px 18px;background:#ffffff;border:2px solid ${C.line};border-radius:14px;font-family:${DISPLAY};font-size:30px;line-height:1.1;letter-spacing:6px;color:${C.frame};">{{ .Token }}</div>
      </div>
      <div style="background:${C.goldSoft};border:2px dashed ${C.gold};border-radius:14px;padding:12px 14px;font-size:14px;line-height:1.5;font-weight:800;color:${C.ink};">${info}</div>
      <p style="margin:18px 0 0;font-size:12.5px;line-height:1.5;color:${C.ink2};">Le bouton ne marche pas ? Copie ce lien dans ton navigateur :<br><a href="${URL}" style="color:${C.frame};word-break:break-all;">${URL}</a></p>
    </td></tr>
    <tr><td align="center" style="padding:16px 10px 0;font-size:12.5px;line-height:1.55;color:${C.ink2};">
      Tu n’as rien demandé ? Ignore simplement cet e-mail : personne ne peut utiliser ton compte sans ce lien.<br>
      ☕ <a href="https://www.comptoir-et-cie.fr" style="color:${C.frame};font-weight:800;text-decoration:none;">www.comptoir-et-cie.fr</a>
    </td></tr>
  </table>
</td></tr>
</table>
</body>
</html>
`;
}

const MAILS = [
  { file: 'connexion.html', template: 'Magic link or OTP',
    subject: '☕ Ton lien pour retrouver ta partie · Comptoir & Cie',
    preheader: 'Un clic et ton café t’attend, sur n’importe quel appareil.',
    eyebrow: 'Connexion', title: 'Ton café t’attend !',
    text: 'Clique sur le bouton pour te connecter et retrouver ta partie, ta vitrine et ta place au classement. Pas besoin de mot de passe.',
    button: '☕ Retrouver ma partie',
    info: '⏱️ Ce lien ne sert qu’une fois et expire au bout d’une heure. Tu peux l’ouvrir sur n’importe quel appareil : ta partie en ligne t’y attend.' },
  { file: 'confirmation-adresse.html', template: 'Change email address',
    subject: '✅ Confirme ton adresse pour garder ta partie · Comptoir & Cie',
    preheader: 'Ta partie est à l’abri : un clic pour la garder sur tous tes appareils.',
    eyebrow: 'Sauvegarde en ligne', title: 'Garde ta partie pour toujours',
    text: 'Ta partie est déjà à l’abri en ligne. Confirme l’adresse <b>{{ .NewEmail }}</b> pour la retrouver sur tous tes appareils et ne jamais perdre ta place au classement.',
    button: '✅ Confirmer mon adresse',
    info: '🏆 Une fois ton adresse confirmée, ton café, ta vitrine, ton club et tes actions restent attachés à ton compte.' },
  { file: 'inscription.html', template: 'Confirm sign up',
    subject: '☕ Bienvenue au Comptoir ! Confirme ton adresse',
    preheader: 'Encore un clic pour activer ta sauvegarde en ligne.',
    eyebrow: 'Bienvenue', title: 'Bienvenue au Comptoir &amp; Cie !',
    text: 'Encore un clic : confirme ton adresse pour activer ta sauvegarde en ligne et retrouver ton café partout.',
    button: '☕ Activer mon compte',
    info: '🏆 Choisis aussi un pseudo dans l’onglet 🌍 En ligne pour entrer dans le classement national et défier les autres cafés.' },
];

const dir = __dirname;
MAILS.forEach(m => fs.writeFileSync(path.join(dir, m.file), email(m)));

// Page d'aperçu : les trois e-mails avec des exemples à la place des variables de Supabase
const sample = h => h.split('{{ .ConfirmationURL }}').join('https://www.comptoir-et-cie.fr/').split('{{ .NewEmail }}').join('toi@exemple.fr').split('{{ .Token }}').join('482913');
const esc = s => s.replace(/&/g, '&amp;').replace(/"/g, '&quot;');
fs.writeFileSync(path.join(dir, 'apercu.html'), `<!doctype html><html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Aperçu des e-mails</title>
<style>body{margin:0;background:#cfd9c8;font-family:Nunito,Segoe UI,Arial,sans-serif;color:#2b1d16}h1{font-size:20px;margin:18px 16px 4px}p{margin:0 16px 12px;color:#4a3c32}
.g{display:flex;flex-wrap:wrap;gap:16px;padding:0 16px 24px}.m{flex:1 1 360px;max-width:600px;background:#fff;border-radius:14px;overflow:hidden;box-shadow:0 6px 18px rgba(0,0,0,.12)}
.s{padding:10px 14px;font-size:13px;border-bottom:1px solid #e3e3e3}.s b{display:block;font-size:14px}iframe{width:100%;height:760px;border:0;display:block}</style></head><body>
<h1>Aperçu des e-mails de connexion</h1><p>Avec des exemples à la place du vrai lien et de l’adresse.</p><div class="g">
${MAILS.map(m => `<div class="m"><div class="s"><b>${m.subject}</b>Modèle Supabase : ${m.template} · fichier ${m.file}</div><iframe title="${esc(m.subject)}" srcdoc="${esc(sample(email(m)))}"></iframe></div>`).join('\n')}
</div></body></html>`);

console.log(MAILS.map(m => `${m.template} → ${m.file} · objet : ${m.subject}`).join('\n'));
