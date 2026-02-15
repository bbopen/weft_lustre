//// Lustre renderer for weft — Elm-UI-style layout with deterministic CSS injection.
////
//// Apps build a `weft_lustre.Element(msg)` tree using primitives like `row`,
//// `column`, and `el`. The `layout` function is the compilation step that:
//// - compiles `weft.Attribute`s into deterministic class names
//// - injects a single `<style>` node containing the exact CSS needed
//// - renders to a `lustre/element.Element(msg)` for mounting or SSR

import gleam/list
import lustre/attribute
import lustre/element
import weft

/// An element in the weft_lustre layout tree.
pub opaque type Element(msg) {
  Element(inner: Node(msg))
}

/// A structural layer for portalled content.
pub opaque type Layer {
  BehindContent
  InFront
  Modal
  Tooltip
  Toast
}

/// An attribute that can be attached to a weft_lustre `Element`.
pub opaque type Attribute(msg) {
  Attribute(inner: Attr(msg))
}

/// An image loading hint.
pub opaque type ImageLoading {
  ImageLoading(value: String)
}

/// An image decoding hint.
pub opaque type ImageDecoding {
  ImageDecoding(value: String)
}

/// An image fetch priority hint.
pub opaque type FetchPriority {
  FetchPriority(value: String)
}

type Node(msg) {
  Empty
  Text(String)
  Html(element.Element(msg))
  Portal(layer: Layer, child: Node(msg))
  Node(
    tag: String,
    weft_attrs: List(weft.Attribute),
    html_attrs: List(attribute.Attribute(msg)),
    children: List(Node(msg)),
  )
}

type Attr(msg) {
  Styles(List(weft.Attribute))
  HtmlAttr(attribute.Attribute(msg))
  HtmlAttrs(List(attribute.Attribute(msg)))
}

fn image_loading_value(value: ImageLoading) -> String {
  case value {
    ImageLoading(value:) -> value
  }
}

fn image_decoding_value(value: ImageDecoding) -> String {
  case value {
    ImageDecoding(value:) -> value
  }
}

fn fetch_priority_value(value: FetchPriority) -> String {
  case value {
    FetchPriority(value:) -> value
  }
}

fn node(n: Node(msg)) -> Element(msg) {
  Element(inner: n)
}

fn unwrap(el: Element(msg)) -> Node(msg) {
  case el {
    Element(inner:) -> inner
  }
}

/// Place content into a structural root layer.
///
/// Content in a layer renders at the root of the `layout(...)` output and
/// renders nothing in its original position in the tree.
pub fn in_layer(layer layer: Layer, child child: Element(msg)) -> Element(msg) {
  node(Portal(layer: layer, child: unwrap(child)))
}

/// Portalled content that is rendered behind the main content.
pub fn layer_behind_content() -> Layer {
  BehindContent
}

/// Portalled content that is rendered in front of the main content.
pub fn layer_in_front() -> Layer {
  InFront
}

/// Portalled content that is rendered above normal content, intended for
/// modals.
pub fn layer_modal() -> Layer {
  Modal
}

/// Portalled content that is rendered above modals, intended for tooltips.
pub fn layer_tooltip() -> Layer {
  Tooltip
}

/// Portalled content that is rendered above everything else, intended for
/// transient toasts.
pub fn layer_toast() -> Layer {
  Toast
}

/// Convenience wrapper for `in_layer(layer_behind_content(), ...)`.
pub fn behind_content(child child: Element(msg)) -> Element(msg) {
  in_layer(layer: layer_behind_content(), child: child)
}

/// Convenience wrapper for `in_layer(layer_in_front(), ...)`.
pub fn in_front(child child: Element(msg)) -> Element(msg) {
  in_layer(layer: layer_in_front(), child: child)
}

/// Convenience wrapper for `in_layer(layer_modal(), ...)`.
pub fn modal(child child: Element(msg)) -> Element(msg) {
  in_layer(layer: layer_modal(), child: child)
}

/// Convenience wrapper for `in_layer(layer_tooltip(), ...)`.
pub fn tooltip(child child: Element(msg)) -> Element(msg) {
  in_layer(layer: layer_tooltip(), child: child)
}

/// Convenience wrapper for `in_layer(layer_toast(), ...)`.
pub fn toast(child child: Element(msg)) -> Element(msg) {
  in_layer(layer: layer_toast(), child: child)
}

