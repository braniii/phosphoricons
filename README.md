[![CTAN](https://img.shields.io/ctan/v/phosphoricons.svg)](https://ctan.org/pkg/phosphoricons)

# phosphoricons — Phosphor Icons for LaTeX

A LaTeX package providing all [Phosphor Icons](https://phosphoricons.com) in
all six weights (thin, light, regular, bold, fill, duotone) on **pdfLaTeX,
XeLaTeX and LuaLaTeX**.

```latex
\usepackage{phosphoricons}
...
\ppIcon{acorn}                                % generic command
\ppAcorn                                      % generated per-icon command
\ppAcorn[bold]                                % per-icon weight
\ppIcon[weight=duotone, secondary=orange]{campfire}
\ppSet{weight=fill}                           % document/group default
```

Weights can be set as a package option (`\usepackage[weight=bold]{phosphoricons}`),
mid-document (`\ppSet{...}` / `\ppWeight{...}`) or per icon; the most specific
setting wins. Duotone icons are rendered as two stacked glyphs; the background
layer color defaults to the current text color mixed at 20 % (`secondary=.!20`)
and can be set to any xcolor expression.

See [the manual](phosphoricons/doc/phosphoricons.pdf) for the full icon list.

## Installation

From CTAN/TeX Live: install the `phosphoricons` package with your distribution.

From this repository:

```sh
scripts/local_install.sh
```

which copies the package into `TEXMFHOME` and registers the font map
(`updmap-user --enable Map=phosphoricons.map`).

## How it works

- On XeLaTeX/LuaLaTeX the TrueType fonts are loaded directly (a `TU` font
  family per weight, no fontspec needed) and glyphs are addressed by Unicode
  codepoint.
- On pdfLaTeX the fonts are re-encoded into 256-glyph chunks (`U` encoding
  families, weights on the NFSS series axis) and the TTFs are embedded
  directly — no Type 1 conversion.
- Both engines consume the same generated mapping file
  (`phosphoricons-mapping.def`), which is also reused to build the icon-list
  documentation and the CI test that typesets every icon in every weight on
  all three engines.

## Upgrading to a new Phosphor release

Everything under `phosphoricons/` except the three hand-written `.sty` files
is generated from the upstream npm package
[`@phosphor-icons/web`](https://www.npmjs.com/package/@phosphor-icons/web):

```sh
scripts/upgrade_phosphor.sh        # fetch latest, regenerate, test, build doc
```

A GitHub Action runs this monthly and opens a pull request when upstream
publishes a new version.

Requirements for regeneration: `python3` with `fontTools`
(`pip install fonttools`), `otftotfm` (lcdf-typetools, ships with TeX Live)
and a TeX Live with pdfLaTeX, XeLaTeX and LuaLaTeX.

## License

- The LaTeX package (sty files, scripts, generated TeX artefacts):
  [LPPL 1.3c](https://www.latex-project.org/lppl.txt), maintained by
  Daniel Nagel.
- The Phosphor Icons fonts (`phosphoricons/truetype/`): MIT,
  © Tobias Fried & Helena Zhang ([phosphor-icons](https://github.com/phosphor-icons/web)).
