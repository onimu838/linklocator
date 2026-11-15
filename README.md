# 🔗 LinkLocator

Self-hosted link tracker and shortener with click analytics, geolocation, GPS tracking, tracking pixels, visitor stitching, conversion webhooks, SMS sending, and Street View.

## Features

- **Short links** — Create tracked short links with custom slugs
- **Click analytics** — Track IP, location, referrer, device for every click
- **IP geolocation** — ipgeolocation.io (primary) → ipwhois.app (free HTTPS fallback) → ip-api.com (HTTP fallback), 1hr cache
- **GPS tracking** — Browser geolocation on click (Redirect mode) or continuous tracking (Embed mode)
- **Embed mode** — Destination loads in iframe while parent tracks GPS position continuously
- **Location pings** — Continuous GPS pings stored per click, viewable in dashboard with OpenStreetMap
- **Tracking pixels** — Invisible 1x1 GIF endpoint records opens (email, web pages) without JavaScript
- **Visitor stitching** — `ll_vid` cookie + localStorage identifies same visitor across all your links
- **Conversion webhooks** — Forward click events server-side to Facebook CAPI, Google Ads, Zapier, or any URL
- **Deep device fingerprinting** — Browser, OS, device type, Client Hints, GPU, screen, touch, connection, memory, cores, WebRTC, DNT
- **SMS sending** — Send links via SMS: SignalWire, Telnyx, Vonage, or custom webhook
- **Street View** — Click any location coordinate to see Google Street View
- **Analytics dashboard** — Clicks by day/country/city, unique IPs, unique visitors, GPS accuracy indicators
- **Supabase backend** — Postgres with RLS, RPC functions for analytics

## Deploy to Production

### 1. Create a Supabase project