/// Attach one or more `weft.Attribute` values to an element.
///
/// App code should prefer using `styles([...])` rather than calling `weft.class`
/// directly. `layout` is responsible for CSS injection.
pub fn styles(attrs attrs: List(weft.Attribute)) -> Attribute(msg) {
  Attribute(inner: Styles(attrs))
}

/// Attach a single `weft.Attribute` value to an element.
pub fn style(attr attr: weft.Attribute) -> Attribute(msg) {
  styles(attrs: [attr])
}

/// Escape hatch: attach a raw Lustre attribute.
///
/// This is outside the "if it compiles, it's correct" guarantee boundary.
pub fn html_attribute(attr attr: attribute.Attribute(msg)) -> Attribute(msg) {
  Attribute(inner: HtmlAttr(attr))
}

/// Internal helper: attach multiple raw Lustre attributes at once.
@internal
pub fn html_attributes(
  attrs attrs: List(attribute.Attribute(msg)),
) -> Attribute(msg) {
  Attribute(inner: HtmlAttrs(attrs))
}

/// Defer image loading until needed.
pub fn image_loading_lazy() -> ImageLoading {
  ImageLoading(value: "lazy")
}

/// Load images eagerly.
pub fn image_loading_eager() -> ImageLoading {
  ImageLoading(value: "eager")
}

/// Attach a `loading` hint to an image.
pub fn image_loading(loading loading: ImageLoading) -> Attribute(msg) {
  Attribute(inner: HtmlAttr(attribute.loading(image_loading_value(loading))))
}

/// Default image decoding behavior.
pub fn image_decoding_auto() -> ImageDecoding {
  ImageDecoding(value: "auto")
}

/// Decode images asynchronously.
pub fn image_decoding_async() -> ImageDecoding {
  ImageDecoding(value: "async")
}

/// Decode images synchronously.
pub fn image_decoding_sync() -> ImageDecoding {
  ImageDecoding(value: "sync")
}

/// Attach a `decoding` hint to an image.
pub fn image_decoding(decoding decoding: ImageDecoding) -> Attribute(msg) {
  Attribute(inner: HtmlAttr(attribute.decoding(image_decoding_value(decoding))))
}

/// Default fetch priority.
pub fn fetch_priority_auto() -> FetchPriority {
  FetchPriority(value: "auto")
}

/// High fetch priority.
pub fn fetch_priority_high() -> FetchPriority {
  FetchPriority(value: "high")
}

/// Low fetch priority.
pub fn fetch_priority_low() -> FetchPriority {
  FetchPriority(value: "low")
}

/// Attach a `fetchpriority` hint to an image.
pub fn image_fetch_priority(
  fetch_priority fetch_priority: FetchPriority,
) -> Attribute(msg) {
  Attribute(
    inner: HtmlAttr(
      attribute.fetchpriority(fetch_priority_value(fetch_priority)),
    ),
  )
}

/// Attach a `width` attribute to an image.
pub fn image_width(value value: Int) -> Attribute(msg) {
  Attribute(inner: HtmlAttr(attribute.width(value)))
}

/// Attach a `height` attribute to an image.
pub fn image_height(value value: Int) -> Attribute(msg) {
  Attribute(inner: HtmlAttr(attribute.height(value)))
}

/// Attach a `srcset` attribute to an image.
pub fn image_srcset(value value: String) -> Attribute(msg) {
  Attribute(inner: HtmlAttr(attribute.srcset(value)))
}

/// Attach a `sizes` attribute to an image.
pub fn image_sizes(value value: String) -> Attribute(msg) {
  Attribute(inner: HtmlAttr(attribute.sizes(value)))
}

fn split_attributes(
  attrs: List(Attribute(msg)),
) -> #(List(weft.Attribute), List(attribute.Attribute(msg))) {
  let #(weft_rev, html_rev) =
    list.fold(attrs, #([], []), fn(acc, attr) {
      let #(weft_rev, html_rev) = acc
      case attr {
        Attribute(inner: Styles(styles)) -> #(
          list.append(list.reverse(styles), weft_rev),
          html_rev,
        )

        Attribute(inner: HtmlAttr(a)) -> #(weft_rev, [a, ..html_rev])
        Attribute(inner: HtmlAttrs(attrs)) -> #(
          weft_rev,
          list.append(list.reverse(attrs), html_rev),
        )
      }
    })

  #(list.reverse(weft_rev), list.reverse(html_rev))
}

fn element_node(
  tag: String,
  base_weft_attrs: List(weft.Attribute),
  attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  let #(weft_attrs, html_attrs) = split_attributes(attrs)
  node(Node(
    tag: tag,
    weft_attrs: list.append(base_weft_attrs, weft_attrs),
    html_attrs: html_attrs,
    children: list.map(children, unwrap),
  ))
}

