-- Le cartable : une table principale, un compte par enfant. Chaque ligne est un élément
-- (un cours, un devoir, une note, une leçon vue, une erreur, ou les réglages).
create table if not exists public.items (
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  collection text not null check (collection in ('edt','devoirs','notes','vu','erreurs','config')),
  id         text not null,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, collection, id)
);

-- Sécurité : chaque compte ne voit et ne modifie que ses propres lignes.
alter table public.items enable row level security;

drop policy if exists "lire mes items" on public.items;
create policy "lire mes items" on public.items for select using (auth.uid() = user_id);
drop policy if exists "ajouter mes items" on public.items;
create policy "ajouter mes items" on public.items for insert with check (auth.uid() = user_id);
drop policy if exists "modifier mes items" on public.items;
create policy "modifier mes items" on public.items for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists "supprimer mes items" on public.items;
create policy "supprimer mes items" on public.items for delete using (auth.uid() = user_id);

create or replace function public.touch_items() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;
drop trigger if exists items_touch on public.items;
create trigger items_touch before update on public.items for each row execute function public.touch_items();

-- Mise à jour en direct entre le téléphone et l'ordinateur.
alter table public.items replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.items;
exception when duplicate_object then null; end $$;

-- Compteur d'appels à Claude : /api/claude ajoute une ligne à chaque appel et refuse
-- au-delà de CLAUDE_DAILY_LIMIT par jour. Pas de règle de suppression : on ne peut pas effacer son compteur.
create table if not exists public.claude_usage (
  id         bigint generated always as identity primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create index if not exists claude_usage_user_day on public.claude_usage (user_id, created_at);
alter table public.claude_usage enable row level security;
drop policy if exists "lire mon compteur" on public.claude_usage;
create policy "lire mon compteur" on public.claude_usage for select using (auth.uid() = user_id);
drop policy if exists "ajouter a mon compteur" on public.claude_usage;
create policy "ajouter a mon compteur" on public.claude_usage for insert with check (auth.uid() = user_id);
