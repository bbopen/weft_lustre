//// SSR-friendly HTML document rendering for weft_lustre.
////
//// `weft_lustre.layout(...)` injects a `<style>` node as the first child of the
//// returned root container. For SSR, it's often preferable to inject styles
//// into `<head>`. This module provides a small `Document` type and a
//// `layout_document(...)` helper that injects weft CSS into `<head>`.

import gleam/list
import lustre/attribute
import lustre/element
import weft_lustre

/// A minimal HTML document structure for SSR.
pub opaque type Document(msg) {
  Document(
    html_attrs: List(attribute.Attribute(msg)),
    head: List(element.Element(msg)),
    body_attrs: List(attribute.Attribute(msg)),
    body: weft_lustre.Element(msg),
  )
}

/// Construct a `Document`.
pub fn document(
  html_attrs html_attrs: List(attribute.Attribute(msg)),
  head head: List(element.Element(msg)),
  body_attrs body_attrs: List(attribute.Attribute(msg)),
  body body: weft_lustre.Element(msg),
) -> Document(msg) {
  Document(
    html_attrs: html_attrs,
    head: head,
    body_attrs: body_attrs,
    body: body,
  )
}

/// Compile a weft_lustre tree and inject its stylesheet into `<head>`.
///
/// The resulting HTML is suitable for SSR string rendering via
/// `lustre/element.to_string`.
pub fn layout_document(
  attrs attrs: List(weft_lustre.Attribute(msg)),
  document document: Document(msg),
) -> element.Element(msg) {
  case document {
    Document(html_attrs:, head:, body_attrs:, body:) -> {
      let #(css, nodes) = weft_lustre.compile(attrs, body)
      let style_node = element.element("style", [], [element.text(css)])

      let head_node =
        element.element("head", [], list.append(head, [style_node]))
      let body_node = element.element("body", body_attrs, nodes)

      element.element("html", html_attrs, [head_node, body_node])
    }
  }
}
