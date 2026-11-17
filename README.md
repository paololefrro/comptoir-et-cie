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
| `supabase.sql`, `supabase-stats.sql`, `supabase-multi.sql`, `supabase-multi2.sql`, `supabase-cadeaux.sql`, `supabase-bourse.sql` | Les tables et règles à créer dans Supabase, dans cet ordre. |
| `docs/` | Le site prêt à héberger. Il est regénéré à chaque `node build.js`, ne le modifie pas à la main. |

## Mettre à jour le site

```bash
node build.js
```

Pour le tester sur ton ordinateur, lance `node serve.js`, puis ouvre http://localhost:3090. Pour voir où se placeront les publicités, lance `node build.js --preview`.

## Tutoriel et personnalisation

- **Tutoriel** : à la première visite, l'accueil propose un tour guidé en 11 étapes. Chaque zone de l'écran est mise en lumière avec une bulle d'explication, et on navigue avec les flèches du clavier ou Échap. Le bouton **🧭 Tuto**, en bas du panneau de gestion, permet de le revoir.
- **Ma boutique** : en haut de l'onglet Travaux, le bouton **Personnaliser** permet de choisir le nom sur l'enseigne et les teintes des murs, du lambris et de la porte, du sol, du comptoir et de l'enseigne, ainsi que la couleur de la maison (liseré du comptoir et tenue). L'aperçu en direct est libre, et les travaux se paient à la validation : couleur de la maison 20 €, nom de l'enseigne 30 €, style d'enseigne 40 €, lambris 50 €, murs 60 €, comptoir 70 €, sol 80 €. Certaines teintes se débloquent avec le niveau. Les autres joueurs voient ces couleurs quand ils visitent le café dans le multijoueur, mais l'enseigne y affiche le nom choisi pour le multijoueur, qui est modéré.

## Notes de mise à jour (patch note)

Au lancement du jeu, un joueur qui revient voit une fois la fenêtre « Quoi de neuf ? ». Elle est définie dans `src/jeu.html` par la liste `PATCHES` (la plus récente en premier) : pour chaque note, un identifiant (`id`), une date et une liste de nouveautés (émoji, titre, texte). Un joueur voit en une fois toutes les notes qu’il n’a pas encore vues.

- Chaque joueur la voit **une seule fois par identifiant** : elle est marquée vue dès son affichage, dans la sauvegarde (`flags.patchSeenList`) et dans le navigateur (`cc-patch-seen-list`).
- Un tout nouveau joueur ne la voit pas : elle est marquée vue avec l’écran d’accueil.
- Pour une nouvelle note : **ajoute une entrée en tête de `PATCHES`** avec un nouvel identifiant (par exemple `2026-11-20`). Les joueurs qui ont déjà vu les anciennes ne voient que la nouvelle.

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

### Cadeaux aux joueurs

Sur `stats.html`, la carte **🎁 Offrir un cadeau à un joueur** permet de choisir ce que tu offres, et d’en cocher plusieurs à la fois :

- 💰 de l’argent, au plus 100 000 000 € ;
- 📱 des abonnés, au plus 10 millions ;
- ⭐ de l’XP, au plus 1 million ;
- 🆙 des niveaux en plus, jusqu’au niveau maximum ;
- 🌟 une réputation à 5 ★ ;
- 📦 une réserve pleine ;
- 🍽️ toute la carte débloquée ;
- 👑 le boost **tout au maximum**.

Pour l’utiliser :

1. Tape l’e-mail de son compte ou son pseudo du multijoueur, puis clique sur **Chercher** : sa fiche s’affiche (enseigne, niveau, dernière activité, cadeaux en attente).
2. Coche les cadeaux et règle les quantités : un récapitulatif s’affiche sous la liste. Ajoute si tu veux un petit message, puis clique deux fois sur le bouton d’envoi : le deuxième clic confirme.
3. Le joueur reçoit le cadeau tout seul, avec une animation et ton message, à sa prochaine ouverture du jeu ou à la fin de sa prochaine journée. La liste « Derniers cadeaux envoyés » indique s’il l’a reçu.