/// Create an element with an arbitrary tag that still participates in weft
/// styling and CSS injection.
pub fn element_tag(
  tag tag: String,
  base_weft_attrs base_weft_attrs: List(weft.Attribute),
  attrs attrs: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  element_node(tag, base_weft_attrs, attrs, children)
}

type Compiled(msg) {
  Compiled(
    classes: List(weft.Class),
    content: element.Element(msg),
    portals: List(#(Layer, element.Element(msg))),
  )
}

fn compiled(
  classes: List(weft.Class),
  content: element.Element(msg),
  portals: List(#(Layer, element.Element(msg))),
) -> Compiled(msg) {
  Compiled(classes: classes, content: content, portals: portals)
}

/// Create a horizontal flex container.
pub fn row(
  attrs attrs: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  element_node("div", [weft.row_layout()], attrs, children)
}

/// Create a vertical flex container.
pub fn column(
  attrs attrs: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  element_node("div", [weft.column_layout()], attrs, children)
}

/// Create a grid container.
pub fn grid(
  attrs attrs: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  element_node("div", [weft.grid_layout()], attrs, children)
}

/// Wrap a single child with layout attributes.
pub fn el(
  attrs attrs: List(Attribute(msg)),
  child child: Element(msg),
) -> Element(msg) {
  element_node("div", [weft.el_layout()], attrs, [child])
}

/// Create a paragraph (`<p>`) container.
pub fn paragraph(
  attrs attrs: List(Attribute(msg)),
  children children: List(Element(msg)),
) -> Element(msg) {
  element_node("p", [weft.el_layout()], attrs, children)
}

/// Render an image (`<img>`) that participates in weft styling.
///
/// The `attrs` list may include weft styles (`styles([...])`) and image HTML
/// attribute helpers (for example `image_loading(...)`).
pub fn image(
  attrs attrs: List(Attribute(msg)),
  src src: String,
  alt alt: String,
) -> Element(msg) {
  let required = [
    Attribute(inner: HtmlAttr(attribute.src(src))),
    Attribute(inner: HtmlAttr(attribute.alt(alt))),
  ]

  element_node(
    "img",
    [weft.el_layout(), weft.image_layout()],
    list.append(attrs, required),
    [],
  )
}

/// Render plain text.
pub fn text(content content: String) -> Element(msg) {
  node(Text(content))
}

/// Render nothing.
pub fn none() -> Element(msg) {
  node(Empty)
}

/// Escape hatch: embed a raw Lustre node.
///
/// Nodes embedded via `html` are opaque to `weft_lustre` and do not participate
/// in CSS class collection.
pub fn html(node node: element.Element(msg)) -> Element(msg) {
  Element(inner: Html(node))
}

fn compile_node(node: Node(msg)) -> Compiled(msg) {
  case node {
    Empty -> compiled([], element.none(), [])
    Text(t) -> compiled([], element.text(t), [])
    Html(n) -> compiled([], n, [])

    Portal(layer:, child:) -> {
      let compiled_child = compile_node(child)
      compiled(compiled_child.classes, element.none(), [
        #(layer, compiled_child.content),
        ..compiled_child.portals
      ])
    }

    Node(tag:, weft_attrs:, html_attrs:, children:) -> {
      let #(classes_rev, nodes_rev, portals_rev) =
        list.fold(children, #([], [], []), fn(acc, child) {
          let #(classes_rev, nodes_rev, portals_rev) = acc
          let child_compiled = compile_node(child)

          #(
            list.append(list.reverse(child_compiled.classes), classes_rev),
            [child_compiled.content, ..nodes_rev],
            list.append(list.reverse(child_compiled.portals), portals_rev),
          )
        })

      let child_classes = list.reverse(classes_rev)
      let rendered_children = list.reverse(nodes_rev)
      let portals = list.reverse(portals_rev)

      case weft_attrs {
        [] ->
          compiled(
            child_classes,
            element.element(tag, html_attrs, rendered_children),
            portals,
          )

        _ -> {
          let class = weft.class(attrs: weft_attrs)
          let class_attr = attribute.class(weft.class_name(class: class))

          compiled(
            [class, ..child_classes],
            element.element(tag, [class_attr, ..html_attrs], rendered_children),
            portals,
          )
        }
      }
    }
  }
}

