//// Modal helpers for weft_lustre.
////
//// This module provides:
//// - `modal_root_id(...)` for marking a modal root in markup.
//// - `modal_focus_trap(...)` for installing a JS-only focus trap effect.
////
//// The focus trap is a no-op on Erlang/SSR.

@target(javascript)
import gleam/list

@target(javascript)
import gleam/option.{None, Some}
import lustre/attribute
import lustre/effect
import weft_lustre

@target(javascript)
import gleam/javascript/array

@target(javascript)
import plinth/browser/document

@target(javascript)
import plinth/browser/element as dom_element

@target(javascript)
import plinth/browser/event as dom_event

/// Mark the modal root element with an `id` and a `data-weft-modal-root` marker.
pub fn modal_root_id(value value: String) -> weft_lustre.Attribute(msg) {
  weft_lustre.html_attributes(attrs: [
    attribute.id(value),
    attribute.data("weft-modal-root", "true"),
  ])
}

@target(javascript)
fn focusable_selector() -> String {
  // A pragmatic "focusable" selector. We intentionally keep this simple and
  // browser-driven (tab order) rather than trying to model all edge cases.
  "a[href],button:not([disabled]),input:not([disabled]):not([type=\"hidden\"]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex=\"-1\"])"
}

@target(javascript)
fn focus_first(root_id: String) -> Nil {
  let nodes =
    document.query_selector_all("#" <> root_id <> " " <> focusable_selector())
    |> array.to_list

  case nodes {
    [] -> Nil
    [first, ..] -> dom_element.focus(first)
  }
}

@target(javascript)
fn handle_keydown(
  dispatch: fn(msg) -> Nil,
  root_id: String,
  on_escape: msg,
  e: dom_event.Event(dom_event.UIEvent(dom_event.KeyboardEvent)),
) -> Nil {
  case dom_event.key(e) {
    "Escape" -> {
      dom_event.prevent_default(e)
      dom_event.stop_propagation(e)
      dispatch(on_escape)
    }

    "Tab" -> {
      let nodes =
        document.query_selector_all(
          "#" <> root_id <> " " <> focusable_selector(),
        )
        |> array.to_list

      case nodes {
        [] -> Nil
        [first, ..] -> {
          let last = case list.reverse(nodes) {
            [x, ..] -> x
            [] -> first
          }

          let current = case dom_element.cast(dom_event.target(e)) {
            Ok(el) -> Some(el)
            Error(_) -> None
          }

          let shift = dom_event.shift_key(e)

          case shift, current {
            True, Some(el) ->
              case el == first {
                True -> {
                  dom_event.prevent_default(e)
                  dom_element.focus(last)
                }
                False -> Nil
              }

            True, None -> {
              dom_event.prevent_default(e)
              dom_element.focus(last)
            }

            False, Some(el) ->
              case el == last {
                True -> {
                  dom_event.prevent_default(e)
                  dom_element.focus(first)
                }
                False -> Nil
              }

            False, None -> {
              dom_event.prevent_default(e)
              dom_element.focus(first)
            }
          }
        }
      }
    }

    _ -> Nil
  }
}

@target(javascript)
fn installed(root: dom_element.Element) -> Bool {
  case dom_element.get_attribute(root, "data-weft-focus-trap-installed") {
    Ok("true") -> True
    _ -> False
  }
}

@target(javascript)
fn mark_installed(root: dom_element.Element) -> Nil {
  dom_element.set_attribute(root, "data-weft-focus-trap-installed", "true")
}

/// Install a focus trap for a modal subtree (JS-only).
///
/// - JS target: installs a keydown listener that traps Tab/Shift-Tab within the
///   modal root and dispatches `on_escape` on Escape.
/// - Erlang target: `effect.none()`.
pub fn modal_focus_trap(
  root_id root_id: String,
  on_escape on_escape: msg,
) -> effect.Effect(msg) {
  modal_focus_trap_impl(root_id, on_escape)
}

@target(javascript)
fn modal_focus_trap_impl(root_id: String, on_escape: msg) -> effect.Effect(msg) {
  effect.after_paint(fn(dispatch, _root_dynamic) {
    case document.get_element_by_id(root_id) {
      Error(Nil) -> Nil
      Ok(root) -> {
        case installed(root) {
          True -> Nil
          False -> {
            mark_installed(root)
            focus_first(root_id)

            let _remove =
              dom_element.add_event_listener(root, "keydown", fn(e) {
                handle_keydown(dispatch, root_id, on_escape, e)
              })

            Nil
          }
        }
      }
    }
  })
}

@target(erlang)
fn modal_focus_trap_impl(
  _root_id: String,
  _on_escape: msg,
) -> effect.Effect(msg) {
  effect.none()
}