Aucun cadeau ne change la place du joueur au classement, même le boost tout au maximum : seuls les codes secrets utilisés par le joueur lui-même mettent une partie hors classement. Seuls les joueurs qui ont un compte (e-mail ou multijoueur) peuvent recevoir un cadeau. L’installation demande `supabase-cadeaux.sql`, à exécuter après les autres fichiers SQL.

## Sauvegarde des joueurs

La partie s'enregistre toute seule dans le navigateur. Le bouton **💾 Sauvegarde**, en bas du panneau de gestion, permet :

- de copier un code de sauvegarde ;
- de télécharger un fichier (sur le site en ligne seulement) ;
- de recharger une partie à partir d'un code ou d'un fichier, pour changer d'appareil ou restaurer une partie.

### Sauvegarde en ligne avec compte (Supabase, gratuit)

Le joueur se connecte avec son e-mail : il reçoit un lien de connexion, sans mot de passe. Sa partie part ensuite en ligne chaque soir, et il la retrouve sur tous ses appareils.

Comment ça se passe :

- **Avant l’envoi du lien**, la partie part déjà en ligne sous un compte provisoire (celui du multijoueur s’il existe). En confirmant l’e-mail, ce compte devient le compte du joueur. Le lien peut donc s’ouvrir dans un autre navigateur ou sur un autre appareil (l’appli mail d’un téléphone, par exemple) : la partie est retrouvée.
- **Après la connexion** : s’il n’y a rien en ligne, la partie de l’appareil est envoyée ; si l’appareil a une partie toute neuve, la partie en ligne est reprise automatiquement ; si les deux parties diffèrent, le jeu demande laquelle garder.
- **Chaque soir**, la partie est envoyée en ligne, sauf si la partie en ligne est plus avancée de plus d’un jour : elle n’est jamais écrasée sans demander.
- Si l’adresse a déjà un compte, le joueur reçoit un lien de connexion à ce compte et retrouve la partie qui y est enregistrée.
- **Plusieurs appareils en même temps** (PC + téléphone) : chacun garde sa propre session ; « Se déconnecter de cet appareil » ne déconnecte que celui-là. Chaque appareil retient la dernière sauvegarde qu’il a écrite ou reprise (`cc-cloud-sync`). Si l’autre appareil a enregistré depuis, le jeu reprend sa partie tout seul quand rien n’a bougé ici, sinon il demande laquelle garder, et l’envoi automatique n’écrase jamais la partie de l’autre appareil.
- **Code dans l’e-mail** : en plus du lien, l’e-mail contient un code (`{{ .Token }}`) à taper dans 💾 Sauvegarde. Utile sur téléphone, quand le lien s’ouvre dans le navigateur de l’appli mail au lieu de celui du jeu.
- **Lien d’un autre compte** : si le navigateur était déjà connecté à un autre compte e-mail, le jeu demande « Changer de compte ? » et peut revenir sur le compte d’avant.
- Les e-mails partent de `Comptoir & Cie <noreply@comptoir-et-cie.fr>` par le SMTP de Resend (voir plus bas), avec les modèles du dossier `emails/`.

1. Crée un compte sur https://supabase.com, puis un projet. Choisis une région en Europe (par exemple Paris ou Francfort).
2. Ouvre **SQL Editor → New query**, colle le contenu de `supabase.sql`, puis clique sur **Run**.
3. Ouvre **Authentication → URL Configuration**. Renseigne dans **Site URL** l'adresse du site (par exemple `https://www.comptoir-et-cie.fr`), puis ajoute la même adresse dans **Redirect URLs**.
4. Ouvre **Project Settings → API**. Copie la **Project URL** dans `"supabaseUrl"` et la clé **anon public** dans `"supabaseAnonKey"` de `config.json`, puis lance `node build.js`.

