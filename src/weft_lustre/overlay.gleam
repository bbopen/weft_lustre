//// Anchored overlay helpers for tooltips and popovers.
////
//// This module integrates weft's anchored overlay micro-solver by:
//// - attaching deterministic anchor/root ids
//// - providing inline-style helpers for unpositioned and positioned overlays
//// - offering a JS-only `after_paint` measurement effect that dispatches an
////   `OverlaySolution` message
////
//// Overlay positions are applied via inline styles (not hashed classes) so
//// runtime measurements never affect deterministic class names.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import lustre/attribute
import lustre/effect
import weft
import weft_lustre

@target(javascript)
import gleam/float

@target(javascript)
import plinth/browser/document

@target(javascript)
import plinth/browser/element as dom_element

@target(javascript)
import plinth/browser/window

/// A normalized overlay identifier used for deterministic anchor/root ids.
pub opaque type OverlayKey {
  OverlayKey(suffix: String)
}

fn suffix(key: OverlayKey) -> String {
  case key {
    OverlayKey(suffix:) -> suffix
  }
}

fn normalize_suffix(value: String) -> String {
  let trimmed =
    value
    |> string.trim
    |> string.lowercase

  let #(acc, _last_was_dash) =
    string.to_utf_codepoints(trimmed)
    |> list.fold(from: #([], False), with: fn(state, cp) {
      let #(acc, last_was_dash) = state

      let i = string.utf_codepoint_to_int(cp)

      let out = case i {
        // a-z
        i if i >= 97 && i <= 122 -> string.from_utf_codepoints([cp])
        // 0-9
        i if i >= 48 && i <= 57 -> string.from_utf_codepoints([cp])
        // _
        95 -> string.from_utf_codepoints([cp])
        // -
        45 -> string.from_utf_codepoints([cp])
        // everything else
        _ -> "-"
      }

      case out == "-" && last_was_dash {
        True -> #(acc, True)
        False -> #([out, ..acc], out == "-")
      }
    })

  let normalized =
    acc
    |> list.reverse
    |> string.join(with: "")

  case normalized {
    "" -> "overlay"
    _ -> normalized
  }
}

/// Construct an `OverlayKey` by normalizing the given string to a safe HTML id
/// suffix.
pub fn overlay_key(value value: String) -> OverlayKey {
  OverlayKey(suffix: normalize_suffix(value))
}

/// The deterministic HTML id used for the anchor element.
pub fn overlay_anchor_id(key key: OverlayKey) -> String {
  "weft-anchor--" <> suffix(key)
}

/// The deterministic HTML id used for the overlay root element.
pub fn overlay_root_id(key key: OverlayKey) -> String {
  "weft-overlay--" <> suffix(key)
}

/// Mark an element as an overlay anchor.
///
/// Attaches:
/// - `id="<overlay_anchor_id(key)>"`
/// - `data-weft-anchor="true"`
pub fn overlay_anchor(key key: OverlayKey) -> weft_lustre.Attribute(msg) {
  weft_lustre.html_attributes(attrs: [
    attribute.id(overlay_anchor_id(key: key)),
    attribute.data("weft-anchor", "true"),
  ])
}

/// Mark an element as an overlay root.
///
/// Attaches:
/// - `id="<overlay_root_id(key)>"`
/// - `data-weft-overlay="true"`
pub fn overlay_root(key key: OverlayKey) -> weft_lustre.Attribute(msg) {
  weft_lustre.html_attributes(attrs: [
    attribute.id(overlay_root_id(key: key)),
    attribute.data("weft-overlay", "true"),
  ])
}

/// Hide an overlay without removing it from layout or measurement.
///
/// This MUST NOT use `display:none`, so the overlay remains measurable.
pub fn overlay_unpositioned() -> weft_lustre.Attribute(msg) {
  weft_lustre.html_attributes(attrs: [
    attribute.styles([
      #("position", "fixed"),
      #("left", "0px"),
      #("top", "0px"),
      #("visibility", "hidden"),
      #("pointer-events", "none"),
    ]),
  ])
}

fn side_to_string(side: weft.OverlaySide) -> String {
  case side == weft.overlay_side_above() {
    True -> "above"
    False ->
      case side == weft.overlay_side_below() {
        True -> "below"
        False ->
          case side == weft.overlay_side_left() {
            True -> "left"
            False -> "right"
          }
      }
  }
}

fn align_to_string(align: weft.OverlayAlign) -> String {
  case align == weft.overlay_align_start() {
    True -> "start"
    False ->
      case align == weft.overlay_align_center() {
        True -> "center"
        False -> "end"
      }
  }
}

