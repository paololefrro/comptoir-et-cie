# Comptoir & Cie

Jeu de gestion de café gratuit, dans le navigateur. Ce dossier contient le jeu et tout ce qu'il faut pour le mettre en ligne avec de la publicité Google AdSense.

## Ce qu'il y a dans le dossier

| Fichier | Rôle |
| --- | --- |
| `src/jeu.html` | Le jeu lui-même. C'est le seul fichier à modifier pour changer le jeu. |
| `config.json` | Les réglages du site : adresse, identifiants AdSense, informations légales. |
| `build.js` | Fabrique le site final dans `docs/`. |
| `serve.js` | Petit serveur pour tester le site sur ton ordinateur. |
| `src/guides.js` | Les guides du jeu publiés sur le site (une page par guide, plus la page `guides.html`). |
| `src/stats.html` | La page privée des statistiques. |
| `src/audience.js` | Le comptage anonyme des visites, ajouté à la page du jeu. |
| `supabase.sql`, `supabase-stats.sql`, `supabase-multi.sql`, `supabase-multi2.sql`, `supabase-cadeaux.sql` | Les tables et règles à créer dans Supabase, dans cet ordre. |
| `docs/` | Le site prêt à héberger. Il est regénéré à chaque `node build.js`, ne le modifie pas à la main. |

## Mettre à jour le site

```bash
node build.js
```

Pour le tester sur ton ordinateur, lance `node serve.js`, puis ouvre http://localhost:3090. Pour voir où se placeront les publicités, lance `node build.js --preview`.

## Tutoriel et personnalisation

- **Tutoriel** : à la première visite, l'accueil propose un tour guidé en 11 étapes. Chaque zone de l'écran est mise en lumière avec une bulle d'explication, et on navigue avec les flèches du clavier ou Échap. Le bouton **🧭 Tuto**, en bas du panneau de gestion, permet de le revoir.
- **Ma boutique** : en haut de l'onglet Travaux, le bouton **Personnaliser** permet de choisir le nom sur l'enseigne et les teintes des murs, du lambris et de la porte, du sol, du comptoir et de l'enseigne, ainsi que la couleur de la maison (liseré du comptoir et tenue). L'aperçu en direct est libre, et les travaux se paient à la validation : couleur de la maison 20 €, nom de l'enseigne 30 €, style d'enseigne 40 €, lambris 50 €, murs 60 €, comptoir 70 €, sol 80 €. Certaines teintes se débloquent avec le niveau. Les autres joueurs voient ces couleurs quand ils visitent le café dans le multijoueur, mais l'enseigne y affiche le nom choisi pour le multijoueur, qui est modéré.

## Codes secrets

Pour ouvrir la case cachée, clique **5 fois rapidement sur la tasse rose** à côté du nom du café. Les majuscules, les accents et les espaces ne comptent pas.

| Code | Effet |
| --- | --- |
| `TOUTAUMAX` | Tout au maximum : niveau, améliorations, carte ★★★, labo, équipe, adresses, rachats et franchise mondiale |
| `PLUIEDOR` | +10 000 € |
| `MILLIONNAIRE` | +1 000 000 € |
| `FOULE` | Deux fois plus de clients pendant 3 jours |
| `ETOILES` | Réputation à 5 ★ |
| `VIRAL` | +50 000 abonnés |
| `NIVEAUSUP` | Passe au niveau suivant |
| `STOCKPLEIN` | Remplit toute la réserve |
| `TOUTDEBLOQUER` | Débloque toute la carte |
| `EQUIPEDREVE` | Comptoir agrandi au maximum, équipe au moral maximal |
| `FRANCHISEXPRESS` | Crée la société, lance la franchise et fait venir 5 candidats |
| `FONDATEUR` | +5 parts de fondateur |

### Cadeaux aux joueurs

Sur `stats.html`, la carte **🎁 Offrir un cadeau à un joueur** permet d’offrir à un joueur :

- de l’argent, au plus 100 000 000 € par cadeau ;
- des abonnés, au plus 10 millions ;
- de l’XP, au plus 1 million ;
- le boost **tout au maximum**.

Pour l’utiliser :

1. Tape l’e-mail de son compte ou son pseudo du multijoueur, puis clique sur **Chercher** : sa fiche s’affiche (enseigne, niveau, dernière activité, cadeaux en attente).
2. Choisis le cadeau et la quantité, ajoute si tu veux un petit message, puis clique deux fois sur le bouton d’envoi : le deuxième clic confirme.
3. Le joueur reçoit le cadeau tout seul, avec une animation et ton message, à sa prochaine ouverture du jeu ou à la fin de sa prochaine journée. La liste « Derniers cadeaux envoyés » indique s’il l’a reçu.

L’argent, les abonnés et l’XP ne changent rien au classement. Le boost tout au maximum, lui, place la partie hors classement, comme un code secret. Seuls les joueurs qui ont un compte (e-mail ou multijoueur) peuvent recevoir un cadeau. L’installation demande `supabase-cadeaux.sql`, à exécuter après les autres fichiers SQL.