Go to [supabase.com](https://supabase.com) and create a new project. Save your:
- **Project URL**: `https://xxxxx.supabase.co`
- **Service role key**: `sb_secret_...` (Project Settings → API)

### 2. Run database migrations

Go to **SQL Editor** in your Supabase dashboard and run these files **in order**:

1. `supabase/migrations/20261108000000_initial.sql` — tables, indexes, RLS, RPC functions
2. `supabase/migrations/20261112000000_device_info.sql` — device fingerprinting columns
3. `supabase/migrations/20261113000000_visitor_tracking.sql` — visitor_id column
4. `supabase/migrations/20261113000001_webhooks.sql` — webhook_url column
5. `supabase/migrations/20261113000002_stats_unique_visitors.sql` — updated stats RPC

Or use the Supabase CLI:
```bash
supabase link --project-ref your-project-ref
supabase db push
```

### 3. Deploy to Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app)

1. Push your repo to GitHub
2. In Railway: **New Project** → **Deploy from GitHub repo** → select your repo
3. Railway auto-detects Node.js via `nixpacks.toml`
4. Set **environment variables**:

| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | ✅ | `https://xxxxx.supabase.co` |
| `SUPABASE_SERVICE_KEY` | ✅ | `sb_secret_...` (service role key) |
| `GEO_API_KEY` | Recommended | [ipgeolocation.io](https://ipgeolocation.io) key (without this, falls back to free providers) |
| `BASE_URL` | Optional | Override auto-detected URL for short links |
| `SMS_PROVIDER` | Optional | `signalwire` (default), `telnyx`, `vonage`, `webhook` |
| `SMS_FROM` | Optional | Sender phone number (E.164) |
| `SIGNALWIRE_SPACE` | Optional | SignalWire space name |
| `SIGNALWIRE_PROJECT_ID` | Optional | SignalWire project ID |
| `SIGNALWIRE_API_TOKEN` | Optional | SignalWire API token |

5. Railway assigns a `PORT` automatically — no need to set it
6. Deploy! Railway gives you a URL like `linklocator-production.up.railway.app`

### 4. Verify

1. Open your Railway URL → dashboard should load
2. Create a test link → `https://your-railway-url/test123`
3. Visit the short link → should redirect
4. Click "Details" → should see click with geo data

## Local Development

```bash
git clone https://github.com/fox1984/linklocator.git
cd linklocator
npm install
cp .env.example .env
# Edit .env with your Supabase credentials
node server.js
```

Open `http://localhost:3000` for the dashboard.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/links` | Create a short link |
| `GET` | `/api/links` | List all links with click counts |
| `GET` | `/api/links/:slug` | Get link detail + analytics |
| `PATCH` | `/api/links/:slug` | Update link (mode, GPS, webhook, label, destination) |
| `PATCH` | `/api/links/:slug/toggle` | Toggle active/paused |
| `DELETE` | `/api/links/:slug` | Delete link + click data |
| `POST` | `/api/click` | Record a click (called by interstitial) |
| `POST` | `/api/ping` | Record GPS ping (embed mode) |
| `GET` | `/api/pixel/:slug` | 1x1 tracking pixel GIF (for emails, embeds) |
| `POST` | `/api/links/:slug/sms` | Send link via SMS |
| `GET` | `/api/sms/status` | Check SMS provider configuration |
| `GET` | `/api/whoami` | Debug: show your IP + geo |
| `GET` | `/api/health` | Health check |
| `GET` | `/:slug` | Interstitial page (redirects or embeds) |

## Tracking Modes

### Redirect (default)
Interstitial page tries browser GPS → records click → JavaScript redirect to destination. Falls back to meta-refresh after 6 seconds if GPS permission blocks the page.

### Embed + GPS
Destination loads in a full-screen iframe. Parent frame runs `watchPosition` and sends GPS pings every N seconds via `/api/ping`. Pings pause when tab is hidden and resume when visible.

> **Note:** Embed mode only works for destinations that allow iframing. Sites with `X-Frame-Options: DENY/SAMEORIGIN` or `CSP: frame-ancestors 'none'` will block the iframe. LinkLocator checks this at creation time and warns you.

## Tracking Pixels

Invisible 1x1 GIF that records a click when loaded — works in emails, web pages, anywhere images are allowed:

```html
<img src="https://your-domain/api/pixel/abc123" width="1" height="1">
```

The pixel endpoint:
- Records IP, geo, device, referrer
- Sets `ll_vid` visitor cookie
- Fires conversion webhook if configured
- Returns a real GIF (no 404 or weird response that gets blocked)

## Visitor Tracking

Every visitor gets a `ll_vid` cookie (1 year, first-party to your domain). This lets you:

- **Stitch visits across links** — same person clicking multiple links shows the same `visitor_id`
- **Count unique visitors** — separate from unique IPs (NAT/shared IPs count as one IP, multiple visitors)
- **Query by visitor** — `SELECT * FROM clicks WHERE visitor_id = 'v_abc123'` shows all their activity

Works via cookie + localStorage fallback. No third-party cookies needed.

## Conversion Webhooks

Set a webhook URL on any link. Every click POSTs a JSON payload server-side:

```json
{
  "event": "click",
  "slug": "abc123",
  "destination": "https://example.com",
  "label": "Ad Campaign",
  "click": {
    "click_id": 42,
    "ip": "98.137.11.157",
    "country": "United States",
    "city": "Quincy",
    "browser": "Chrome 131",
    "os": "Windows 11",
    "device_type": "desktop",
    "visitor_id": "v_abc123"
  },
  "timestamp": "2026-11-13T04:07:48.000Z"
}
```

**Facebook Conversions API (CAPI):**
```
Webhook URL: https://graph.facebook.com/v18.0/<PIXEL_ID>/events?access_token=<TOKEN>
```

**Google Ads Enhanced Conversions:**
Point webhook to a Cloud Function that calls the Google Ads API.

**Zapier / Make:**
Use a webhook catch URL to trigger any workflow.

## SMS Providers

Set `SMS_PROVIDER` to one of:

| Provider | Env Vars Required |
|----------|-------------------|
| `signalwire` (default) | `SIGNALWIRE_SPACE`, `SIGNALWIRE_PROJECT_ID`, `SIGNALWIRE_API_TOKEN`, `SMS_FROM` |
| `telnyx` | `TELNYX_API_KEY`, `SMS_FROM` |
| `vonage` | `VONAGE_API_KEY`, `VONAGE_API_SECRET`, `SMS_FROM` |
| `webhook` | `SMS_WEBHOOK_URL` |

## Database Schema

| Table | Columns |
|-------|---------|
| `links` | id, slug, destination, label, tracking_mode, gps_interval, max_pings, webhook_url, created_at, active |
| `clicks` | id, link_id, ip, referrer, user_agent, country, region, city, lat, lon, isp, gps_accuracy, browser, os, device_type, device_json, visitor_id, clicked_at |
| `location_pings` | id, click_id, lat, lon, accuracy, pinged_at |

## Security

- Security headers (CSP, HSTS, X-Frame-Options, Accept-CH, etc.)
- Slug validation: alphanumeric + hyphens/underscores only, max 64 chars
- Reserved slugs: `api`, `health`, `links`, `sms`, `whoami`, `click`, `favicon`, `robots`, `pixel`
- Link count cap: 1000
- SMS recipient cap: 50 per request
- E.164 phone validation
- Destination URL validation (http/https only, no self-referential)
- XSS prevention in interstitial HTML
- Supabase RLS policies (anon: read active links + insert clicks/pings)

## License

MIT
