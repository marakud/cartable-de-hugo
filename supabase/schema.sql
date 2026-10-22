-- Le cartable de Harry : une seule table. Chaque ligne est un élément
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
