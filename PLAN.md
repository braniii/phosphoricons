# Plan: `phosphoricons` — a LaTeX package for Phosphor Icons

## Context

There is no Phosphor Icons package on CTAN (namespace verified free). The goal is a font-based LaTeX package supporting pdfLaTeX, XeLaTeX and LuaLaTeX with all six Phosphor weights (thin, light, regular, bold, fill, duotone), fully auto-generated from upstream releases so that upgrading to a new Phosphor version is a single script run. The user maintains the CTAN packages fontawesome6/7 (`~/Documents/Coding/fontawesome`); that codebase is the architectural reference, deliberately simplified where Phosphor allows it. Working directory `/Users/nagel/Documents/Coding/phosphoricons` is empty — clean start (git init it).

## Decisions made (with user)

- Package name: **`phosphoricons`**; command prefix **`pp`**: `\ppIcon[weight]{acorn}` + generated `\ppAcorn[fill]` per-icon macros. Verified: no `\ppIcon`/`\pp<Name>` commands in TeX Live 2026 (bare `\pp` exists in footmisc/perpage/cryptocode — we never define bare `\pp`). Generator uses `\cs_new_protected` so any future collision is a hard error caught in CI.
- Duotone: **color-mix secondary** — background glyph drawn in `<current color>!20` via xcolor (≈ upstream's `opacity:0.2` on white), configurable à la `\ppDuotoneSetSecondary{...}`. Engine-independent, no transparency machinery.
- Automation: **full CI** — monthly GitHub Action (poll npm → regenerate → compile-test all icons on 3 engines → PR, mirroring fontawesome's `upgrade_fa.sh` + `update-fa7.yml`) plus simpleicons' `paolobrasolin/ctan-submit-action` for CTAN upload.

## Key upstream facts (from research)

- Source of truth: npm **`@phosphor-icons/web`** (latest 2.1.2). Per weight `src/<w>/`: `Phosphor[-Weight].ttf` (regular has no suffix!), `selection.json` (IcoMoon: `properties.name`, decimal `properties.code`), `style.css`. Tarball: `https://registry.npmjs.org/@phosphor-icons/web/-/web-<V>.tgz`; latest via registry `.dist-tags.latest`.
- **1512 icons + 18 aliases**, codepoints PUA U+E000–U+EE82, **identical across all six weights**. Kebab names camelize cleanly to digit-free Pascal names (also available as `pascal_name` in `@phosphor-icons/core` `src/icons.ts`, which also lists aliases).
- Duotone = two stacked glyphs: base codepoint (background, 20% opacity) + secondary on top. Secondary is *nominally* cp+1 but **not guaranteed** (agents disagreed on odd-codepoint counts) → parse `duotone/style.css` `:before`/`:after` contents as the authoritative source.
- License: MIT throughout (fonts embed the notice) — CTAN redistribution unproblematic. TeX code under LPPL, fonts stay MIT; include both licenses.
- Upstream ships **TTF only, no OTF**.

## Architecture

### Shipped CTAN tree (`phosphoricons/` inside the repo, like `fontawesome7/`)

```
phosphoricons/
├── tex/   phosphoricons.sty              (main: options, \ppIcon, \ppWeight, engine dispatch)
│          phosphoricons-generic-helper.sty   (pdfTeX: U-encoding chunk fonts)
│          phosphoricons-utex-helper.sty      (Xe/Lua: TU + \char codepoint)
│          phosphoricons-mapping.def          (GENERATED — the single data artefact)
│          uphosphoricons<0..N>.fd            (GENERATED, U encoding, weights as NFSS series)
│          tuphosphoricons.fd                 (GENERATED, TU, \UnicodeFontFile per weight — no fontspec)
├── truetype/  6 TTFs (renamed consistently, e.g. Phosphor-Regular.ttf)
├── type1/     6 .pfb   (only if direct-TTF embedding fails; see below)
├── tfm/       ~6 chunks × 6 weights .tfm    (GENERATED)
├── enc/       ~6–12 .enc                    (GENERATED)
├── map/phosphoricons.map                    (GENERATED)
└── doc/  phosphoricons.tex + pp_fulllist.tex (GENERATED) + PDF
```

### Engine seam (copied from fontawesome7, but **symmetric**)

`phosphoricons.sty` tests `\c_sys_engine_str` and loads one helper; both implement `\phosphoricons_use_icon:nn{<weight>}{<name>}`. Unlike fontawesome7, **both engines consume the same generated `phosphoricons-mapping.def`** — no runtime font-scraping, no `.lua` file, no XeTeX camel-case rescan hack. One line per icon:

```latex
\__phosphoricons_def_icon:nnnnnn{\ppAcorn}{acorn}{2}{154}{"EB9A}{"EB9B}
%                                {macro}{name}{chunk}{slot}{cp}{duotone-secondary-cp}
```

- **pdfTeX helper**: stores `{chunk}{slot}`; renders via `\usefont{U}{phosphoricons<chunk>}{<weight>}{n}\char<slot>`. Weights are the NFSS **series** axis; `.fd` adds `ssub` aliases (`m→regular`, `b/bx→bold`) so icons survive bold context. Uniform glyph coverage → no `\iffontchar` fallback chains; unknown name/weight is a clean `\msg_error`.
- **Xe/Lua helper**: stores codepoints; renders via `\usefont{TU}{phosphoricons}{<weight>}{n}\char"<cp>`. `tuphosphoricons.fd` uses `\UnicodeFontFile{Phosphor-<W>.ttf}` — fontspec never loaded.
- Aliases (18) get their own `def_icon` lines pointing at the shared codepoint.
- Macros: `\ppAcorn` → `\ppPreselectedIcon{acorn}` with trailing optional arg; `\ppIcon[<opts>]{name}`; `\ppWeight{bold}` setter.
- **Options are one shared l3keys key tree, settable at three levels** (package options ← `\ppSet{...}` mid-document ← per-icon optional arg, most specific wins):
  - `weight = thin|light|regular|bold|fill|duotone` (default `regular`). So duotone can be turned on globally via `\usepackage[weight=duotone]{phosphoricons}` or per icon.
  - `secondary = <xcolor spec>` — duotone background-layer color, default `.!20` (current color at 20%).
  - The per-icon optional arg accepts the same keys, with a **bare value shorthand for weight**: `\ppAcorn[duotone]`, `\ppIcon[bold]{acorn}`, and full form `\ppAcorn[weight=duotone, secondary=blue!30]`.
- Duotone rendering: draw the background glyph (base cp) in the `secondary` color, then overlay the foreground glyph (secondary cp) at the same position (`\rlap`/`\llap`, glyphs are uniformly square). Requires **xcolor** (hard dependency).

### pdfTeX font strategy

Codepoint-ordered chunking: `chunk = (cp − 0xE000) div 256`, `slot = cp mod 256` → ~6 chunks for base glyphs (duotone secondaries land in the same range; build encodings from the **union** of all codepoints incl. secondaries, so one chunk layout serves every weight; plain-weight TFMs simply have empty slots where only duotone has glyphs).
- First choice: **embed TTF directly** in the map line (`<Phosphor-Regular.ttf` + ReEncodeFont), TFMs via `otftotfm` (or `ttf2tfm`) — avoids any FontForge/Type1 step. Test this very early (spike, step 1); it's the main deviation from the fontawesome7 generator.
- Fallback: FontForge one-liner TTF→`.pfb` (simpleicons' `convert.pe` pattern), then `otftotfm` exactly as in `generate_binding.py`.
- Caveat: `.enc` files reference glyph *names* — verify actual glyph names in the TTFs with fontTools early (IcoMoon usually names glyphs by icon name; duotone layer names may differ). If names differ per weight, generate per-weight `.enc` sets — still fully automatic, just more files.

## Generation & upgrade tooling (repo root)

- `scripts/generate_binding.py` (Python, fontTools; adapted from `~/Documents/Coding/fontawesome/scripts/generate_binding.py`): input = unpacked `@phosphor-icons/web` tarball. Parse all `selection.json` (assert codepoint sets identical across weights), parse `duotone/style.css` for secondary cps, camelize kebab→Pascal, add aliases; emit `mapping.def`, `.enc`, `.tfm` (+`.pfb` if needed), `.map`, all `.fd`, and the doc's full icon list.
- `scripts/upgrade_phosphor.sh` (adapted from `upgrade_fa.sh`): query npm registry for latest → download & unpack tarball → copy TTFs + metadata into `assets/` → run generator → sed-bump version/date in `.sty` + doc → **compile-test every icon on pdfLaTeX, XeLaTeX, LuaLaTeX** by redefining `\__phosphoricons_def_icon:nnnnnn` to typeset each icon in each weight over `mapping.def` → rebuild doc → emit `GITHUB_OUTPUT`.
- Keep fontawesome's reuse pattern: `mapping.def` is the single data source consumed by (1) package load, (2) CI all-icons test, (3) generated documentation table.
- `local_install.sh` (adapted): copy into `~/texmf`, `mktexlsr`, `updmap-user --enable Map=phosphoricons.map`.
- `.github/workflows/update.yml`: monthly cron in `texlive/texlive:latest`, runs upgrade script, opens PR via `peter-evans/create-pull-request` (mirror `update-fa7.yml`).
- Release workflow: build CTAN zip (TDS-ish tree like fontawesome's archiver) + `paolobrasolin/ctan-submit-action`.

## Implementation order

1. **Spike (de-risks everything)**: download `web-2.1.2.tgz`; inspect TTF glyph names/cmap with fontTools; hand-build one chunk (enc + tfm + map with direct-TTF embedding) and a 5-line test doc printing `\char` on all three engines. Decides TTF-direct vs Type1 route and enc-sharing vs per-weight.
2. Write `generate_binding.py` → full generated artefact set.
3. Write the three `.sty` files (main + two helpers), duotone rendering, error messages.
4. Test document exercising: both engines' generic + per-icon commands, all 6 weights, aliases, bold-context `ssub`, duotone colors, error paths.
5. `upgrade_phosphor.sh` + `local_install.sh`; run full 3-engine all-icons compile test.
6. Documentation (`doc/phosphoricons.tex` manual + generated full list), README, LICENSE (LPPL + MIT notice).
7. git init, GitHub repo, `update.yml` + CTAN release workflow; final end-to-end run of the upgrade script from a clean checkout.

## Verification

- `upgrade_phosphor.sh` end-to-end from clean state regenerates identical artefacts (idempotence).
- All-icons compile test on pdfLaTeX, XeLaTeX, LuaLaTeX (every icon × every weight via the mapping-redefinition trick); assert zero missing-glyph warnings in logs.
- Visual spot-check PDF: a page with a handful of icons in all 6 weights on all 3 engines — compare against phosphoricons.com rendering (esp. duotone layering and baseline/size next to text).
- `local_install.sh` into `~/texmf`, then compile a user-style document from an arbitrary directory (validates map registration).
- Collision safety: `\cs_new_protected` errors if any `\pp<Name>` already exists — implicit in the all-icons test.
