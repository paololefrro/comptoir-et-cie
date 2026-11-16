// Guides du jeu : pages de contenu publiées sur le site (build.js les transforme en pages HTML).
// Chaque guide : slug (nom du fichier), icône, titre, description (balise meta), intro et contenu HTML.
module.exports = [
{
  slug: 'guide-debutant',
  icon: '🌱',
  title: 'Bien démarrer : tes premières journées',
  desc: 'Le guide du débutant de Comptoir & Cie : ouvrir son café, servir vite, commander son stock, fixer ses premiers prix et réussir ses cinq premières journées.',
  intro: 'Tu reprends un minuscule kiosque avec 150 € en caisse, un café serré et des croissants. Voici comment transformer ces premières journées en vraie réussite, sans te ruiner.',
  html: `
<h2>Ta première journée, étape par étape</h2>
<p>Avant d’ouvrir, jette un œil à l’onglet <b>Carte</b>. Tu y trouves tes deux premiers produits : le <b>café serré</b> (vendu 2,50 €, il te coûte environ 0,35 €) et le <b>croissant pur beurre</b> (2,20 €, pour environ 0,45 € de matières premières). La réserve contient déjà quelques portions, de quoi tenir la première journée.</p>
<p>Clique ensuite sur <b>Ouvrir le café</b>. Les clients entrent par la porte, font la queue au comptoir et passent commande. Ton personnage prépare les commandes tout seul, mais tu peux l’aider : <b>clique sur une commande au comptoir</b> pour la préparer plus vite. Quand la file s’allonge, c’est le meilleur moyen d’éviter les départs.</p>
<p>Surveille la petite jauge au-dessus des clients qui attendent. Si elle se vide, le client repart fâché et ta réputation baisse. Un clic sur un client impatient le fait patienter un peu plus longtemps.</p>
<p>Les clients assis laissent parfois des <b>pièces sur les tables</b>. Ramasse-les toi-même : un pourboire cliqué rapporte 50 % de plus que s’il est ramassé automatiquement en fin de journée.</p>

<h2>Le soir : le moment des décisions</h2>
<p>À la fermeture, le bilan du jour s’affiche : ventes, pourboires, dépenses et bénéfice. C’est le moment de préparer le lendemain.</p>
<ul>
  <li><b>Commande ton stock.</b> Les commandes passées le soir sont livrées à l’ouverture suivante. Le bouton « Tout commander » remplit la réserve de chaque produit d’un coup.</li>
  <li><b>Regarde la météo du lendemain.</b> Par beau temps, les boissons fraîches partent plus vite ; quand il pleut ou qu’il fait froid, ce sont les boissons chaudes.</li>
  <li><b>Vérifie tes missions.</b> Trois missions du jour te sont proposées, avec une récompense chacune. Réussis les trois pour ouvrir le coffre bonus.</li>
</ul>

<h2>Tes premiers achats : par quoi commencer ?</h2>
<p>L’argent part vite au début, alors mieux vaut le placer là où il rapporte le plus. Voici un ordre qui fonctionne bien :</p>
<ol>
  <li><b>Une nouvelle boisson.</b> La citronnade maison (120 €) ou le chocolat chaud (180 €) élargissent ta carte : plus de choix, c’est plus de clients satisfaits et un ticket moyen plus élevé.</li>
  <li><b>Les tables bistrot</b> (90 €). Elles ajoutent deux places assises, et les clients assis laissent des pourboires.</li>
  <li><b>La déco cosy</b> (70 € pour le premier niveau). Elle rend les clients plus heureux et attire 4 % de passants en plus à chaque niveau.</li>
  <li><b>Une première embauche</b>, dès que la file d’attente dépasse régulièrement quatre clients. Chaque personne au comptoir sert en même temps que toi.</li>
</ol>

<h2>Monter de niveau</h2>
<p>Chaque client servi te rapporte 1 point d’expérience. Ton café passe ainsi de <b>Kiosque</b> à <b>Petit café</b> (40 XP), puis <b>Café de quartier</b> (150 XP), <b>Adresse prisée</b> (380 XP) et bien plus loin : il y a <b>50 niveaux</b>, jusqu’au <b>Panthéon du café</b>. Chaque niveau débloque de nouveaux produits, de nouvelles améliorations et, à partir du niveau 3, la création de ta propre société. Après le niveau 12, chaque client rapporte de 2 à 6 points d’expérience.</p>

<h2>La livraison à domicile</h2>
<p>Dès le niveau 4, l’onglet <b>Livraison</b> te permet d’inscrire ton café sur <b>Livr’Éclair</b>, l’appli de livraison de la ville (500 €). Des commandes arrivent alors pendant la journée, surtout le midi, le soir et quand il pleut. Ton équipe les prépare au comptoir, ou tes commis en cuisine, puis un livreur passe les chercher près de la porte. Tu touches le prix de ta carte moins une commission de 30 % au départ.</p>
<p>Une commande qui attend trop est annulée et fait baisser ta note sur l’appli. Plus ta note est haute, plus tu reçois de commandes. Avec le temps, tu peux agrandir ta zone de livraison, négocier une commission plus basse, soigner tes emballages et embaucher tes propres livreurs, qui ne paient pas de commission.</p>

<h2>Les erreurs à éviter</h2>
<ul>
  <li><b>Tomber en rupture de stock.</b> Un produit épuisé, ce sont des ventes perdues et des clients déçus. Le coursier express dépanne en pleine journée, mais il coûte bien plus cher qu’une commande du soir.</li>
  <li><b>Remplir la réserve de pâtisseries.</b> Une partie des invendus sucrés part à la poubelle chaque nuit. Commande ce que tu vends vraiment.</li>
  <li><b>Laisser les avis négatifs sans réponse.</b> Sur les réseaux sociaux, une critique ignorée fait baisser ta réputation. Une réponse rapide limite les dégâts.</li>
  <li><b>Augmenter tous les prix d’un coup.</b> Les clients ont un budget : trop cher, ils repartent sans rien acheter. Le guide sur les prix t’explique comment trouver le bon réglage.</li>
</ul>

<h2>Personnaliser ta boutique</h2>
<p>Dans l’onglet <b>Travaux</b>, le bouton « Personnaliser » te permet de choisir le nom écrit sur l’enseigne et les teintes de ta boutique : murs, lambris, sol, comptoir, enseigne et couleur de la maison. L’aperçu est libre, et les travaux coûtent de 20 à 80 € par changement. Certaines finitions, comme le sol en marbre, se débloquent avec le niveau.</p>
`},
{
  slug: 'guide-prix',
  icon: '💶',
  title: 'Bien fixer ses prix',
  desc: 'Comment régler les prix de ta carte dans Comptoir & Cie : l’indicateur de prix, la marge, la météo, les saisons, la tendance du jour et l’effet des recettes.',
  intro: 'Le prix est le levier le plus puissant du jeu. Trop bas, tu travailles pour rien ; trop haut, les clients repartent les mains vides. Voici comment trouver le bon équilibre, produit par produit.',
  html: `
<h2>Lire l’indicateur de prix</h2>
<p>Dans l’onglet <b>Carte</b>, chaque produit affiche un petit verdict à côté de son prix. Il compare ton prix au « prix juste » que les clients ont en tête :</p>
<table>
  <thead><tr><th>Verdict</th><th>Ce que ça veut dire</th></tr></thead>
  <tbody>
    <tr><td>😍 Bon plan</td><td>Jusqu’à 15 % sous le prix juste. Les clients adorent, mais ta marge fond.</td></tr>
    <tr><td>🙂 Prix juste</td><td>Autour du prix attendu. Le meilleur équilibre la plupart du temps.</td></tr>
    <tr><td>😬 Un peu cher</td><td>Jusqu’à 20 % au-dessus. Ça passe pour un produit très demandé ou une belle recette.</td></tr>
    <tr><td>🙅 Trop cher</td><td>Au-delà. Beaucoup de clients refusent d’acheter.</td></tr>
  </tbody>
</table>
<p>Juste sous le curseur, le jeu rappelle le <b>coût</b> du produit et ta <b>marge</b> par vente. Un café serré vendu 2,50 € pour un coût d’environ 0,35 € te laisse plus de 2 € de marge : c’est l’un des produits les plus rentables du jeu.</p>

<h2>Marge ou volume ?</h2>
<p>Un prix bas attire du monde et remplit la salle, ce qui fait grimper l’expérience et la réputation. Un prix plus haut rapporte davantage par client. En début de partie, quand le café est petit et la file courte, mieux vaut rester autour du prix juste pour fidéliser. Une fois l’équipe en place et la salle pleine, tu peux monter légèrement les prix des produits phares sans perdre beaucoup de ventes.</p>

<h2>Les recettes changent tout</h2>
<p>Chaque produit peut être amélioré jusqu’à trois étoiles grâce au bouton <b>Recette</b>. Une meilleure recette rend les clients plus heureux et leur fait accepter un prix plus élevé. Un produit en ★★★ supporte un prix « un peu cher » bien mieux qu’un produit de base.</p>
<p>La <b>maîtrise</b> joue aussi : après 50, 250 puis 1 000 ventes d’un même produit, tu obtiens une médaille de bronze, d’argent puis d’or, avec un bonus de revenus de 3 %, 6 % puis 10 % sur ce produit.</p>

<h2>Météo, saisons et tendance du jour</h2>
<ul>
  <li><b>La météo</b> modifie la demande : les boissons fraîches (citronnade, bubble tea, smoothies…) se vendent mieux au soleil, les boissons chaudes par temps froid ou pluvieux. Le bulletin du lendemain s’affiche le soir : c’est le bon moment pour ajuster prix et stock.</li>
  <li><b>Les saisons</b> durent 14 jours. Chacune apporte son produit de saison à 150 € : fraises chantilly au printemps, granité citron en été, latte potiron en automne, marrons chauds en hiver. Très populaires, ils supportent volontiers un prix un peu plus élevé.</li>
  <li><b>La tendance du jour</b>, affichée sur les réseaux sociaux, met un produit à l’honneur. Il part plus vite : vérifie que tu en as assez en stock.</li>
</ul>

<h2>Le marché des matières premières</h2>
<p>Le coût de tes matières premières bouge chaque jour, par famille de produits : boissons chaudes, boissons fraîches, pâtisseries et brunch peuvent devenir plus chers ou moins chers, et une pénurie peut ponctuellement frapper un ingrédient. Garde un œil sur ta marge quand les coûts grimpent : un prix qui était rentable la semaine dernière peut ne plus l’être.</p>

<h2>La méthode simple</h2>
<ol>
  <li>Commence chaque nouveau produit au prix proposé par le jeu.</li>
  <li>Monte-le par petites touches de 10 à 20 centimes tant que l’indicateur reste sur « Prix juste ».</li>
  <li>Regarde le bilan du soir : si les ventes de ce produit chutent nettement, redescends d’un cran.</li>
  <li>Une fois la recette améliorée, recommence : le prix juste a monté.</li>
</ol>
`},
{
  slug: 'guide-stock',
  icon: '📦',
  title: 'Gérer le stock et les livraisons',
  desc: 'Commandes du soir, réserve, coursier express, pertes de la nuit, pénuries et contrat fournisseur : tout pour ne jamais manquer de rien dans Comptoir & Cie.',
  intro: 'Un café sans stock, c’est un café qui ne vend rien. Bien gérer sa réserve, c’est trouver le bon compromis entre ruptures et gaspillage.',
  html: `
<h2>Comment fonctionnent les livraisons</h2>
<p>Tu passes tes commandes depuis l’onglet <b>Carte</b> ou <b>Appro</b>, de préférence le soir. Elles sont livrées à l’ouverture du lendemain. Chaque produit a son propre stock, limité par la taille de ta réserve.</p>
<p>Si un produit vient à manquer en pleine journée, le <b>coursier express</b> livre tout de suite… mais à un prix nettement plus élevé. C’est une roue de secours, pas une habitude.</p>

<h2>Agrandir la réserve</h2>
<p>Au départ, chaque produit peut stocker 40 portions. L’amélioration <b>Réserve agrandie</b> fait passer cette limite à 80, puis 150, 300 et enfin 500 portions. Plus ta carte s’étoffe et plus ta clientèle grandit, plus cette amélioration devient indispensable.</p>
<table>
  <thead><tr><th>Niveau de la réserve</th><th>Portions par produit</th><th>Prix</th></tr></thead>
  <tbody>
    <tr><td>De base</td><td>40</td><td>–</td></tr>
    <tr><td>1</td><td>80</td><td>110 €</td></tr>
    <tr><td>2</td><td>150</td><td>450 €</td></tr>
    <tr><td>3</td><td>300</td><td>1 300 €</td></tr>
    <tr><td>4</td><td>500</td><td>3 600 €</td></tr>
  </tbody>
</table>

<h2>Les pertes de la nuit</h2>
<p>Les boissons se conservent, mais pas les produits frais. Chaque nuit, environ <b>25 % des pâtisseries et du brunch invendus</b> partent à la poubelle. La <b>vitrine réfrigérée</b> (380 €, dès le niveau 2) réduit ces pertes à 8 %. Si tu vends beaucoup de gâteaux, de sandwichs ou de pancakes, c’est l’un des meilleurs investissements du jeu.</p>
<p>Astuce : commande les produits frais au plus près de tes ventes réelles. Le bilan du soir indique combien tu en as vendu ; vise un peu au-dessus, pas le double.</p>

<h2>Pénuries et grèves</h2>
<p>De temps en temps, un événement vient compliquer l’approvisionnement : une <b>pénurie</b> rend un ingrédient rare pendant quelques jours, ou une <b>grève des transporteurs</b> perturbe les livraisons. Les nouvelles du quartier t’en avertissent. Dans ces moments-là, mets en avant les produits qui ne sont pas touchés et ajuste tes prix.</p>

<h2>Le contrat fournisseur</h2>
<p>Dès le niveau 3, le <b>contrat fournisseur</b> (1 400 €) passe automatiquement chaque soir une commande pour remplir ta réserve. Tu gagnes un temps précieux, surtout quand ta carte compte plus de vingt produits. Pense quand même à vérifier de temps en temps les produits frais, pour ne pas sur-stocker.</p>

<h2>En résumé</h2>
<ul>
  <li>Commande le soir, jamais à la dernière minute.</li>
  <li>Agrandis la réserve au rythme de ta carte et de ta clientèle.</li>
  <li>Protège tes produits frais avec la vitrine réfrigérée.</li>
  <li>Garde le coursier express pour les vrais imprévus.</li>
</ul>
`},
{
  slug: 'guide-equipe',
  icon: '👥',
  title: 'Recruter et motiver son équipe',
  desc: 'Les profils à recruter dans Comptoir & Cie (novice, rapide, sympa, touche-à-tout, star du latte), les salaires, le moral, le comptoir agrandi et le responsable de la carte.',
  intro: 'Seul, tu ne pourras jamais servir une salle pleine. Une bonne équipe double, triple puis quintuple ta capacité de service. Encore faut-il choisir les bonnes personnes.',
  html: `
<h2>Quand recruter ?</h2>
<p>Le signal est simple : si la file d’attente dépasse régulièrement quatre clients et que des clients repartent à cause de l’attente, il est temps d’embaucher. Chaque personne recrutée occupe un poste au comptoir et sert en même temps que toi.</p>
<p>Au départ, le comptoir compte deux postes : le tien et un poste à pourvoir. L’amélioration <b>Comptoir agrandi</b> ajoute un poste à chaque niveau (160 €, 750 €, 2 400 €, puis 15 000 € au niveau 12 et 60 000 € au niveau 24), jusqu’à <b>sept postes</b> au total. Avec plus de postes, la file d’attente s’allonge aussi.</p>
<p>À partir du niveau 11, les <b>commis en cuisine</b> (onglet Travaux) accélèrent toutes les préparations de 10 % chacun, jusqu’à cinq commis. Ils préparent aussi les commandes à livrer, ce qui libère le comptoir. Chaque commis touche un salaire chaque soir.</p>
<p>Pour asseoir plus de monde, les <b>tables bistrot</b> montent jusqu’à six tables, et la <b>salle voisine</b> (dès le niveau 9) ajoute six places par niveau, jusqu’à 36 places.</p>

<h2>Les profils de candidats</h2>
<p>Chaque candidat a un trait de caractère qui change sa façon de travailler, et un salaire journalier qui va avec :</p>
<table>
  <thead><tr><th>Profil</th><th>Atout</th><th>Salaire par jour</th></tr></thead>
  <tbody>
    <tr><td>🌱 Novice</td><td>Débute lentement, mais progresse de 3 % de vitesse chaque jour.</td><td>16 à 24 €</td></tr>
    <tr><td>⚡ Rapide</td><td>Prépare les commandes 30 % plus vite.</td><td>34 à 44 €</td></tr>
    <tr><td>😄 Sympa</td><td>Clients plus heureux et 35 % de pourboires en plus.</td><td>30 à 40 €</td></tr>
    <tr><td>🎯 Touche-à-tout</td><td>Un peu de tout : 15 % de vitesse et de pourboires en plus.</td><td>32 à 42 €</td></tr>
    <tr><td>⭐ Star du latte</td><td>Ultra rapide et adorée des clients (dès le niveau 3).</td><td>62 à 80 €</td></tr>
    <tr><td>☕ Barista confirmé</td><td>65 % plus rapide qu’un débutant (dès le niveau 8).</td><td>110 à 140 €</td></tr>
    <tr><td>🏅 Champion de latte art</td><td>Deux fois plus rapide, et les clients adorent (dès le niveau 15).</td><td>250 à 310 €</td></tr>
    <tr><td>🎖️ Maître barista</td><td>Une vitesse folle et un service impeccable (dès le niveau 25).</td><td>580 à 720 €</td></tr>
    <tr><td>👑 Légende du comptoir</td><td>Le meilleur profil du jeu, plus de trois fois plus rapide (dès le niveau 38).</td><td>1 350 à 1 650 €</td></tr>
  </tbody>
</table>
<p>Les meilleurs profils débloqués se présentent plus souvent. Si les CV du jour ne te plaisent pas, le bouton <b>Publier une annonce</b> en fait venir de nouveaux tout de suite.</p>

<h2>Former ses employés</h2>
<p>Chaque employé peut suivre des <b>formations</b> depuis l’onglet Équipe. Un niveau de formation rend la personne 10 % plus rapide et lui fait gagner 6 % de pourboires en plus, mais son salaire augmente de 12 %. Chaque profil a un maximum : 3 niveaux pour un novice, 4 pour les profils simples, 5 pour une star ou un barista, 6 pour un champion ou un maître barista, et 7 pour une légende.</p>
<p>Quand une personne a atteint son maximum, la seule façon d’aller plus vite est de la <b>remercier</b> (après la fermeture) et de recruter un profil plus doué, puis de le former à son tour. Une équipe rapide prend aussi les commandes plus vite au comptoir : c’est le meilleur moyen d’éviter que les clients repartent.</p>
<p>En tout début de partie, un <b>novice</b> est souvent le meilleur choix : il coûte peu et devient efficace en quelques jours. Plus tard, quand la salle est pleine, un profil <b>rapide</b> fait la différence aux heures de pointe, et un profil <b>sympa</b> rapporte gros si tu as des tables et une terrasse.</p>

<h2>Le moral de l’équipe</h2>
<p>Chaque membre de l’équipe a un moral. Une équipe heureuse travaille mieux. Les primes, disponibles dans l’onglet Équipe, remontent le moral quand il faiblit. Garde aussi un œil sur la masse salariale dans le bilan : les salaires sont payés chaque soir, que la journée ait été bonne ou non.</p>

<h2>Le responsable de la carte</h2>
<p>À partir du niveau 4, tu peux embaucher un <b>responsable de la carte</b>. Son coût est élevé : 3 000 € à l’embauche, puis 150 € par jour. Mais chaque soir, il s’occupe à ta place :</p>
<ul>
  <li>d’ajouter de nouveaux produits à la carte ;</li>
  <li>d’améliorer les recettes jusqu’à trois étoiles ;</li>
  <li>de mener des tests au labo de création, en ne gardant que les bonnes recettes.</li>
</ul>
<p>Tu choisis ses missions et la réserve d’argent qu’il doit toujours laisser en caisse. C’est l’embauche idéale quand ta carte devient trop grande pour être gérée à la main.</p>

<h2>Le bras droit</h2>
<p>Au niveau 5, l’amélioration <b>Bras droit</b> (4 500 €) ramasse les pourboires, répond aux avis négatifs et débloque le mode continu : les journées s’enchaînent toutes seules pendant que tu gères ton groupe.</p>
`},
{
  slug: 'guide-labo',
  icon: '🧪',
  title: 'Le labo de création : inventer ses recettes',
  desc: 'Comment fonctionne le labo de Comptoir & Cie : bases, parfums, étoiles, créations signature et quelques associations gagnantes pour démarrer.',
  intro: 'Au niveau 3, le labo de création ouvre ses portes. Tu y associes une base et un parfum pour inventer des recettes signature, que tu es seul à proposer.',
  html: `
<h2>Le principe</h2>
<p>Dans l’onglet <b>Labo</b>, choisis une <b>base</b> et un <b>parfum</b>, puis lance les tests. Le résultat arrive le lendemain matin, après le bilan du soir : ta recette reçoit une note de une à cinq étoiles.</p>
<p>Six bases sont disponibles : <b>café</b>, <b>thé</b>, <b>chocolat</b>, <b>boisson glacée</b>, <b>tartelette</b> et <b>tartine</b>. Elles se combinent avec neuf parfums : vanille, caramel, pistache, framboise, épices, coco, noisette, citron et miel. Cela fait 54 associations à découvrir.</p>

<h2>Que valent les étoiles ?</h2>
<p>Plus une création a d’étoiles, plus son prix conseillé est élevé et plus elle est populaire. Une recette cinq étoiles devient vite l’un des produits les plus rentables de ta carte. Une recette à une ou deux étoiles peut quand même être proposée, mais elle se vendra mal.</p>
<p>Ta carte signature peut accueillir <b>cinq créations</b> au maximum. Pour en tester une nouvelle quand elle est pleine, retire d’abord la moins bonne. Chaque recette testée reste notée dans ton carnet : tu ne perds jamais une découverte.</p>

<h2>Quelques pistes pour démarrer</h2>
<p>Sans tout dévoiler, voici des associations qui ont fait leurs preuves auprès des testeurs :</p>
<ul>
  <li><b>Café caramel</b> et <b>café noisette</b> : des classiques indémodables.</li>
  <li><b>Thé citron</b> : frais et réconfortant à la fois.</li>
  <li><b>Chocolat noisette</b> : un succès garanti par temps froid.</li>
  <li><b>Boisson glacée framboise</b> : la star des journées ensoleillées.</li>
  <li><b>Tartelette pistache</b> : la gourmandise chic par excellence.</li>
</ul>
<p>D’autres associations atteignent aussi les cinq étoiles. À l’inverse, certaines sont franchement ratées : le café au citron, par exemple, n’a convaincu personne. À toi d’explorer.</p>

<h2>Bien utiliser ses créations</h2>
<ul>
  <li>Une création arrive sur la carte avec dix portions offertes : profites-en pour tester son prix.</li>
  <li>Comme les autres produits, elle profite des recettes ★★★, de la maîtrise et de la tendance du jour.</li>
  <li>Le responsable de la carte peut mener les tests à ta place et ne garder que les recettes d’au moins trois étoiles.</li>
</ul>
`},
{
  slug: 'guide-empire',
  icon: '🏢',
  title: 'Du petit café à l’empire mondial',
  desc: 'Créer sa société, ouvrir de nouvelles adresses, racheter les concurrents, emprunter et lancer sa franchise jusqu’à l’international dans Comptoir & Cie.',
  intro: 'Une fois ton café bien installé, l’aventure change d’échelle : société, succursales, rachats, franchise et paliers jusqu’à l’empire mondial.',
  html: `
<h2>Créer sa société</h2>
<p>Dans l’onglet <b>Groupe</b>, tu peux fonder ta société dès que ton café atteint le niveau 3 et que tu as 1 200 € en caisse. La création coûte 800 €. Elle te permet d’ouvrir de nouvelles adresses, de racheter tes concurrents et d’emprunter de plus grosses sommes.</p>

<h2>Ouvrir de nouvelles adresses</h2>
<p>Chaque quartier a son public, son potentiel et son loyer :</p>
<table>
  <thead><tr><th>Quartier</th><th>Ouverture</th><th>Potentiel</th><th>Loyer par jour</th></tr></thead>
  <tbody>
    <tr><td>🎓 Campus universitaire</td><td>3 000 €</td><td>×1</td><td>45 €</td></tr>
    <tr><td>🚉 Quartier de la gare</td><td>4 000 €</td><td>×1,2</td><td>70 €</td></tr>
    <tr><td>🏰 Vieille ville (niveau 4)</td><td>6 000 €</td><td>×1,45</td><td>90 €</td></tr>
    <tr><td>🏙️ Quartier d’affaires (niveau 5)</td><td>9 000 €</td><td>×1,8</td><td>120 €</td></tr>
    <tr><td>🌊 Bord du canal (niveau 6)</td><td>12 000 €</td><td>×2,2</td><td>150 €</td></tr>
  </tbody>
</table>
<p>Chaque adresse est tenue par une personne en gérance, plus ou moins douée. Tu peux rénover tes adresses jusqu’au niveau 5 pour augmenter leurs ventes, et changer de gérance si les résultats déçoivent.</p>

<h2>Racheter la concurrence</h2>
<p>Ton quartier compte quatre concurrents : une boulangerie, un bar à bubble tea, une chaîne de coffee shops et un salon de thé. L’onglet <b>Quartier</b> montre leurs parts de marché, leur réputation et leurs difficultés. Un concurrent en difficulté se rachète moins cher. Chaque rachat devient une nouvelle adresse de ton groupe et t’apporte une partie de ses abonnés.</p>

<h2>Bien utiliser la banque</h2>
<table>
  <thead><tr><th>Emprunt</th><th>Montant</th><th>Coût</th><th>Durée</th></tr></thead>
  <tbody>
    <tr><td>Microcrédit</td><td>500 €</td><td>8 %</td><td>10 soirs</td></tr>
    <tr><td>Prêt professionnel (niveau 3)</td><td>2 500 €</td><td>10 %</td><td>15 soirs</td></tr>
    <tr><td>Prêt d’investissement (niveau 4, société)</td><td>12 000 €</td><td>12 %</td><td>20 soirs</td></tr>
  </tbody>
</table>
<p>Un emprunt n’est intéressant que s’il finance quelque chose qui rapporte plus que son coût : une nouvelle adresse bien placée, une amélioration clé ou un rachat. Les remboursements sont prélevés chaque soir.</p>

<h2>Lancer la franchise</h2>
<p>Au niveau 4, avec ta société et au moins une adresse en plus de ton café, tu peux lancer ta franchise pour 2 500 €. Des candidats proposent alors d’ouvrir un Petit Comptoir dans leur ville. Ils te versent un droit d’entrée, puis des royalties chaque jour.</p>
<ul>
  <li><b>Le taux de royalties</b> : plus il est élevé, plus chaque franchisé te rapporte, mais moins tu attires de candidats.</li>
  <li><b>La charte</b> : souple (beaucoup de candidats, qualité inégale), standard, ou exigeante (moins de candidats, mais excellents).</li>
  <li><b>La prospection</b> : tu peux démarcher une ville précise pour y attirer des candidats.</li>
</ul>
<p>Le réseau couvre 23 villes, des grandes villes françaises jusqu’à Bruxelles, Genève, Londres, Montréal et New York, soit plus de cent places de franchise.</p>

<h2>Les paliers de ton groupe</h2>
<table>
  <thead><tr><th>Palier</th><th>Points de vente</th></tr></thead>
  <tbody>
    <tr><td>☕ Café indépendant</td><td>1</td></tr>
    <tr><td>🏪 Petite enseigne</td><td>3</td></tr>
    <tr><td>🔗 Chaîne régionale</td><td>8</td></tr>
    <tr><td>🗺️ Chaîne nationale</td><td>20</td></tr>
    <tr><td>🌍 Marque internationale</td><td>45</td></tr>
    <tr><td>👑 Empire mondial</td><td>90</td></tr>
  </tbody>
</table>
<p>Chaque palier rend ta marque plus attirante.</p>

<h2>Entrer en Bourse</h2>
<p>Quand ta société vaut au moins 100 000 €, l’onglet « 📈 Bourse » te permet de faire coter ton groupe. Tu vends une partie du capital, de 10 à 49 %, à des investisseurs et tu récupères aussitôt de l’argent frais. Rien n’est remis à zéro : ton café, ta caisse, tes adresses et ta progression restent intacts, et tu gardes toujours la majorité.</p>
<p>Le cours de ton action suit la valeur de ton groupe et tes bénéfices des sept derniers jours. Il bouge chaque soir avec l’humeur du marché et quelques événements : euphorie, coup de froid, article élogieux… Tu peux ensuite :</p>
<ul>
  <li><b>lever plus d’argent</b> en émettant de nouvelles actions, tant que tu gardes 51 % du capital ;</li>
  <li><b>racheter tes actions</b> pour reprendre une plus grosse part ;</li>
  <li><b>verser des dividendes</b>, de 10 à 50 % du bénéfice du jour : ils rassurent les investisseurs et font monter ton cours ;</li>
  <li><b>investir dans les groupes rivaux</b> de la ville, qui versent eux aussi un petit dividende chaque soir.</li>
</ul>
<p>Astuce : une action se vend mieux quand le cours est haut. Soigne tes bénéfices et ta réputation avant de lever de l’argent.</p>
`},
{
  slug: 'guide-multijoueur',
  icon: '🌍',
  title: 'Le multijoueur : classement, défis et clubs',
  desc: 'Rejoindre le multijoueur de Comptoir & Cie : vitrine, classement national, visites et pourboires, duels de ventes, clubs et règles de la terrasse.',
  intro: 'Dans l’onglet « En ligne », ton café rejoint ceux des autres joueurs. Tu peux te comparer à toute la France, visiter d’autres boutiques, lancer des défis et faire équipe dans un club.',
  html: `
<h2>Rejoindre en quelques secondes</h2>
<p>Il suffit d’un <b>pseudo</b>, d’un <b>nom d’enseigne</b> et d’un <b>emblème</b>. Pas besoin d’adresse e-mail ni de mot de passe : un compte anonyme est créé pour toi. Ta vitrine se met ensuite à jour toute seule chaque soir de jeu.</p>

<h2>Le classement national</h2>
<p>Le classement compare les groupes selon leur <b>valeur</b>, leurs <b>abonnés</b>, les <b>pourboires</b> reçus ou les <b>duels gagnés</b>. Seules les parties sans code secret et actives ces trente derniers jours y figurent : le classement reste juste et vivant. Un classement des <b>clubs</b> existe aussi.</p>

<h2>Visiter les autres cafés</h2>
<p>Clique sur un café du classement ou de l’annuaire pour le visiter : tu découvres sa salle avec sa décoration, ses couleurs et son équipe, ainsi que ses chiffres. Tu peux y laisser :</p>
<ul>
  <li><b>un pourboire</b>, un par café et par jour : le café qui le reçoit gagne de l’argent et des abonnés, et toi un peu d’expérience ;</li>
  <li><b>un mot dans son livre d’or</b>.</li>
</ul>

<h2>Les défis entre joueurs</h2>
<p>Depuis la vitrine d’un café ou la liste des « adversaires à ta taille », lance un <b>duel de ventes</b>. Une fois le défi accepté, chacun joue trois journées, et l’on compare les ventes au comptoir du café d’origine, sans les succursales ni la franchise. Un petit café peut donc battre un empire ! Le gagnant remporte une belle récompense, et le perdant gagne un peu d’expérience. Un défi non accepté expire au bout de 48 heures.</p>

<h2>Les clubs</h2>
<p>Un club réunit jusqu’à vingt cafés. On peut en fonder un dès le niveau 3, pour 5 000 €. Chaque semaine, les membres doivent servir ensemble un nombre de clients fixé selon la taille du club. Quand l’objectif est atteint, chaque membre récupère une récompense. Le club a aussi son <b>salon privé</b> pour discuter entre membres.</p>

<h2>La Bourse entre joueurs</h2>
<p>Si ton groupe est coté en Bourse, tu peux proposer une partie de tes actions aux autres joueurs, depuis l’onglet « 📈 Bourse ». Ils les achètent au cours de ta dernière clôture, et l’argent arrive dans ta caisse à ta prochaine connexion ou à la fin de ta journée.</p>
<p>À l’inverse, tu peux acheter des actions des cafés des autres joueurs. Chaque soir où ce café fait un bénéfice et verse un dividende, tu touches ta part. Tu peux revendre tes actions à tout moment au cours du jour, moins 2 % de frais. Si un café quitte le multijoueur, ses actionnaires sont remboursés au dernier cours. Les parties qui ont utilisé un code secret ne peuvent pas échanger d’actions avec les joueurs.</p>

<h2>La terrasse et les règles</h2>
<p>La terrasse est le salon de discussion commun de tous les joueurs. Pour que tout le monde s’y sente bien :</p>
<ul>
  <li>les insultes, les liens, les adresses e-mail, les pseudos de réseaux sociaux et les numéros de téléphone sont bloqués automatiquement ;</li>
  <li>chaque message peut être signalé, et un message signalé plusieurs fois est masqué en attendant la modération ;</li>
  <li>ne partage jamais d’informations personnelles, comme ton nom, ton adresse ou ton école.</li>
</ul>
<p>Tu peux quitter le multijoueur à tout moment depuis l’onglet « En ligne » : ta vitrine, tes messages et tes pourboires sont alors supprimés.</p>
`},
];
