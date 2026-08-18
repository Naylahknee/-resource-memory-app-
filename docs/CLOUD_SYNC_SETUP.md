# Cloud sync setup

Resource Memory is local-first: Hive remains the fast offline cache on each device. Cross-device sync uses a Cloudflare Worker API, Neon Postgres for canonical resource data, and Cloudflare R2 for uploaded files.

## Architecture

```text
Flutter web / desktop / mobile
        |
        v
Cloudflare Worker API
   |              |
   v              v
Neon Postgres     R2
resources/auth    dropped files/screenshots
```

The Flutter client never receives the Neon database connection string.

## 1. Create Neon

Create a Neon project and copy its Postgres connection string.

Run `worker/schema.sql` against the Neon database. It creates:

- `users`
- `sessions`
- `resources`

## 2. Create the R2 bucket

Create an R2 bucket named:

```text
resource-memory-files
```

`worker/wrangler.jsonc` already declares it as the `RESOURCE_FILES` binding.

## 3. Configure and deploy the Worker

From the `worker` directory:

```bash
npm install
npx wrangler secret put DATABASE_URL
npm run deploy
```

Enter the Neon connection string when Wrangler asks for `DATABASE_URL`.

The Worker exposes:

```text
POST   /auth/register
POST   /auth/login
POST   /auth/logout
GET    /resources
PUT    /resources/:id
DELETE /resources/:id
POST   /sync
POST   /uploads/:resourceId
GET    /assets/:resourceId
GET    /health
```

Passwords are derived with PBKDF2 in the Worker. Session tokens are hashed before being stored in Neon.

## 4. Connect the Flutter deployment

After deploying the Worker, copy its public URL.

In GitHub repository Settings → Secrets and variables → Actions, add:

```text
RESOURCE_API_URL=https://resource-memory-api.YOUR-SUBDOMAIN.workers.dev
```

The GitHub Pages workflow passes this value to Flutter with `--dart-define`.

For local/native Flutter builds:

```bash
flutter run \
  --dart-define=RESOURCE_API_URL=https://resource-memory-api.YOUR-SUBDOMAIN.workers.dev
```

## Sync behavior

- Hive remains the local/offline copy.
- A Resource Memory email/password account can be used on desktop, web, Android, and iOS.
- Saving or deleting while signed in mirrors resource metadata through the Worker into Neon.
- `Sync now` uploads the local library and pulls the canonical library back down.
- Dropped files and screenshots upload their bytes to R2 when sync is connected.
- Each synced file Resource stores an `assetPath` that points to its authenticated R2 endpoint.
- The Worker can return the original bytes through `GET /assets/:resourceId` on another signed-in device.
- The Neon database credential stays only in the Worker secret store.

## Remaining presentation pass

The storage and transfer path is wired. The next UI pass should render/download a synced `assetPath` from the Resource detail screen so a remote screenshot or file can be opened directly after it arrives on another device.