/// Position an overlay using an `OverlaySolution` via inline styles.
///
/// This MUST include `data-weft-overlay-side` and `data-weft-overlay-align`
/// metadata derived from the solution placement.
pub fn overlay_position_fixed(
  solution solution: weft.OverlaySolution,
) -> weft_lustre.Attribute(msg) {
  let x = weft.overlay_solution_x(solution: solution)
  let y = weft.overlay_solution_y(solution: solution)

  let placement = weft.overlay_solution_placement(solution: solution)
  let side = weft.overlay_placement_side(placement: placement)
  let align = weft.overlay_placement_align(placement: placement)

  weft_lustre.html_attributes(attrs: [
    attribute.styles([
      #("position", "fixed"),
      #("left", int.to_string(x) <> "px"),
      #("top", int.to_string(y) <> "px"),
      #("visibility", "visible"),
      #("pointer-events", "auto"),
    ]),
    attribute.data("weft-overlay-side", side_to_string(side)),
    attribute.data("weft-overlay-align", align_to_string(align)),
  ])
}

/// Measure anchor/overlay rectangles after paint and dispatch a `weft.OverlaySolution`.
///
/// - JavaScript target: runs in `effect.after_paint`, reads DOM measurements,
///   solves with `weft.solve_overlay`, and dispatches `on_positioned(solution)`.
/// - Erlang target: `effect.none()`.
pub fn position_overlay_on_paint(
  key key: OverlayKey,
  prefer_sides prefer_sides: List(weft.OverlaySide),
  alignments alignments: List(weft.OverlayAlign),
  offset_px offset_px: Int,
  viewport_padding_px viewport_padding_px: Int,
  arrow arrow: Option(#(Int, Int)),
  on_positioned on_positioned: fn(weft.OverlaySolution) -> msg,
) -> effect.Effect(msg) {
  position_overlay_on_paint_impl(
    key,
    prefer_sides,
    alignments,
    offset_px,
    viewport_padding_px,
    arrow,
    on_positioned,
  )
}

@target(javascript)
fn position_overlay_on_paint_impl(
  key: OverlayKey,
  prefer_sides: List(weft.OverlaySide),
  alignments: List(weft.OverlayAlign),
  offset_px: Int,
  viewport_padding_px: Int,
  arrow: Option(#(Int, Int)),
  on_positioned: fn(weft.OverlaySolution) -> msg,
) -> effect.Effect(msg) {
  effect.after_paint(fn(dispatch, _root_dynamic) {
    let anchor_id = overlay_anchor_id(key: key)
    let overlay_id = overlay_root_id(key: key)

    case document.get_element_by_id(anchor_id) {
      Error(Nil) -> Nil
      Ok(anchor) ->
        case document.get_element_by_id(overlay_id) {
          Error(Nil) -> Nil
          Ok(overlay) -> {
            let #(ax_f, ay_f, aw_f, ah_f) =
              dom_element.bounding_client_rect(anchor)

            let #(_ox_f, _oy_f, ow_f, oh_f) =
              dom_element.bounding_client_rect(overlay)

            let anchor_rect =
              weft.rect(
                x: float.round(ax_f),
                y: float.round(ay_f),
                width: float.round(aw_f),
                height: float.round(ah_f),
              )

            let overlay_size =
              weft.size(width: float.round(ow_f), height: float.round(oh_f))

            let win = window.self()

            let viewport =
              weft.rect(
                x: 0,
                y: 0,
                width: window.inner_width(win),
                height: window.inner_height(win),
              )

            let problem =
              weft.overlay_problem(
                anchor: anchor_rect,
                overlay: overlay_size,
                viewport: viewport,
              )
              |> weft.overlay_prefer_sides(sides: prefer_sides)
              |> weft.overlay_alignments(aligns: alignments)
              |> weft.overlay_offset(pixels: offset_px)
              |> weft.overlay_padding(pixels: viewport_padding_px)

            let problem = case arrow {
              Some(#(size_px, edge_padding_px)) ->
                weft.overlay_arrow(
                  problem: problem,
                  size_px: size_px,
                  edge_padding_px: edge_padding_px,
                )
              None -> problem
            }

            let solution = weft.solve_overlay(problem: problem)
            dispatch(on_positioned(solution))
          }
        }
    }
  })
}

@target(erlang)
fn position_overlay_on_paint_impl(
  _key: OverlayKey,
  _prefer_sides: List(weft.OverlaySide),
  _alignments: List(weft.OverlayAlign),
  _offset_px: Int,
  _viewport_padding_px: Int,
  arrow: Option(#(Int, Int)),
  _on_positioned: fn(weft.OverlaySolution) -> msg,
) -> effect.Effect(msg) {
  // Use constructors so imports stay warning-free on Erlang.
  case arrow {
    Some(_) -> effect.none()
    None -> effect.none()
  }
}
