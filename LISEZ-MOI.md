# Le cartable : mise en ligne sur Vercel et Supabase

Ce guide est pour **le parent** qui installe le site. Il faut environ 30 minutes. Tout est gratuit, sauf Claude (voir l'étape 3).

À la fin, le site est en ligne à une adresse du type `https://cartable-de-hugo.vercel.app`. Chaque parent peut y **créer un compte pour son enfant** (un compte = un enfant). On se connecte une seule fois par appareil, puis le site s'ouvre directement.

> **Le site est déjà en ligne ?** Faites seulement : relancer `supabase/schema.sql` (étape 1.2, sans danger pour les données), les étapes 1.4 et 1.5, mettre `ALLOWED_EMAILS` à `*` sur Vercel (étape 4), puis redéployer. `APP_EMAIL` ne sert plus, vous pouvez la supprimer.

## Ce que contient ce dossier

| Fichier | À quoi il sert |
| --- | --- |
| `index.html` | La page du cartable |
| `api/claude.js` | Demande à Claude de lire les captures Pronote et de créer les quiz. La clé Claude reste sur le serveur. |
| `api/config.js` | Donne à la page l'adresse de la base Supabase |
| `supabase/schema.sql` | Crée les tables de la base. Chaque compte ne voit que ses propres données. |
| `.env.example` | La liste des réglages à mettre dans Vercel |

## 1. Créer la base Supabase

1. Créez un compte sur [supabase.com](https://supabase.com), puis un nouveau projet (région : Europe, par exemple Paris ou Francfort).
2. Dans le menu **SQL Editor**, collez tout le contenu de `supabase/schema.sql` et cliquez sur **Run**.
3. Notez l'**URL du projet** et la **clé publique**. Le plus simple : cliquez sur le bouton **Connect** en haut de la page du projet. Sinon :
    - l'URL est dans **Project Settings → Data API** (elle ressemble à `https://xxxx.supabase.co`) ;
    - la clé est dans **Project Settings → API Keys** : prenez la **Publishable key** (`sb_publishable_…`), ou la clé **anon** dans l'onglet **Legacy API Keys**. Ne prenez jamais la clé **secret** ou **service_role**.
4. Dans **Authentication → Sign In / Providers** :
    - vérifiez que **Email** est activé et que **Allow new users to sign up** est **activé** (sinon personne ne peut créer de compte) ;
    - choisissez pour **Confirm email** (voir plus bas, « E-mails ») : **désactivé** pour commencer simplement, ou activé si vous avez branché un service d'e-mail.
5. Dans **Authentication → URL Configuration**, mettez l'adresse du site Vercel dans **Site URL** (par exemple `https://cartable-de-hugo.vercel.app`). Les liens envoyés par e-mail ramènent à cette adresse.

## 2. Mettre le code sur GitHub

1. Créez un compte sur [github.com](https://github.com) si vous n'en avez pas.
2. Créez un dépôt **privé** nommé `cartable-de-hugo`.
3. Cliquez sur **uploading an existing file**, puis glissez tout le contenu de ce dossier (avec les dossiers `api` et `supabase`). Validez avec **Commit changes**.

## 3. Créer la clé Claude

1. Créez un compte sur [console.anthropic.com](https://console.anthropic.com) et ajoutez un moyen de paiement.
2. **Fixez une limite de dépense mensuelle** (par exemple 5 €) dans **Billing → Limits**.
3. Dans **API Keys**, créez une clé et copiez-la. Elle commence par `sk-ant-`.

Pour l'ordre de grandeur : un quiz coûte environ 2 à 5 centimes, et la lecture d’une capture Pronote environ 5 à 10 centimes. Avec une limite à 5 € par mois, il n’y a pas de mauvaise surprise.

## 4. Mettre en ligne sur Vercel

1. Créez un compte sur [vercel.com](https://vercel.com) avec **Continue with GitHub**.
2. Cliquez sur **Add New → Project**, puis choisissez le dépôt `cartable-de-hugo`. Laissez **Framework Preset** sur **Other**.
3. Ouvrez **Environment Variables** et ajoutez :

| Nom | Valeur |
| --- | --- |
| `SUPABASE_URL` | L'URL du projet Supabase (étape 1) |
| `SUPABASE_ANON_KEY` | La clé publique (étape 1) |
| `ANTHROPIC_API_KEY` | La clé Claude (étape 3) |
| `ALLOWED_EMAILS` | `*` pour que tous les comptes puissent utiliser Claude, ou une liste d'e-mails séparés par des virgules |
| `CLAUDE_DAILY_LIMIT` | Facultatif : nombre d'appels à Claude par compte et par jour (30 par défaut) |

4. Cliquez sur **Deploy**. Vercel donne l'adresse du site.

## 5. Première ouverture

1. Ouvrez le site et cliquez sur **Créer un compte (parents)**.
2. Donnez le prénom et la classe de l'enfant, votre e-mail et un mot de passe (8 caractères au moins).
3. Le cartable s'ouvre (ou, si **Confirm email** est activé, cliquez d'abord sur le lien reçu par e-mail). Sur cet appareil, il s'ouvrira ensuite directement.
4. Sur un autre appareil, cliquez sur **J'ai déjà un compte** avec le même e-mail et le même mot de passe : on retrouve les mêmes données.
5. Pour un deuxième enfant, créez un deuxième compte avec une autre adresse e-mail.

Sur le téléphone, on peut ajouter le site à l'écran d'accueil (menu **Partager → Sur l'écran d'accueil**).

## Bon à savoir

- **Sécurité** : sans se connecter, on ne voit rien. La base refuse qu'un compte lise les données d'un autre.
- **Coût de Claude** : c'est votre clé qui paie pour tous les comptes. Chaque compte a droit à `CLAUDE_DAILY_LIMIT` appels par jour (30 par défaut), et la limite mensuelle de l'étape 3 protège le total. Pour réserver Claude à certains comptes, mettez leurs e-mails dans `ALLOWED_EMAILS` au lieu de `*`.
- **E-mails** : le service d'e-mail fourni par Supabase n'envoie qu'aux membres de votre équipe Supabase, et très peu par heure. Pour que les autres parents reçoivent la confirmation de compte et le lien **Mot de passe oublié**, branchez un service d'e-mail (par exemple [Resend](https://resend.com), gratuit jusqu'à 3 000 e-mails par mois) dans **Authentication → Emails → SMTP Settings**. Sans cela, laissez **Confirm email** désactivé ; « Mot de passe oublié » ne marchera pas, mais vous pourrez changer un mot de passe dans **Authentication → Users**.
- **Vie privée** : le site garde des données sur des enfants (notes, devoirs). Si vous l'ouvrez à d'autres familles, dites-leur clairement ce qui est enregistré et où (Supabase), et supprimez un compte sur demande dans **Authentication → Users** (ses données partent avec lui).
- **Modèle** : par défaut `claude-opus-5-5`. Pour un modèle moins cher, ajoutez la variable `CLAUDE_MODEL` avec `claude-sonnet-5-5` ou `claude-haiku-5-5`, puis redéployez. Le moins cher lit un peu moins bien les captures.
- **Refus** : si Claude refuse une demande pour une raison de sécurité, l'API essaie automatiquement un autre modèle (option `fallbacks` dans `api/claude.js`).
- **Données** : elles sont dans Supabase, table `items`. On peut les exporter depuis **Table Editor → Export to CSV**.