La clé « anon » est faite pour être publique. Ce sont les règles du fichier `supabase.sql` qui empêchent chaque joueur de voir les parties des autres. Ne mets jamais la clé « service_role » dans le site.

Tant que ces deux champs sont vides, la sauvegarde en ligne n'apparaît pas : seuls le code et le fichier de sauvegarde sont proposés.

### E-mails de connexion aux couleurs du jeu

Le dossier `emails/` contient les modèles d’e-mails de Supabase aux couleurs de Comptoir & Cie (généré par `node emails/generer.js`, aperçu dans `emails/apercu.html`).

| Modèle Supabase | Fichier | Objet |
| --- | --- | --- |
| Magic link or OTP | `connexion.html` | ☕ Ton lien pour retrouver ta partie · Comptoir & Cie |
| Change email address | `confirmation-adresse.html` | ✅ Confirme ton adresse pour garder ta partie · Comptoir & Cie |
| Confirm sign up | `inscription.html` | ☕ Bienvenue au Comptoir ! Confirme ton adresse |

Supabase ne permet de modifier les modèles qu’avec un **SMTP personnalisé**. Celui du jeu passe par **Resend** (domaine comptoir-et-cie.fr vérifié, région Irlande) :

- **Authentication → Emails → SMTP Settings** : expéditeur `noreply@comptoir-et-cie.fr`, nom « Comptoir & Cie », hôte `smtp.resend.com`, port 465, identifiant `resend`, mot de passe = une clé API Resend (à coller soi-même, elle ne s’affiche plus ensuite).
- **DNS chez OVH** : TXT `resend._domainkey` (DKIM) et les deux CNAME `send` et `rsend` donnés par Resend. Pas de MX Resend : la réception reste chez OVH.
- **Modèles** : Authentication → Emails → Templates, choisir le modèle, coller l’objet et le contenu du fichier, puis enregistrer (les trois sont en place depuis le 17 novembre 2026). Les variables `{{ .ConfirmationURL }}` et `{{ .NewEmail }}` sont remplies par Supabase. Après une modification de `generer.js`, recoller les fichiers.

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

La vitrine de chaque joueur se met à jour chaque soir de jeu. Les parties qui ont utilisé un code secret restent visibles, mais hors classement. Exception : les vitrines marquées `exempt` dans la table `profiles`, comme le compte de l’équipe, restent toujours classées. Une nouvelle partie les remet dans la course.

Installation, à faire une seule fois :

1. Dans **Authentication → Sign In / Providers**, active **Allow anonymous sign-ins**, puis enregistre.
2. Dans **SQL Editor**, exécute `supabase-multi.sql` après `supabase-stats.sql`, puis `supabase-multi2.sql` (défis et clubs), `supabase-cadeaux.sql` et `supabase-bourse.sql` (Bourse entre joueurs).

Modération :

- Les pseudos, enseignes et messages passent par un filtre : mots interdits (table `banned_words`, que tu peux compléter dans Table Editor), liens, e-mails, pseudos de réseaux sociaux et numéros de téléphone.
- Les messages sont limités à 200 caractères, avec 4 secondes entre deux messages et 15 messages par tranche de 10 minutes.
- Un message signalé 3 fois est masqué automatiquement. Une vitrine signalée 5 fois l'est aussi.
- Sur `stats.html`, la carte **Modération du multijoueur** liste les messages signalés, les joueurs à surveiller, les clubs et les derniers messages. Tu peux y masquer ou réafficher un message, une vitrine ou un club, et bloquer un joueur 7 jours. Un club signalé 5 fois est masqué automatiquement.
- Les messages de plus de 60 jours sont effacés automatiquement.

### Niveaux et améliorations

