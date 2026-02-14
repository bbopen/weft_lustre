import startest.{describe, it}
import startest/expect
import sketch/lustre/element
import weft
import weft_lustre

pub fn main() {
  startest.run(startest.default_config())
}

pub fn weft_lustre_tests() {
  describe("weft_lustre", [
    describe("primitives", [
      it("builds row/column/el/text/paragraph elements", fn() {
        let _row: element.Element(Nil) =
          weft_lustre.row(attrs: [weft.spacing(pixels: 8)], children: [])

        let _column: element.Element(Nil) =
          weft_lustre.column(attrs: [], children: [])

        let _text: element.Element(Nil) = weft_lustre.text("hello")

        let _el: element.Element(Nil) =
          weft_lustre.el(attrs: [weft.padding(pixels: 4)], child: _text)

        let _paragraph: element.Element(Nil) =
          weft_lustre.paragraph(attrs: [], children: [_text])

        1 |> expect.to_equal(expected: 1)
      }),
    ]),
  ])
}
