# Cloud sync setup

Resource Memory keeps Hive as the local cache and mirrors resources to Supabase when a user connects a sync account. The same email/password account can be used on desktop, web, Android, and iOS.

## 1. Create a Supabase project

Create a project and copy the Project URL and publishable key.

## 2. Create the resources table

Run this SQL in the Supabase SQL editor:

```sql
create table if not exists public.resources (
  id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

alter table public.resources enable row level security;

create policy "users can read their resources"
on public.resources for select
using (auth.uid() = user_id);

create policy "users can insert their resources"
on public.resources for insert
with check (auth.uid() = user_id);

create policy "users can update their resources"
on public.resources for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can delete their resources"
on public.resources for delete
using (auth.uid() = user_id);

grant select, insert, update, delete on public.resources to authenticated;
```

## 3. Add GitHub repository secrets

In GitHub → repository Settings → Secrets and variables → Actions, add:

- `SUPABASE_URL`
- `SUPABASE_PUBLISHABLE_KEY`

The GitHub Pages workflow passes these into Flutter using `--dart-define`.

## 4. Native builds

Pass the same values when building locally:

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_PROJECT_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

The Supabase publishable key is designed for client applications. Do not use a secret or service-role key in the app. Row Level Security is what protects each user's rows.

## 5. Authentication behavior

The current V1 sync screen supports email/password signup and login. If email confirmation is enabled in Supabase Auth, a new user must confirm their email before the first authenticated sync can complete.

## Sync behavior

- Hive remains the local copy for fast/offline use.
- Saving or deleting while signed in mirrors the change to Supabase.
- `Sync now` uploads local resources, downloads cloud resources, and merges them by resource ID.
- Signing into the same account on another device gives that device access to the same resource library.
