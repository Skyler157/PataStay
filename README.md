# PataStay

**Pata your perfect stay.** A marketplace for affordable, trustworthy short-stay accommodation in Kenya, starting with Nairobi.

Guests browse and enquire, hosts list properties for review, and administrators moderate and verify listings. The MVP connects guests and hosts through enquiries, WhatsApp and phone calls. It has no online payments or instant booking.

## Repository layout

```
apps/mobile/            Flutter app for Android and iOS (guests and hosts)
apps/admin/             Flutter Web admin dashboard
packages/patastay_core/ Shared code: config, Supabase access, models, repositories, theme, widgets
supabase/migrations/    Database schema, RLS policies and server functions (tracked in Git)
supabase/tests/         pgTAP access-control tests
supabase/seed.sql       Local development seed data only (sample listings flagged is_seed)
env/                    Build-time configuration (example.json is committed, everything else is ignored)
docs/                   Architecture and security documentation
```

The repository is a [Dart pub workspace](https://dart.dev/tools/pub/workspaces), so one `flutter pub get` at the root resolves all three packages.

## Prerequisites (Windows)

| Tool | Version | Notes |
|---|---|---|
| Flutter SDK | 3.47+ (Dart 3.13+) | Unzip from flutter.dev to `C:\Users\<you>\flutter` and add `flutter\bin` to your user PATH |
| Git | any recent version | |
| Docker Desktop | running | Runs the local Supabase stack |
| Supabase CLI | 2.120+ | `npm i -g supabase`, or download `supabase_windows_amd64.tar.gz` from the GitHub releases page |
| Android SDK + JDK 17/21 | | Install with Android Studio, or use the command-line tools only (see below) |
| Chrome | | For the admin dashboard |

iOS builds need a Mac with Xcode, or a cloud CI service such as Codemagic.

Run `flutter doctor` and fix anything it marks with ✗ for Android.

**Android without Android Studio.** Install the "Command line tools only" package to `%USERPROFILE%\Android\Sdk\cmdline-tools\latest`, install a JDK (for example Temurin 21), then run:
```powershell
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"
flutter config --android-sdk "$env:USERPROFILE\Android\Sdk"
flutter config --jdk-dir "<path to JDK>"
flutter doctor --android-licenses
```

## First-time setup

```powershell
git clone <repo-url> PataStay
cd PataStay
flutter pub get

# Generate Freezed/JSON code in the shared package
cd packages/patastay_core
dart run build_runner build
cd ../..

# Start the local backend (Postgres, Auth, Storage, Studio). This applies all
# migrations and seed.sql. The first run downloads the Docker images.
supabase start

# Create your local environment file from the template
copy env\example.json env\dev.json
# Paste the PUBLISHABLE_KEY printed by `supabase status` into env\dev.json
```

> Only use the **publishable** (anon) key in `env/*.json`. The app refuses to start if you give it a secret or service-role key.

## Maps and "Near me"

Maps use **OpenStreetMap** through `flutter_map`. They are free, with no API key and no card. Each listing shows an approximate ~350 m area; the exact pin is private (see docs/SECURITY.md). "Near me" uses the phone's GPS through `geolocator`, which is also free.

OpenStreetMap's public tile server is fine for development and early testing, but its usage policy does not allow heavy app traffic. Before a public launch, point the app at a hosted tile provider by adding these to `env/prod.json`:

```json
"MAP_TILE_URL": "https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=YOUR_KEY",
"MAP_ATTRIBUTION": "MapTiler, OpenStreetMap contributors"
```

MapTiler, Stadia Maps and Mapbox all offer free or low-cost tiers. No code changes are needed.

> **Ports.** The local stack uses ports 58320–58329 (set in `supabase/config.toml`). Windows can reserve port blocks after updates. If `supabase start` fails with "access permissions", run `netsh interface ipv4 show excludedportrange protocol=tcp` and move the ports to a free range.

## Running

```powershell
# Admin dashboard (Chrome). Port 5050 is in the allowed auth redirect URLs.
cd apps/admin
flutter run -d chrome --web-port 5050 --dart-define-from-file=../../env/dev.json

# Mobile app (Android phone connected over USB with USB debugging on, or an emulator)
cd apps/mobile
flutter devices
flutter run --dart-define-from-file=../../env/dev.json
```

**Reaching the local backend from a phone.** `127.0.0.1` points at the phone itself, not your PC.
- Android emulator: set `SUPABASE_URL` to `http://10.0.2.2:58321`.
- Physical phone on the same Wi-Fi: use your PC's LAN IP (run `ipconfig`), for example `http://192.168.1.20:58321`, and allow port 58321 through Windows Firewall.
- Physical phone over USB: run `adb reverse tcp:58321 tcp:58321` and keep `http://127.0.0.1:58321`. The link drops whenever the USB connection blips; `tools/keep-phone-linked.ps1` re-creates it automatically.

### Local accounts (seed data)

Every account uses the password `PataStay#Dev2026`. `supabase db reset` deletes any other accounts you created locally.

| Email | Role |
|---|---|
| admin@patastay.local | Administrator |
| owner@patastay.local | Host (owns 6 sample listings) |
| guest@patastay.local | Guest |

- Supabase Studio: http://127.0.0.1:58323
- Local email inbox (password resets, confirmations): http://127.0.0.1:58324

## Database migrations

```powershell
supabase migration new <descriptive_name>   # create a new migration file
supabase db reset                           # rebuild the local DB from migrations + seed
supabase db diff                            # compare the local DB with the migrations
supabase link --project-ref <ref>           # link a hosted project (once)
supabase db push                            # apply pending migrations to the hosted project
```

Never edit a migration that has already been pushed to a hosted project. Add a new one instead. Every new table needs `enable row level security`, explicit `grant`s and policies (see [docs/SECURITY.md](docs/SECURITY.md)).

## Tests

```powershell
supabase test db                                    # database access-control tests (pgTAP)
cd packages/patastay_core; flutter test; cd ../..   # shared unit tests
cd apps/mobile; flutter test; cd ../..              # mobile widget tests
cd apps/admin; flutter test; cd ../..               # admin widget tests
flutter analyze                                     # run inside each package
```

## Building releases

```powershell
cd apps/mobile
flutter build appbundle --release --dart-define-from-file=../../env/prod.json   # Google Play
flutter build apk --release --dart-define-from-file=../../env/prod.json         # sideload/testing
cd ../admin
flutter build web --release --dart-define-from-file=../../env/prod.json         # deploy build/web to any static host
```

Android release signing requires `apps/mobile/android/key.properties` and a keystore. Neither is ever committed.

## Hosted Supabase setup (staging/production)

1. Create a project at supabase.com (choose a region close to Kenya, such as `eu-west` or `af-south` if available).
2. Run `supabase link --project-ref <ref>`, then `supabase db push`. Do **not** run `seed.sql` in production.
3. Under Auth > URL Configuration, add the redirect URLs `com.patastay.app://login-callback` and your admin site URL.
4. Under Auth > Providers > Email, turn email confirmation on and set the password policy to 8+ characters with letters and digits.
5. Configure custom SMTP for auth emails (the built-in sender is rate-limited).
6. Create the first administrator: sign up normally, then run this in the SQL editor:
   `update public.profiles set role = 'admin' where email = 'you@example.com';`
   (Clients cannot do this. Role changes are blocked for every API caller.)
7. Copy the project URL and publishable key into `env/prod.json`.

## Build status

| Phase | Status |
|---|---|
| 1. Foundation: schema, RLS, auth, profiles, routing, theme, admin sign-in and stats | Done |
| 2. Guest marketplace: home, search and filters, details, favourites, enquiries, WhatsApp/call contact, reports | Done |
| 3. Host tools: listing wizard, photos, enquiries, statistics | Next |
| 4. Administration: review queue, verification, reports, users, exports | Planned |
| 5. Quality and launch | Planned |

Known launch requirement: account-deletion requests (`profiles.deletion_requested_at`) must be processed within 30 days, as the app promises. A service-role Edge Function and admin action for this are planned for Phase 4.