## Sauvegarde des joueurs

La partie s'enregistre toute seule dans le navigateur. Le bouton **💾 Sauvegarde**, en bas du panneau de gestion, permet :

- de copier un code de sauvegarde ;
- de télécharger un fichier (sur le site en ligne seulement) ;
- de recharger une partie à partir d'un code ou d'un fichier, pour changer d'appareil ou restaurer une partie.

### Sauvegarde en ligne avec compte (Supabase, gratuit)

Le joueur se connecte avec son e-mail : il reçoit un lien de connexion, sans mot de passe. Sa partie part ensuite en ligne chaque soir, et il la retrouve sur tous ses appareils.

1. Crée un compte sur https://supabase.com, puis un projet. Choisis une région en Europe (par exemple Paris ou Francfort).
2. Ouvre **SQL Editor → New query**, colle le contenu de `supabase.sql`, puis clique sur **Run**.
3. Ouvre **Authentication → URL Configuration**. Renseigne dans **Site URL** l'adresse du site (par exemple `https://www.comptoir-et-cie.fr`), puis ajoute la même adresse dans **Redirect URLs**.
4. Ouvre **Project Settings → API**. Copie la **Project URL** dans `"supabaseUrl"` et la clé **anon public** dans `"supabaseAnonKey"` de `config.json`, puis lance `node build.js`.

La clé « anon » est faite pour être publique. Ce sont les règles du fichier `supabase.sql` qui empêchent chaque joueur de voir les parties des autres. Ne mets jamais la clé « service_role » dans le site.

Tant que ces deux champs sont vides, la sauvegarde en ligne n'apparaît pas : seuls le code et le fichier de sauvegarde sont proposés.

### Boîte à idées

Le même projet Supabase sert aussi à la **boîte à idées**. Les joueurs cliquent sur **💡 Proposer une idée** (en bas du panneau de gestion ou en bas de la page), choisissent un type (nouveau produit, amélioration, bug, autre) et écrivent leur idée.

- Les suggestions arrivent dans **Supabase → Table Editor → suggestions**. Tu peux changer la colonne `status` (par exemple en `lue` ou `ajoutée`) pour t'y retrouver.
- Personne d'autre que toi ne peut les lire : le site a seulement le droit d'en ajouter.
- Un même navigateur ne peut envoyer qu'une idée par minute, et chaque message fait au plus 600 caractères.
- Tant que Supabase n'est pas configuré, le bouton n'apparaît pas.

### Multijoueur (onglet « 🌍 En ligne »)

Les joueurs rejoignent le multijoueur avec un simple pseudo : un compte anonyme est créé pour eux, sans e-mail. Ils ont alors accès à :

- **un classement national** par valeur du groupe, abonnés ou pourboires ;
- **un annuaire des cafés**, avec une recherche ;
- **la visite des cafés** des autres, avec leur salle redessinée (déco, équipe, enseigne), leurs chiffres et un livre d'or ;
- **les pourboires** : un par café et par jour. Le café qui les reçoit gagne de l'argent et des abonnés, et la personne qui les laisse gagne de l'XP ;
- **la terrasse**, un salon de discussion commun ;
- **les défis** : un duel de ventes sur 3 journées de jeu entre deux cafés, qui compte les ventes au comptoir du café d'origine, sans les succursales ni la franchise. Le gagnant reçoit de l'argent, des abonnés et de l'XP, et un classement « Duels » existe. Chaque joueur a au plus 3 défis en cours, et un défi non accepté expire au bout de 48 h ;
- **les clubs** : jusqu'à 20 cafés par club, fondé pour 5 000 € dès le niveau 3, avec un salon privé et un classement des clubs. L'objectif de la semaine est de servir 1 000 clients par membre, avec un minimum de 2 000. Il se remet à zéro chaque lundi, et chaque membre récupère alors une récompense.

La vitrine de chaque joueur se met à jour chaque soir de jeu. Les parties qui ont utilisé un code secret restent visibles, mais hors classement. Une nouvelle partie les remet dans la course.

Installation, à faire une seule fois :

1. Dans **Authentication → Sign In / Providers**, active **Allow anonymous sign-ins**, puis enregistre.
2. Dans **SQL Editor**, exécute `supabase-multi.sql` après `supabase-stats.sql`, puis `supabase-multi2.sql` (défis et clubs).

Modération :

- Les pseudos, enseignes et messages passent par un filtre : mots interdits (table `banned_words`, que tu peux compléter dans Table Editor), liens, e-mails, pseudos de réseaux sociaux et numéros de téléphone.
- Les messages sont limités à 200 caractères, avec 4 secondes entre deux messages et 15 messages par tranche de 10 minutes.
- Un message signalé 3 fois est masqué automatiquement. Une vitrine signalée 5 fois l'est aussi.
- Sur `stats.html`, la carte **Modération du multijoueur** liste les messages signalés, les joueurs à surveiller, les clubs et les derniers messages. Tu peux y masquer ou réafficher un message, une vitrine ou un club, et bloquer un joueur 7 jours. Un club signalé 5 fois est masqué automatiquement.
- Les messages de plus de 60 jours sont effacés automatiquement.

