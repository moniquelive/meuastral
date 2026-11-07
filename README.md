# MeuAstral

MeuAstral is a bilingual Hugo site with an Elm-powered interactive reading and a Cloudflare Worker API. The site combines daily horoscope content, biorhythm cycles, and ascended-master correspondences in Portuguese and English.

## Stack

- Hugo renders localized editorial pages and metadata.
- Elm renders the interactive reading.
- Tailwind CSS, DaisyUI, and project CSS provide the UI styles.
- A Cloudflare Worker serves static assets and normalizes horoscope-provider responses.
- Mise pins the Node, Hugo, Elm, formatting, testing, and Wrangler toolchain.

## Local setup

```sh
mise install
mise run install
mise run dev
```

The development server uses Wrangler and normally listens on `http://localhost:8787/`. Both horoscope sources are public and require no API key. Wrangler provides a local Durable Object store for the daily cache.

## Commands

```sh
mise run format:check  # validate Elm formatting
mise run test          # run Elm and Worker tests
mise run build         # create the production bundle in build/
mise run check:build   # validate generated HTML, sitemap, and local references
mise run ci            # run the complete local/CI quality gate
mise run clean         # remove generated output and local Elm caches
```

Use `npm run test:watch` for an interactive Elm test loop. Prefer the Mise tasks for repeatable repository workflows.

## Project layout

- `content/pt-br/` and `content/en/` contain localized Hugo content.
- `themes/meuastral/layouts/` contains HTML templates and metadata partials.
- `themes/meuastral/static/site.css` styles the Hugo shell.
- `src/` contains Elm modules, the browser bootstrap, and component CSS.
- `worker/` contains request routing and the horoscope-provider boundary.
- `tests/` contains Elm and Node test suites.
- `scripts/` contains dependency installation, production build, development, and build-validation scripts.
- `public/` contains source static assets copied into the production build. Numbered PNG portraits are archival sources; the optimized WebP counterparts are shipped.
- `build/` is generated and must not be edited by hand.

## Architecture notes

The Worker handles `/api/horoscope` before static assets. Portuguese requests use Terra; English requests use the [Zodiac Timeline feed](https://zodiactimeline.com/horoscope-api/), with visible attribution beside English readings. The feed contains all twelve signs for several dates; the adapter selects the configured São Paulo date. Provider payloads are normalized to one public response shape. Static HTML falls through to Cloudflare Assets.

One SQLite-backed Durable Object per locale stores the latest complete daily snapshot. Requests from every Cloudflare data center share it, and simultaneous misses share one provider fetch. A normal day therefore needs one English feed request and one Terra request globally, including monitoring. The edge Cache API remains a fast local layer; its expiry and browser caching are capped at São Paulo midnight. The API exposes the snapshot date and provider through `X-Horoscope-Date` and `X-Horoscope-Provider`.

Only complete, unique twelve-sign snapshots are stored. Failed refreshes return non-cacheable errors and persist a five-minute retry cooldown to prevent request bursts; yesterday's readings are never presented as today's. Storage failure does not bypass the shared cache. A Worker restart reuses the persisted snapshot, though an interruption between fetching and saving may require a duplicate fetch. Each object keeps only the latest snapshot and retry state, so storage stays bounded.

The production build runs Hugo, generates the localized sitemap from rendered `hreflang` metadata, builds the CSS bundle, compiles and minifies Elm, fingerprints app assets, copies public assets, and validates the result through `mise run check:build`.

## Content and accessibility

Keep Portuguese and English pages paired with the same `translationKey`. Preserve canonical, `hreflang`, structured-data, consent, and AdSense behavior when changing templates. Interactive controls must remain keyboard accessible, expose localized accessible names, retain visible focus, and allow browser zoom.

## Deployment

Cloudflare executes `bash build.sh`, which bootstraps the pinned build environment and delegates to the Mise build task. To deploy from a configured environment:

```sh
npm run deploy
```

Run `mise run ci` before deployment or before opening a pull request.

The `HOROSCOPE_CACHE` binding and `v1-horoscope-cache` SQLite migration in `wrangler.toml` must be deployed together with the Worker. SQLite Durable Objects are available on Cloudflare's free plan, subject to its included limits. The retired `API_NINJAS_KEY` is no longer read by the app or GitHub workflow.

## Daily horoscope source checks

`.github/workflows/horoscope-sources.yml` runs every day at **09:00 America/Sao_Paulo** and supports **Run workflow** in GitHub Actions. It becomes active once committed to the default branch. GitHub may delay scheduled runs.

Each locale has an independent job, so a Portuguese failure does not hide the English result. The check requests the production API once per locale, using the same shared cache as visitors. It requires today's São Paulo snapshot date, the configured provider, all 12 unique signs, and nonempty names and readings. Network errors, malformed JSON, stale snapshots, and incomplete data fail the job, with results in its log and summary. These checks establish served availability and snapshot freshness; they cannot independently establish the editorial freshness or language of provider text.

No provider secrets are required. Scheduled and manual runs use trusted repository code; this workflow does not run against pull requests. Monitoring can populate a missing daily snapshot, but it never bypasses the shared cache for a separate provider check.

Run both live checks locally with `mise run check:sources`. They are separate from `mise run ci`, which uses deterministic tests and does not consume provider requests. GitHub's normal Actions notification preferences control failure notifications.
