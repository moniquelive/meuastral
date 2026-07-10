# Repository Guidelines

## Project structure

- `src/` contains Elm modules, `bootstrap.js`, and component CSS. Keep one Elm module per `ModuleName.elm` file.
- `content/`, `data/`, `config.yaml`, and `themes/meuastral/` define the bilingual Hugo site, metadata, templates, and shared shell styles.
- `worker/` contains explicit Cloudflare request routing and horoscope-provider normalization.
- `scripts/` owns dependency installation, development, production builds, and generated-output validation.
- `tests/` mirrors source behavior with Elm suites and `node:test` Worker suites.
- `public/` contains source static assets. Numbered PNG portraits are archival inputs; production ships their WebP counterparts.
- `build/` and `.elm-home/` are generated. Never edit or commit generated output.

## Commands and verification

- `mise install` installs the pinned runtimes and global CLI tools from `mise.toml`.
- `mise run install` runs the serialized, hash-stamped `npm ci` workflow in `scripts/install.mjs`.
- `mise run dev` starts the local Cloudflare Worker; its custom build reuses the original Mise home so pinned tools stay active.
- `mise run format:check` validates every Elm source and test file with `elm-format`.
- `mise run test` runs Elm tests followed by Worker tests.
- `mise run build` produces the optimized and fingerprinted site in `build/`.
- `mise run check:build` checks rendered HTML language/zoom requirements, duplicate IDs, sitemap coverage, local references, and shipped image formats.
- `mise run ci` is the complete quality gate. Always run it before returning code changes; also report any individual `mise run test` or `mise run build` failure.
- Use `npm run test:watch` only for the interactive Elm watch loop. Prefer Mise tasks for repeatable workflows.

Do not run install/build/test workflows through parallel ad hoc commands. They share a serialized installer because concurrent `npm ci` runs previously corrupted `node_modules`.

## Elm conventions

- Format with `elm-format`; use PascalCase modules/types and lower camelCase functions and values.
- Preserve legacy snake_case APIs in `AscentMasters.elm` unless a task explicitly includes a coordinated migration of callers and tests.
- Prefer pure helpers and explicit type annotations for exposed functions.
- Keep date-picker month/year navigation open; collapse it only after an actual calendar-day selection.
- Birth dates must not be selectable after the current local date.
- Put new suites in `tests/ModuleNameTests.elm` and expose a top-level `all` value.

## HTML and CSS conventions

- Use semantic HTML before ARIA. When a standard button group is sufficient, do not emulate a tab widget with incomplete tab semantics.
- Every interactive control needs a localized accessible name, visible keyboard focus, and a touch target appropriate for mobile use.
- Do not disable browser zoom in the viewport. Respect `prefers-reduced-motion` for nonessential animations.
- Keep Hugo shell selectors in `themes/meuastral/static/site.css`; keep widget-specific CSS in `src/` and load it through `scripts/build.mjs`.
- Use clear BEM-like selectors for project components. Remove dead selectors instead of keeping historical framework boilerplate.
- Keep user-facing Portuguese and English spelling correct, including Brazilian Portuguese accents and diacritics.

## JavaScript and Worker conventions

- Use modern JavaScript with 2-space indentation, `const` by default, early returns, and built-in browser/Worker/Node APIs before dependencies.
- Keep `src/bootstrap.js` limited to safe browser-state reads, Elm flags, and port wiring. The app must still initialize when local storage is blocked.
- Keep provider secrets in the Worker; never expose `API_NINJAS_KEY` through Elm flags, templates, static assets, or browser requests.
- Route API requests before static assets. Accept only intended methods and return controlled, non-cacheable errors for provider failures.
- Cache only complete normalized horoscope payloads by locale and the configured São Paulo site date.
- Give immutable caching only to fingerprinted assets. Stable-looking, non-fingerprinted images must revalidate so replacements reach returning users.
- Use `node:test` and `node:assert/strict`; test routing, locale parsing, provider selection, normalization, cache decisions, and error responses.
- Preserve the existing AdSense publisher/account behavior unless the user explicitly requests a change.

## Build and deployment

- `scripts/build.mjs` is the source of truth for Hugo, sitemap generation, CSS assembly, Elm compilation/minification, public assets, and fingerprinting.
- Cloudflare runs `bash build.sh`; any dependency or build change must work through both local Mise tasks and this deployment entry point.
- `wrangler.toml` serves `build/` through `STATIC_CONTENT`, with Worker routes evaluated first.
- Deploy with `npm run deploy` only when the user asks for deployment and the target Cloudflare environment is configured.

## Commits and pull requests

- Follow the existing conventional style, such as `fix: handle provider failures` or `chore: refresh contributor docs`.
- Preserve unrelated working-tree changes. Do not rewrite history or discard user work.
- PRs should summarize functional changes, list `mise run ci` evidence, mention configuration/build changes, and include screenshots for visible widget, date-picker, chart, or zodiac changes.
