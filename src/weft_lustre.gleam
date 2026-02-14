//// Lustre adapter for weft — Elm-UI-style layout on top of sketch_lustre.
////
//// This package provides Elm-UI-inspired layout primitives for Lustre apps,
//// implemented on top of `weft` (core) and `sketch_lustre` (renderer adapter).

import sketch/lustre/element
import sketch/lustre/element/html
import weft

/// Create a horizontal flex container.
pub fn row(
  attrs: List(weft.Attribute),
  children: List(element.Element(msg)),
) -> element.Element(msg) {
  html.div(weft.class([weft.row_layout(), ..attrs]), [], children)
}

/// Create a vertical flex container.
pub fn column(
  attrs: List(weft.Attribute),
  children: List(element.Element(msg)),
) -> element.Element(msg) {
  html.div(weft.class([weft.column_layout(), ..attrs]), [], children)
}

/// Wrap a single child with layout attributes.
pub fn el(attrs: List(weft.Attribute), child: element.Element(msg)) -> element.Element(msg) {
  html.div(weft.class([weft.el_layout(), ..attrs]), [], [child])
}

/// Render plain text.
pub fn text(content: String) -> element.Element(msg) {
  html.text(content)
}

/// Create a paragraph (`<p>`) container.
pub fn paragraph(
  attrs: List(weft.Attribute),
  children: List(element.Element(msg)),
) -> element.Element(msg) {
  html.p(weft.class([weft.el_layout(), ..attrs]), [], children)
}
