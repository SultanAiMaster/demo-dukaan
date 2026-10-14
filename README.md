# Demo Dukaan (WorkChain AI product template)

One Flutter codebase -> shop website (Flutter Web), Android app, admin panel. Backend for the demo: Cloudflare Pages worker + KV (`backend/_worker.js`).

## Design language (product default for every customer clone)
**Bento Grid + Minimalism.**
- Layout: modular rounded "bento" tiles (24px radius, 1px hairline border `kLine`, no heavy shadows) in an asymmetric grid; large tile + stacked small tiles on desktop, stacked on mobile.
- Palette: neutral (`kBg` #F4F4F1, white cards, ink #111) plus ONE accent (`kBrand`, #E85D2A). To rebrand a clone, change `kBrand` only.
- Type: heavy tight headings (w800, negative letter-spacing), muted secondary text, small uppercase accent eyebrow labels.
- Whitespace: 20px page gutters, 16px grid gaps, 40px between sections.
- Constants and the `bento()` decoration live in `lib/ui.dart`.

## Run
`flutter build web` then copy `build/web` + `backend/_worker.js` to `dist` and deploy to Cloudflare Pages with a KV binding named `DB`.
Demo admin login: demo / demo123 (data resets daily, IST).