Supabase recommande d'activer un captcha pour les comptes anonymes quand le jeu devient populaire (**Authentication → Attack Protection**).

### Statistiques de fréquentation

Le site compte les visites de façon anonyme, sans cookie, et les enregistre dans le même projet Supabase. Pour chaque visite, il garde un identifiant tiré au hasard, la durée, le type d'appareil, la provenance, ainsi que le jour et le niveau de la partie. Les chiffres se consultent sur une page privée : **https://www.comptoir-et-cie.fr/stats.html**.

Installation, à faire une seule fois :

1. Dans **SQL Editor → New query**, colle le contenu de `supabase-stats.sql`, puis clique sur **Run**.
2. Dans **Authentication → Users → Add user → Create new user**, crée ton compte avec ton adresse e-mail et un mot de passe. Coche **Auto Confirm User**. Ajoute ensuite cette adresse dans la table `admins` (Table Editor → admins → Insert row).
3. Ouvre `stats.html` et connecte-toi avec cette adresse et ce mot de passe.

Pour donner l'accès à quelqu'un d'autre, ajoute son adresse dans la table `admins` (Table Editor), puis crée-lui un compte de la même façon.

Bon à savoir :

- Pour savoir d'où viennent les joueurs, ajoute `?ref=nom` à tes liens, par exemple `https://www.comptoir-et-cie.fr/?ref=tiktok`.
- Les visites faites depuis ton ordinateur en local (`node serve.js`) ne sont pas comptées. Ajoute `?track=1` à l'adresse pour tester.
- Les joueurs peuvent refuser le comptage sur la page Confidentialité.
- Les visites de plus de 25 mois sont effacées automatiquement, comme le recommande la CNIL.

## Mise en ligne avec GitHub Pages (gratuit)

1. Crée un compte sur https://github.com, puis un dépôt **public** nommé `comptoir-et-cie`.
2. Envoie le contenu de ce dossier dans le dépôt.
3. Dans le dépôt, ouvre **Settings → Pages**. Choisis **Deploy from a branch**, la branche `main` et le dossier `/docs`, puis enregistre.
4. Au bout d'une minute ou deux, le site est en ligne sur `https://<ton-pseudo>.github.io/comptoir-et-cie/`.

## Brancher ton nom de domaine

1. Achète le domaine chez un bureau d'enregistrement. Pour un `.fr`, OVHcloud est le plus courant en France ; compte environ 7 à 15 € par an.
2. Dans `config.json`, renseigne `"siteUrl": "https://www.ton-domaine.fr"`, puis lance `node build.js`. Le fichier `docs/CNAME` est créé automatiquement.
3. Dans la zone DNS de ton domaine, ajoute :
   - 4 enregistrements **A** sur `@`, vers `185.199.108.153`, `185.199.109.153`, `185.199.110.153` et `185.199.111.153` ;
   - un enregistrement **CNAME** `www` vers `<ton-pseudo>.github.io.`
4. Sur GitHub, dans **Settings → Pages → Custom domain**, saisis `www.ton-domaine.fr`, puis coche **Enforce HTTPS** quand l'option apparaît (il faut parfois attendre jusqu'à 24 h).

## Publicité Google AdSense

1. Crée un compte sur https://adsense.google.com avec **ton propre domaine**. AdSense n'accepte pas les adresses en `github.io`.
2. Dans AdSense, active le message de consentement : **Confidentialité et messages → RGPD**. C'est obligatoire pour les visiteurs européens, et le lien « Gérer mes cookies » du site s'en sert.
3. Copie ton identifiant `ca-pub-…` dans `"adsenseClient"` de `config.json`, puis lance `node build.js`. Le fichier `ads.txt` est généré.
4. Une fois le site validé (cela peut prendre de quelques jours à quelques semaines), crée 3 blocs d'annonces **Display** responsives. Colle leurs identifiants dans `adSlots` (`game` sous la salle du café, `bottom` sous le jeu, `content` dans le texte « Comment jouer »), puis relance `node build.js`.
5. AdSense refuse les sites sans contenu rédigé (« Annonces Google diffusées sur des pages ou écrans sans contenu d'éditeur »). Les guides de `src/guides.js` servent à cela : ajoute-en régulièrement, et la balise publicitaire n'est placée que sur la page du jeu et les guides.
6. Laisse les **annonces automatiques désactivées**, ou exclus-en la zone du jeu, pour qu'elles ne viennent pas se glisser dans l'interface.

## À faire avant l'ouverture au public

- Renseigne `editorName` et `contactEmail` dans `config.json` : les mentions légales sont obligatoires en France. Sans ces informations, les pages affichent « à compléter ».
- Vérifie sur https://data.inpi.fr que le nom choisi n'est pas déjà une marque déposée dans ton domaine d'activité.
- Les revenus publicitaires se déclarent. Le statut de micro-entrepreneur est le plus simple pour commencer.
