//// Time-related effect helpers for weft_lustre.
////
//// weft_lustre aims to be cross-target. Time-based effects are JavaScript-only
//// and are implemented using the vendored `plinth` bindings. On Erlang/SSR,
//// these helpers return `effect.none()`.

import lustre/effect

@target(javascript)
import plinth/javascript/global

@target(javascript)
fn non_negative(value: Int) -> Int {
  case value < 0 {
    True -> 0
    False -> value
  }
}

/// Dispatch a message after a delay in milliseconds.
///
/// - JavaScript target: schedules a `setTimeout` and dispatches `msg` when it
///   fires.
/// - Erlang/SSR target: returns `effect.none()`.
///
/// Negative delays are clamped to `0`.
pub fn dispatch_after(
  after_ms after_ms: Int,
  msg msg: msg,
) -> effect.Effect(msg) {
  dispatch_after_impl(after_ms, msg)
}

@target(javascript)
fn dispatch_after_impl(after_ms: Int, msg: msg) -> effect.Effect(msg) {
  let delay = non_negative(after_ms)

  effect.from(fn(dispatch) {
    let _timer = global.set_timeout(delay, fn() { dispatch(msg) })

    Nil
  })
}

@target(erlang)
fn dispatch_after_impl(_after_ms: Int, _msg: msg) -> effect.Effect(msg) {
  effect.none()
}