- **50 niveaux**, du Kiosque au Panthéon du café. Les 12 premiers n’ont pas changé. Du niveau 13 au 50, chaque palier demande environ 4,5 % d’XP de plus que le précédent (21 000 XP pour le niveau 13, près de 500 000 XP pour le 50). Au-delà du niveau 12, chaque client servi rapporte 2 à 6 XP.
- Au-delà du niveau 12, les effets liés au niveau (passage, loyer, récompenses, prix) progressent 4 fois moins vite (fonction `lvE`). La pénalité de réputation quand des clients repartent diminue au fil de la journée, pour qu’un café bondé ne s’effondre pas.
- **Nouveaux paliers jusqu’au niveau 50** : tables (6 tables), salle voisine (+6 places par niveau, jusqu’à 36), comptoir (7 postes, et une file d’attente qui s’allonge), commis en cuisine (5 niveaux, +10 % de vitesse chacun et préparation des livraisons, salaire chaque soir), machine espresso, four, déco, réserve (jusqu’à 2 000 portions), enseigne et terrasse chauffée.
- Les nouveaux grands objectifs, missions et trophées sont ajoutés à la fin des listes pour ne pas décaler les sauvegardes.

### Mise à jour du 17 novembre

- **Pertes** : invendus frais 18 % par nuit (5 % avec la vitrine). « Tout commander » et le contrat fournisseur visent, pour les produits périssables, les ventes moyennes des 3 derniers jours × 1,35 + 8 (`stockTarget`), au lieu de remplir la réserve. Une grande carte fait prendre plus d’articles par client.
- **9 recettes de base** de plus, du niveau 12 au niveau 40 (cappuccino, crêpe, bretzel, pizza, frappé, burger, fondant, lunch box, sorbet).
- **Labo** : créations ×(1,35 + 0,2 × (étoiles − 3)) en demande et jusqu’à +15 % de prix accepté, en haut de la Carte, `sigMax()` de 5 à 12 places, test ⚡ immédiat (2,5 × le prix d’un test).
- **Second comptoir** (`comptoir2`, niveaux 20, 30 et 42) : +2 postes par niveau, hors de l’écran à gauche (`SX` renvoie −44 pour ces postes), jusqu’à 13 postes.
- **Bâtiments** : 8 quartiers de plus (niveaux 10 à 45) et rénovations jusqu’au niveau 10 (`LOC_MAX`, `renoReq`).
- **Vols** : cambriolage rare la nuit (événement) et client qui part sans payer (0,12 % des clients) ; l’amélioration « Alarme et caméras » les réduit fortement. Catégorie de bilan « Vols ».
- **Bourse des joueurs** en haut de l’onglet, en trois rubriques (Acheter ×10 / ×100 / Max, Mes actions, Vendre les miennes).
- Après chaque clic dans le panneau, la fiche cliquée est remise à la même place à l’écran (`keepInView`).
- **Inciter à jouer en ligne** : sous les missions, une carte « 🏆 Tu serais n° X sur Y au classement national » pour les joueurs non inscrits (classement public chargé sans compte, `mpWouldRank`), puis « 🔒 Garde ta place au classement » pour les comptes anonymes (bouton vers la sauvegarde avec e-mail). Masquable 3 jours. Le bilan du soir et l’onglet En ligne affichent le rang et l’écart avec le joueur juste devant ; le patch note propose « Rejoindre le classement ».

### Équipe : profils et formation

