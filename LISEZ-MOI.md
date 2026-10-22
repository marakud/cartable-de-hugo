# Le cartable de Harry : mise en ligne sur Vercel et Supabase

Ce guide est pour **le parent** de Harry. Il faut environ 30 minutes. Tout est gratuit, sauf Claude (voir l'étape 3).

À la fin, Harry aura son cartable à une adresse du type `https://cartable-de-harry.vercel.app`. Il tape un code secret une seule fois par appareil, puis le site s'ouvre directement.

## Ce que contient ce dossier

| Fichier | À quoi il sert |
| --- | --- |
| `index.html` | La page du cartable |
| `api/claude.js` | Demande à Claude de lire les captures Pronote et de créer les quiz. La clé Claude reste sur le serveur. |
| `api/config.js` | Donne à la page l'adresse de la base Supabase |
| `supabase/schema.sql` | Crée la table de la base. Chaque compte ne voit que ses propres données. |
| `.env.example` | La liste des réglages à mettre dans Vercel |

## 1. Créer la base Supabase

1. Créez un compte sur [supabase.com](https://supabase.com), puis un nouveau projet (région : Europe, par exemple Paris ou Francfort).
2. Dans le menu **SQL Editor**, collez tout le contenu de `supabase/schema.sql` et cliquez sur **Run**.
3. Notez l'**URL du projet** et la **clé publique**. Le plus simple : cliquez sur le bouton **Connect** en haut de la page du projet. Sinon :
    - l'URL est dans **Project Settings → Data API** (elle ressemble à `https://xxxx.supabase.co`) ;
    - la clé est dans **Project Settings → API Keys** : prenez la **Publishable key** (`sb_publishable_…`), ou la clé **anon** dans l'onglet **Legacy API Keys**. Ne prenez jamais la clé **secret** ou **service_role**.
4. Dans **Authentication → Sign In / Providers**, vérifiez que **Email** est activé, puis désactivez **Allow new users to sign up** : personne ne pourra créer de compte.
5. Dans **Authentication → Users**, cliquez sur **Add user → Create new user**. Mettez l'e-mail de Harry, choisissez un **code secret** comme mot de passe (au moins 8 caractères) et cochez **Auto Confirm User**. Aucun e-mail n'est envoyé.

## 2. Mettre le code sur GitHub

1. Créez un compte sur [github.com](https://github.com) si vous n'en avez pas.
2. Créez un dépôt **privé** nommé `cartable-de-harry`.
3. Cliquez sur **uploading an existing file**, puis glissez tout le contenu de ce dossier (avec les dossiers `api` et `supabase`). Validez avec **Commit changes**.

## 3. Créer la clé Claude

1. Créez un compte sur [console.anthropic.com](https://console.anthropic.com) et ajoutez un moyen de paiement.
2. **Fixez une limite de dépense mensuelle** (par exemple 5 €) dans **Billing → Limits**.
3. Dans **API Keys**, créez une clé et copiez-la. Elle commence par `sk-ant-`.

Pour l'ordre de grandeur : un quiz coûte environ 2 à 5 centimes, et la lecture d’une capture Pronote environ 5 à 10 centimes. Avec une limite à 5 € par mois, il n’y a pas de mauvaise surprise.

## 4. Mettre en ligne sur Vercel

1. Créez un compte sur [vercel.com](https://vercel.com) avec **Continue with GitHub**.
2. Cliquez sur **Add New → Project**, puis choisissez le dépôt `cartable-de-harry`. Laissez **Framework Preset** sur **Other**.
3. Ouvrez **Environment Variables** et ajoutez :

| Nom | Valeur |
| --- | --- |
| `SUPABASE_URL` | L'URL du projet Supabase (étape 1) |
| `SUPABASE_ANON_KEY` | La clé publique (étape 1) |
| `ANTHROPIC_API_KEY` | La clé Claude (étape 3) |
| `APP_EMAIL` | L'e-mail du compte créé à l'étape 1.5 |
| `ALLOWED_EMAILS` | Le même e-mail : seul ce compte peut utiliser Claude |

4. Cliquez sur **Deploy**. Vercel donne l'adresse du site.

## 5. Première ouverture

1. Ouvrez le site et tapez le code secret choisi à l'étape 1.5.
2. Le cartable s'ouvre. Sur cet appareil, il s'ouvrira ensuite directement, sans code.
3. Faites pareil sur le téléphone et l'ordinateur : avec le même code, Harry retrouve les mêmes données partout.

Sur le téléphone, on peut ajouter le site à l'écran d'accueil (menu **Partager → Sur l'écran d'accueil**).

## Bon à savoir

- **Sécurité** : sans le code secret, on ne voit rien. Seuls les e-mails de `ALLOWED_EMAILS` peuvent utiliser Claude, donc dépenser des crédits. La base refuse qu'un compte lise les données d'un autre.
- **Modèle** : par défaut `claude-opus-5-5`. Pour un modèle moins cher, ajoutez la variable `CLAUDE_MODEL` avec `claude-sonnet-5-5` ou `claude-haiku-5-5`, puis redéployez. Le moins cher lit un peu moins bien les captures.
- **Refus** : si Claude refuse une demande pour une raison de sécurité, l'API essaie automatiquement un autre modèle (option `fallbacks` dans `api/claude.js`).
- **Données** : elles sont dans Supabase, table `items`. On peut les exporter depuis **Table Editor → Export to CSV**.
