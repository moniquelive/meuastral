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

The development server uses Wrangler and normally listens on `http://localhost:8787/`. Set `API_NINJAS_KEY` in the environment to exercise the English horoscope provider locally; never put that key in browser code or committed files.

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

The Worker handles `/api/horoscope` before static assets. Portuguese requests use Terra; English requests use API Ninjas. Provider payloads are normalized to one public response shape and cached only when all twelve signs are present. Static HTML falls through to Cloudflare Assets.

The production build runs Hugo, generates the localized sitemap from rendered `hreflang` metadata, builds the CSS bundle, compiles and minifies Elm, fingerprints app assets, copies public assets, and validates the result through `mise run check:build`.

## Content and accessibility

Keep Portuguese and English pages paired with the same `translationKey`. Preserve canonical, `hreflang`, structured-data, consent, and AdSense behavior when changing templates. Interactive controls must remain keyboard accessible, expose localized accessible names, retain visible focus, and allow browser zoom.

## Deployment

Cloudflare executes `bash build.sh`, which bootstraps the pinned build environment and delegates to the Mise build task. To deploy from a configured environment:

```sh
npm run deploy
```

Run `mise run ci` before deployment or before opening a pull request.

## Daily horoscope source checks

`.github/workflows/horoscope-sources.yml` runs every day at **09:00 America/Sao_Paulo** and supports **Run workflow** in GitHub Actions. It becomes active once committed to the default branch. GitHub may delay scheduled runs.

Each locale has an independent job, so a Portuguese failure does not hide the English result. The check calls the real Worker provider adapter directly from Node, bypassing the Cloudflare cache, then checks the production API. Both responses must contain all 12 unique signs with nonempty names and readings. Network errors, malformed JSON, incomplete data, or missing credentials fail the job, with results in its log and summary. The checks verify availability and payload shape; they cannot independently establish the editorial freshness or language of provider text.

The English job requires the repository Actions secret `API_NINJAS_KEY`. Do not put its value in workflow YAML or logs. Scheduled and manual runs use trusted repository code; this workflow does not run against pull requests. A normal successful run makes one Terra request and twelve API Ninjas requests, plus two requests to the public API (which may itself refresh its cache). No package installation is required.

Run both checks locally with `mise run check:sources` when the key is already in your environment, or `mise exec -- node --env-file=.dev.vars scripts/check-horoscope-sources.mjs`. These live checks are separate from `mise run ci`, which uses deterministic tests and does not consume provider requests. GitHub's normal Actions notification preferences control failure notifications.
