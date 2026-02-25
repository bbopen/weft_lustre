# weft_lustre

[![Package Version](https://img.shields.io/hexpm/v/weft_lustre)](https://hex.pm/packages/weft_lustre)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/weft_lustre/)

The Lustre renderer for [weft](https://github.com/bbopen/weft). It takes
weft's typed layout model and compiles it into Lustre virtual DOM elements,
injecting exactly the CSS rules needed for the current tree.

You describe layout with `row`, `column`, `el`, and `grid`. weft_lustre
turns that into real DOM nodes with deterministic, hashed class names. No
CSS-in-JS runtime, no style conflicts, no manual class management.

## Installation

Before the first Hex release, use local path dependencies from a checked-out
stack:

```toml
[dependencies]
weft = { path = "../weft" }
weft_lustre = { path = "../weft_lustre" }
```

After Hex publish, install with:

```toml
[dependencies]
weft = ">= 0.1.0 and < 1.0.0"
weft_lustre = ">= 0.1.0 and < 1.0.0"
```

## Quick example

```gleam
import lustre/element
import weft
import weft_lustre

pub fn view(model: Model) -> element.Element(Msg) {
  weft_lustre.layout(
    attrs: [
      weft_lustre.styles([
        weft.width(length: weft.fill()),
        weft.height(length: weft.fill()),
      ]),
    ],
    child: weft_lustre.column(
      attrs: [
        weft_lustre.styles([
          weft.spacing(pixels: 16),
          weft.padding(pixels: 24),
        ]),
      ],
      children: [
        weft_lustre.text(content: "Hello from weft_lustre"),
        weft_lustre.row(
          attrs: [
            weft_lustre.styles([weft.spacing(pixels: 8)]),
          ],
          children: [
            weft_lustre.text(content: "Left"),
            weft_lustre.text(content: "Right"),
          ],
        ),
      ],
    ),
  )
}
```

`layout` is the single entry point. It walks the tree, collects every
`weft.Attribute`, hashes them into class names, and emits one `<style>`
element with the exact CSS needed. Nothing more gets injected.

## What's included

Layout primitives: `row`, `column`, `el`, `grid`, `paragraph`, `image`,
`text`, `none`. These map directly to weft's layout modes.

Structural layers: `in_front`, `modal`, `tooltip`, `toast`,
`behind_content`. Portalled content renders at the root of the layout
output in stacking order, so you don't need z-index.

Anchored overlays: `anchored_overlay` positions a child using weft's
overlay solver. It handles viewport-edge flipping automatically. The
`weft_lustre/overlay` module exposes positioning helpers and an effect hook.
The runtime measurement effect is currently a no-op pending upstream
`plinth` DOM-rect support in Hex.

Modal focus trap: `weft_lustre/modal` installs a keyboard focus trap on
the JS target. It's a no-op on Erlang/SSR.

Time effects: `weft_lustre/time` provides `set_timeout` and
`set_interval` as Lustre effects. JS target only, no-op on Erlang.

SSR documents: `weft_lustre/document` renders a full HTML document with
weft CSS injected into `<head>` instead of inline.

## Dependencies

- [weft](https://github.com/bbopen/weft) -- the layout engine
- [lustre](https://hex.pm/packages/lustre) -- the view framework
- gleam_stdlib

## Companion package

For UI components (buttons, inputs, dialogs, tabs, etc.), see
[weft_lustre_ui](https://github.com/bbopen/weft_lustre_ui).

## License

Apache-2.0
