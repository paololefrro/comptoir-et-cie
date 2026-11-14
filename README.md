# Comptoir & Cie

Jeu de gestion de café gratuit, dans le navigateur. Ce dossier contient le jeu et tout ce qu'il faut pour le mettre en ligne avec de la publicité Google AdSense.

## Ce qu'il y a dans le dossier

| Fichier | Rôle |
| --- | --- |
| `src/jeu.html` | Le jeu lui-même. C'est le seul fichier à modifier pour changer le jeu. |
| `config.json` | Les réglages du site : adresse, identifiants AdSense, informations légales. |
| `build.js` | Fabrique le site final dans `docs/`. |
| `serve.js` | Petit serveur pour tester le site sur ton ordinateur. |
| `docs/` | Le site prêt à héberger. Il est regénéré à chaque `node build.js`, ne le modifie pas à la main. |

## Mettre à jour le site

```bash
node build.js
```

Pour le tester sur ton ordinateur, lance `node serve.js`, puis ouvre http://localhost:3090. Pour voir où se placeront les publicités, lance `node build.js --preview`.

## Codes secrets

Pour ouvrir la case cachée, clique **5 fois rapidement sur la tasse rose** à côté du nom du café. Les majuscules, les accents et les espaces ne comptent pas.

| Code | Effet |
| --- | --- |
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

## Sauvegarde des joueurs

La partie s'enregistre toute seule dans le navigateur. Le bouton **💾 Sauvegarde**, en bas du panneau de gestion, permet :

- de copier un code de sauvegarde ;
- de télécharger un fichier (sur le site en ligne seulement) ;
- de recharger une partie à partir d'un code ou d'un fichier, pour changer d'appareil ou restaurer une partie.

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
5. Laisse les **annonces automatiques désactivées**, ou exclus-en la zone du jeu, pour qu'elles ne viennent pas se glisser dans l'interface.

## À faire avant l'ouverture au public

- Renseigne `editorName` et `contactEmail` dans `config.json` : les mentions légales sont obligatoires en France. Sans ces informations, les pages affichent « à compléter ».
- Vérifie sur https://data.inpi.fr que le nom choisi n'est pas déjà une marque déposée dans ton domaine d'activité.
- Les revenus publicitaires se déclarent. Le statut de micro-entrepreneur est le plus simple pour commencer.