- Profils débloqués avec le niveau : barista confirmé (8), champion de latte art (15), maître barista (25), légende du comptoir (38). Plus rapides, mais avec des salaires bien plus élevés (jusqu’à 1 650 € par jour). Les meilleurs profils débloqués sortent plus souvent dans les candidatures, et le bouton « Publier une annonce » renouvelle les CV contre de l’argent.
- **Formation** (bouton 🎓 dans l’onglet Équipe) : +10 % de vitesse, +6 % de pourboires et un peu de satisfaction par niveau, salaire +12 %. Coût : salaire × (4 + 3 × niveau actuel). Maximum par profil (champ `max` de `TRAITS`) : 3 à 7. Une fois au maximum, il faut remercier l’employé et en former un plus doué.
- La vitesse de l’employé raccourcit aussi la prise de commande, et les clients marchent plus vite vers un grand comptoir : c’est ce qui limite le plus les clients perdus à haut niveau.
- Le boost « tout au maximum » donne une équipe complète du meilleur profil débloqué, formée au maximum.

### Livraison (onglet « 🛵 Livraison »)

Plateforme fictive **Livr’Éclair**, dès le niveau 4 (inscription 500 €). Les commandes arrivent pendant la journée, avec des pics le midi et le soir, et sont plus nombreuses quand il pleut ou fait froid. Elles sont préparées par les commis en cuisine ou à un poste libre du comptoir (ticket vert), puis un livreur vient les chercher au comptoir de retrait près de la porte.

- Une commande non lancée à temps est annulée : son stock revient en réserve et la note baisse.
- Recette = prix de la carte moins la commission (30 % au départ). Note sur 5 selon la rapidité, le prix et l’emballage.
- Améliorations : zone de livraison (6 zones, jusqu’au niveau 50), contrat (commission de 30 % à 10 %), emballages et 4 livreurs maison sans commission (salaire chaque soir). Bouton de mise en avant pour une journée (+60 % de commandes) et mise en pause des commandes.

### Bourse (onglet « 📈 Bourse »)

L’onglet s’ouvre dès que le joueur a créé sa société. L’ancien système d’héritage (entrée en Bourse qui remettait la partie à zéro, parts de fondateur et bonus permanents) a disparu : les parts de fondateur des anciennes sauvegardes sont converties une fois en argent, 10 000 € par part.

- **Introduction en Bourse** : dès 100 000 € de valeur, le joueur vend 10 à 49 % du capital (frais de 5 %). Le fondateur garde toujours ses 100 000 actions : de nouvelles actions sont créées pour les investisseurs. Rien n’est remis à zéro.
- **Cours** : valeur du groupe (trésorerie et placements compris) plus 15 fois le bénéfice moyen des 7 derniers jours, divisée par le nombre d’actions, avec un bonus de confiance (dividende, réputation), l’humeur du marché et des événements le soir.
- **Émettre ou racheter** des actions (frais de 3 % ou prime de 2 %). Le joueur garde au moins 51 % du capital.
- **Dividendes** : 0, 10, 25 ou 50 % du bénéfice du jour, versés seulement aux autres actionnaires et seulement les jours bénéficiaires.
- **Groupes rivaux** : achat et vente d’actions des trois groupes de la ville (frais de 1 %), avec un petit dividende chaque soir.
- **Entre joueurs** (multijoueur) : un joueur coté propose des actions ; les autres les achètent au cours de sa dernière clôture. L’argent et les dividendes arrivent à la connexion suivante ou en fin de journée (fonction `mp_stock_claim`). Revente au marché au cours du jour moins 2 %. Si un café quitte le multijoueur, ses actionnaires sont remboursés au dernier cours. Les parties avec un code secret (hors vitrines exemptées) ne peuvent ni acheter ni proposer d’actions.
- **Actions bradées** : le vendeur peut proposer ses actions à −10, −25 ou −50 % (colonnes `discount` et `disc_club` de `stock_listings`), pour tous les joueurs ou seulement pour les membres de son club. Le cours ne change pas ; l’acheteur paie le prix bradé et la société vendeuse touche ce prix. Le prix de chaque acheteur est calculé côté serveur (`stock_price_for`). Garde-fous côté serveur : cours limité à 5 fois la valeur de la vitrine, variation au plus ×2 d’une publication à l’autre, dividende au plus 5 % du cours et une fois toutes les 30 secondes.

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
