import gleam/list
import gleam/option
import gleam/string
import lustre/attribute
import lustre/effect
import lustre/element
import startest.{describe, it}
import startest/expect
import weft
import weft_lustre
import weft_lustre/document
import weft_lustre/modal
import weft_lustre/overlay
import weft_lustre/time

pub fn main() {
  startest.run(startest.default_config())
}

pub fn weft_lustre_tests() {
  describe("weft_lustre", [
    describe("layout", [
      it("injects CSS for used weft attributes", fn() {
        let view =
          weft_lustre.row(
            attrs: [
              weft_lustre.styles([
                weft.spacing(pixels: 8),
                weft.padding(pixels: 4),
              ]),
            ],
            children: [weft_lustre.text(content: "hello")],
          )

        let css = weft_lustre.debug_stylesheet(attrs: [], child: view)

        string.contains(css, "display:flex;")
        |> expect.to_equal(expected: True)

        string.contains(css, "flex-direction:row;")
        |> expect.to_equal(expected: True)

        string.contains(css, "gap:8px;")
        |> expect.to_equal(expected: True)

        string.contains(css, "padding:4px;")
        |> expect.to_equal(expected: True)
      }),
      it("injects grid CSS", fn() {
        let view =
          weft_lustre.grid(
            attrs: [
              weft_lustre.styles([
                weft.grid_columns(tracks: [
                  weft.grid_fr(fr: 1.0),
                  weft.grid_fixed(length: weft.px(pixels: 100)),
                ]),
                weft.spacing(pixels: 8),
              ]),
            ],
            children: [
              weft_lustre.el(attrs: [], child: weft_lustre.text(content: "a")),
              weft_lustre.el(attrs: [], child: weft_lustre.text(content: "b")),
            ],
          )

        let css = weft_lustre.debug_stylesheet(attrs: [], child: view)

        string.contains(css, "display:grid;")
        |> expect.to_equal(expected: True)

        string.contains(css, "grid-template-columns:1fr 100px;")
        |> expect.to_equal(expected: True)

        string.contains(css, "gap:8px;")
        |> expect.to_equal(expected: True)
      }),
      it("injects container query CSS", fn() {
        let view =
          weft_lustre.column(
            attrs: [
              weft_lustre.styles([
                weft.container_inline_size(),
                weft.container_name(value: "dashboard"),
                weft.when_container(
                  query: weft.container_min_width(length: weft.px(pixels: 720)),
                  attrs: [
                    weft.spacing(pixels: 20),
                  ],
                ),
              ]),
            ],
            children: [weft_lustre.text(content: "container")],
          )

        let css = weft_lustre.debug_stylesheet(attrs: [], child: view)

        string.contains(css, "container-type:inline-size;")
        |> expect.to_equal(expected: True)

        string.contains(css, "container-name:dashboard;")
        |> expect.to_equal(expected: True)

        string.contains(css, "@container (min-width:720px){\n")
        |> expect.to_equal(expected: True)

        string.contains(css, "gap:20px;")
        |> expect.to_equal(expected: True)
      }),
      it("renders portals at the root in deterministic layer order", fn() {
        let view =
          weft_lustre.column(attrs: [], children: [
            weft_lustre.behind_content(child: weft_lustre.el(
              attrs: [weft_lustre.html_attribute(attribute.id("behind"))],
              child: weft_lustre.text(content: "behind"),
            )),
            weft_lustre.el(
              attrs: [weft_lustre.html_attribute(attribute.id("content"))],
              child: weft_lustre.text(content: "content"),
            ),
            weft_lustre.in_front(child: weft_lustre.el(
              attrs: [weft_lustre.html_attribute(attribute.id("front"))],
              child: weft_lustre.text(content: "front"),
            )),
            weft_lustre.modal(child: weft_lustre.el(
              attrs: [weft_lustre.html_attribute(attribute.id("modal"))],
              child: weft_lustre.text(content: "modal"),
            )),
            weft_lustre.tooltip(child: weft_lustre.el(
              attrs: [weft_lustre.html_attribute(attribute.id("tooltip"))],
              child: weft_lustre.text(content: "tooltip"),
            )),
            weft_lustre.toast(child: weft_lustre.el(
              attrs: [weft_lustre.html_attribute(attribute.id("toast"))],
              child: weft_lustre.text(content: "toast"),
            )),
          ])

        let rendered =
          weft_lustre.layout(
            attrs: [weft_lustre.html_attribute(attribute.id("main"))],
            child: view,
          )
          |> element.to_string

        assert_contains_in_order(rendered, [
          "<div><style>",
          "id=\"behind\"",
          "id=\"main\"",
          "id=\"front\"",
          "id=\"modal\"",
          "id=\"tooltip\"",
          "id=\"toast\"",
        ])
        |> expect.to_equal(expected: True)
      }),
      it("portal renders nothing in its original position", fn() {
        let view =
          weft_lustre.column(attrs: [], children: [
            weft_lustre.el(
              attrs: [weft_lustre.html_attribute(attribute.id("before"))],
              child: weft_lustre.text(content: "before"),
            ),
            weft_lustre.behind_content(child: weft_lustre.el(
              attrs: [weft_lustre.html_attribute(attribute.id("portal"))],
              child: weft_lustre.text(content: "portal"),
            )),
            weft_lustre.el(
              attrs: [weft_lustre.html_attribute(attribute.id("after"))],
              child: weft_lustre.text(content: "after"),
            ),
          ])

        let rendered =
          weft_lustre.layout(attrs: [], child: view)
          |> element.to_string

        case string.split(rendered, "id=\"before\"") {
          [_, after_before] ->
            case string.split(after_before, "id=\"after\"") {
              [between, _] ->
                string.contains(between, "id=\"portal\"")
                |> expect.to_equal(expected: False)
              _ -> 0 |> expect.to_equal(expected: 1)
            }
          _ -> 0 |> expect.to_equal(expected: 1)
        }
      }),
      it(
        "adds inert + aria-hidden + pointer-events:none to background when modal exists",
        fn() {
          let view =
            weft_lustre.column(attrs: [], children: [
              weft_lustre.el(attrs: [], child: weft_lustre.text(content: "x")),
              weft_lustre.modal(child: weft_lustre.el(
                attrs: [],
                child: weft_lustre.text(content: "modal"),
              )),
            ])

          let rendered =
            weft_lustre.layout(attrs: [], child: view)
            |> element.to_string

          string.contains(rendered, "inert")
          |> expect.to_equal(expected: True)

          string.contains(rendered, "aria-hidden=\"true\"")
          |> expect.to_equal(expected: True)

          let css = weft_lustre.debug_stylesheet(attrs: [], child: view)

          string.contains(css, "pointer-events:none;")
          |> expect.to_equal(expected: True)
        },
      ),
      it("does not inert background when no modal exists", fn() {
        let view =
          weft_lustre.column(attrs: [], children: [
            weft_lustre.el(attrs: [], child: weft_lustre.text(content: "x")),
          ])

        let rendered =
          weft_lustre.layout(attrs: [], child: view)
          |> element.to_string

        string.contains(rendered, "inert")
        |> expect.to_equal(expected: False)

        string.contains(rendered, "aria-hidden=\"true\"")
        |> expect.to_equal(expected: False)

        let css = weft_lustre.debug_stylesheet(attrs: [], child: view)

        string.contains(css, "pointer-events:none;")
        |> expect.to_equal(expected: False)
      }),
      it("injects a single <style> node first", fn() {
        let view =
          weft_lustre.el(
            attrs: [weft_lustre.styles([weft.padding(pixels: 1)])],
            child: weft_lustre.text(content: "hello"),
          )

        let rendered =
          weft_lustre.layout(attrs: [], child: view)
          |> element.to_string

        string.starts_with(rendered, "<div><style>")
        |> expect.to_equal(expected: True)

        string.split(rendered, "<style>")
        |> list.length
        |> expect.to_equal(expected: 2)
      }),
      it("deduplicates identical classes used in multiple places", fn() {
        let view =
          weft_lustre.row(attrs: [], children: [
            weft_lustre.el(
              attrs: [weft_lustre.styles([weft.padding(pixels: 1)])],
              child: weft_lustre.text(content: "a"),
            ),
            weft_lustre.el(
              attrs: [weft_lustre.styles([weft.padding(pixels: 1)])],
              child: weft_lustre.text(content: "b"),
            ),
          ])

        let css = weft_lustre.debug_stylesheet(attrs: [], child: view)
        let class =
          weft.class(attrs: [weft.el_layout(), weft.padding(pixels: 1)])

        // One rule means the selector appears exactly once.
        string.split(css, "." <> weft.class_name(class: class))
        |> list.length
        |> expect.to_equal(expected: 2)
      }),
      it("forwards html_attribute without affecting weft CSS", fn() {
        let view =
          weft_lustre.el(
            attrs: [weft_lustre.html_attribute(attribute.id("x"))],
            child: weft_lustre.text(content: "hello"),
          )

        let rendered =
          weft_lustre.layout(attrs: [], child: view)
          |> element.to_string

        string.contains(rendered, "id=\"x\"")
        |> expect.to_equal(expected: True)

        let css = weft_lustre.debug_stylesheet(attrs: [], child: view)

        string.contains(css, "id=\"x\"")
        |> expect.to_equal(expected: False)
      }),
    ]),
    describe("document", [
      it(
        "layout_document injects <style> into <head> and content into <body>",
        fn() {
          let view =
            weft_lustre.el(
              attrs: [weft_lustre.styles([weft.padding(pixels: 1)])],
              child: weft_lustre.text(content: "hello"),
            )

          let doc =
            document.document(
              html_attrs: [],
              head: [element.element("meta", [attribute.charset("utf-8")], [])],
              body_attrs: [attribute.id("body")],
              body: view,
            )

          let rendered =
            document.layout_document(attrs: [], document: doc)
            |> element.to_string

          assert_contains_in_order(rendered, [
            "<html><head>",
            "<meta",
            "<style>",
            "</head><body id=\"body\">",
            "hello",
            "</body></html>",
          ])
          |> expect.to_equal(expected: True)
        },
      ),
      it("layout_document appends weft style last in head", fn() {
        let view =
          weft_lustre.el(attrs: [], child: weft_lustre.text(content: "x"))

        let head_nodes = [
          element.element("style", [], [element.text("/* earlier */")]),
        ]

        let doc =
          document.document(
            html_attrs: [],
            head: head_nodes,
            body_attrs: [],
            body: view,
          )

        let rendered =
          document.layout_document(attrs: [], document: doc)
          |> element.to_string

        let parts = string.split(rendered, "<head>")
        case parts {
          [_, after_head] -> {
            // The last <style> in head should be weft's injected one, which
            // contains a `.wf-` selector when any weft attrs are present.
            string.contains(after_head, "/* earlier */")
            |> expect.to_equal(expected: True)

            // We didn't add any weft styles, so injected CSS is empty, but the
            // node still exists and must be last in head.
            string.contains(after_head, "</style></head>")
            |> expect.to_equal(expected: True)
          }
          _ -> 0 |> expect.to_equal(expected: 1)
        }
      }),
    ]),
    describe("modal", [
      it("modal_root_id attaches id and data marker", fn() {
        let view =
          weft_lustre.el(
            attrs: [modal.modal_root_id(value: "m")],
            child: weft_lustre.text(content: "x"),
          )

        let rendered =
          weft_lustre.layout(attrs: [], child: view)
          |> element.to_string

        string.contains(rendered, "id=\"m\"")
        |> expect.to_equal(expected: True)

        string.contains(rendered, "data-weft-modal-root=\"true\"")
        |> expect.to_equal(expected: True)
      }),
      it("modal_focus_trap is callable on Erlang (no-op effect)", fn() {
        let _: effect.Effect(String) =
          modal.modal_focus_trap(root_id: "m", on_escape: "escape")

        1 |> expect.to_equal(expected: 1)
      }),
    ]),
    describe("overlay", [
      it("overlay_key normalizes the id suffix", fn() {
        overlay.overlay_key(value: "  Hello World  ")
        |> overlay.overlay_anchor_id
        |> expect.to_equal(expected: "weft-anchor--hello-world")

        overlay.overlay_key(value: "A--B")
        |> overlay.overlay_root_id
        |> expect.to_equal(expected: "weft-overlay--a-b")

        overlay.overlay_key(value: "   ")
        |> overlay.overlay_anchor_id
        |> expect.to_equal(expected: "weft-anchor--overlay")

        overlay.overlay_key(value: "a@b")
        |> overlay.overlay_root_id
        |> expect.to_equal(expected: "weft-overlay--a-b")
      }),
      it("overlay_anchor attaches id and data marker", fn() {
        let key = overlay.overlay_key(value: "x")
        let view =
          weft_lustre.el(
            attrs: [overlay.overlay_anchor(key: key)],
            child: weft_lustre.text(content: "x"),
          )

        let rendered =
          weft_lustre.layout(attrs: [], child: view)
          |> element.to_string

        string.contains(rendered, "id=\"weft-anchor--x\"")
        |> expect.to_equal(expected: True)

        string.contains(rendered, "data-weft-anchor=\"true\"")
        |> expect.to_equal(expected: True)
      }),
      it("overlay_root attaches id and data marker", fn() {
        let key = overlay.overlay_key(value: "x")
        let view =
          weft_lustre.el(
            attrs: [overlay.overlay_root(key: key)],
            child: weft_lustre.text(content: "x"),
          )

        let rendered =
          weft_lustre.layout(attrs: [], child: view)
          |> element.to_string

        string.contains(rendered, "id=\"weft-overlay--x\"")
        |> expect.to_equal(expected: True)

        string.contains(rendered, "data-weft-overlay=\"true\"")
        |> expect.to_equal(expected: True)
      }),
      it(
        "overlay_unpositioned hides via inline styles without display:none",
        fn() {
          let view =
            weft_lustre.el(
              attrs: [overlay.overlay_unpositioned()],
              child: weft_lustre.text(content: "x"),
            )

          let rendered =
            weft_lustre.layout(attrs: [], child: view)
            |> element.to_string

          string.contains(
            rendered,
            "position:fixed;left:0px;top:0px;visibility:hidden;pointer-events:none;",
          )
          |> expect.to_equal(expected: True)

          string.contains(rendered, "display:none")
          |> expect.to_equal(expected: False)
        },
      ),
      it(
        "overlay_position_fixed applies left/top styles and placement metadata",
        fn() {
          let problem =
            weft.overlay_problem(
              anchor: weft.rect(x: 10, y: 10, width: 10, height: 10),
              overlay: weft.size(width: 20, height: 10),
              viewport: weft.rect(x: 0, y: 0, width: 200, height: 200),
            )

          let solution = weft.solve_overlay(problem: problem)

          let view =
            weft_lustre.el(
              attrs: [overlay.overlay_position_fixed(solution: solution)],
              child: weft_lustre.text(content: "x"),
            )

          let rendered =
            weft_lustre.layout(attrs: [], child: view)
            |> element.to_string

          string.contains(
            rendered,
            "position:fixed;left:5px;top:20px;visibility:visible;pointer-events:auto;",
          )
          |> expect.to_equal(expected: True)

          string.contains(rendered, "data-weft-overlay-side=\"below\"")
          |> expect.to_equal(expected: True)

          string.contains(rendered, "data-weft-overlay-align=\"center\"")
          |> expect.to_equal(expected: True)
        },
      ),
      it("position_overlay_on_paint is callable on Erlang (no-op effect)", fn() {
        let key = overlay.overlay_key(value: "x")

        let _: effect.Effect(String) =
          overlay.position_overlay_on_paint(
            key: key,
            prefer_sides: [],
            alignments: [],
            offset_px: 0,
            viewport_padding_px: 0,
            arrow: option.None,
            on_positioned: fn(_solution) { "positioned" },
          )

        1 |> expect.to_equal(expected: 1)
      }),
    ]),
    describe("time", [
      it("dispatch_after is callable on Erlang (no-op effect)", fn() {
        let _: effect.Effect(String) =
          time.dispatch_after(after_ms: 10, msg: "tick")

        1 |> expect.to_equal(expected: 1)
      }),
    ]),
  ])
}

fn assert_contains_in_order(haystack: String, needles: List(String)) -> Bool {
  case needles {
    [] -> True
    [needle, ..rest] ->
      case string.split(haystack, needle) {
        [_, after] -> assert_contains_in_order(after, rest)
        _ -> False
      }
  }
}