type Layered(msg) {
  Layered(
    behind: List(element.Element(msg)),
    in_front: List(element.Element(msg)),
    modal: List(element.Element(msg)),
    tooltip: List(element.Element(msg)),
    toast: List(element.Element(msg)),
  )
}

fn split_layers(portals: List(#(Layer, element.Element(msg)))) -> Layered(msg) {
  let #(behind_rev, in_front_rev, modal_rev, tooltip_rev, toast_rev) =
    list.fold(portals, #([], [], [], [], []), fn(acc, item) {
      let #(behind_rev, in_front_rev, modal_rev, tooltip_rev, toast_rev) = acc
      let #(layer, node) = item

      case layer {
        BehindContent -> #(
          [node, ..behind_rev],
          in_front_rev,
          modal_rev,
          tooltip_rev,
          toast_rev,
        )
        InFront -> #(
          behind_rev,
          [node, ..in_front_rev],
          modal_rev,
          tooltip_rev,
          toast_rev,
        )
        Modal -> #(
          behind_rev,
          in_front_rev,
          [node, ..modal_rev],
          tooltip_rev,
          toast_rev,
        )
        Tooltip -> #(
          behind_rev,
          in_front_rev,
          modal_rev,
          [node, ..tooltip_rev],
          toast_rev,
        )
        Toast -> #(behind_rev, in_front_rev, modal_rev, tooltip_rev, [
          node,
          ..toast_rev
        ])
      }
    })

  Layered(
    behind: list.reverse(behind_rev),
    in_front: list.reverse(in_front_rev),
    modal: list.reverse(modal_rev),
    tooltip: list.reverse(tooltip_rev),
    toast: list.reverse(toast_rev),
  )
}

fn background_container(
  children: List(element.Element(msg)),
) -> #(List(weft.Class), element.Element(msg)) {
  let class =
    weft.class(attrs: [
      weft.pointer_events(value: weft.pointer_events_none()),
    ])

  let attrs = [
    attribute.class(weft.class_name(class: class)),
    attribute.inert(True),
    attribute.aria_hidden(True),
  ]

  #([class], element.element("div", attrs, children))
}

/// Internal compilation helper shared by `layout` and `weft_lustre/document`.
///
/// This is not part of the stable public API. App code should call `layout(...)`.
@internal
pub fn compile(
  attrs: List(Attribute(msg)),
  child: Element(msg),
) -> #(String, List(element.Element(msg))) {
  let root =
    element_node("div", [weft.el_layout()], attrs, [child])
    |> unwrap

  let compiled_root = compile_node(root)
  let layered = split_layers(compiled_root.portals)

  let has_modal = case layered.modal {
    [] -> False
    _ -> True
  }

  let #(bg_classes, behind_nodes) = case has_modal, layered.behind {
    True, [] -> #([], [])
    True, behind -> {
      let #(classes, node) = background_container(behind)
      #(classes, [node])
    }
    False, behind -> #([], behind)
  }

  let #(main_bg_classes, main_nodes) = case has_modal {
    True -> {
      let #(classes, node) = background_container([compiled_root.content])
      #(classes, [node])
    }
    False -> #([], [compiled_root.content])
  }

  let #(front_bg_classes, in_front_nodes) = case has_modal, layered.in_front {
    True, [] -> #([], [])
    True, in_front -> {
      let #(classes, node) = background_container(in_front)
      #(classes, [node])
    }
    False, in_front -> #([], in_front)
  }

  let classes =
    compiled_root.classes
    |> list.append(bg_classes)
    |> list.append(main_bg_classes)
    |> list.append(front_bg_classes)

  let css = weft.stylesheet(classes: classes)

  #(
    css,
    list.flatten([
      behind_nodes,
      main_nodes,
      in_front_nodes,
      layered.modal,
      layered.tooltip,
      layered.toast,
    ]),
  )
}

/// Compile and render a weft_lustre tree.
///
/// `layout` is the only supported entry point for producing a renderable Lustre
/// element. It injects a single `<style>` node containing the CSS for the tree.
pub fn layout(
  attrs attrs: List(Attribute(msg)),
  child child: Element(msg),
) -> element.Element(msg) {
  let #(css, nodes) = compile(attrs, child)
  let stylesheet_node = element.element("style", [], [element.text(css)])
  element.element("div", [], [stylesheet_node, ..nodes])
}

/// Debug/test helper: return the CSS that `layout` would inject.
pub fn debug_stylesheet(
  attrs attrs: List(Attribute(msg)),
  child child: Element(msg),
) -> String {
  let #(css, _) = compile(attrs, child)
  css
}
