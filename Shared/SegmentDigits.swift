import SwiftUI

struct SegmentDigits: View {
    let text: String
    var color: Color = .orange
    private let segments: [Character: String] = [
        "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
        "5": "afgcd", "6": "afgecd", "7": "abc", "8": "abcdefg", "9": "abfgcd", "—": "g", "-": "g"
    ]
    private let shapes: [(Character, [CGPoint])] = [
        ("a", [.init(x:5,y:1),.init(x:25,y:1),.init(x:21,y:5),.init(x:9,y:5)]),
        ("b", [.init(x:26,y:2),.init(x:26,y:22),.init(x:22,y:19),.init(x:22,y:6)]),
        ("c", [.init(x:26,y:25),.init(x:26,y:45),.init(x:22,y:41),.init(x:22,y:29)]),
        ("d", [.init(x:5,y:46),.init(x:25,y:46),.init(x:21,y:42),.init(x:9,y:42)]),
        ("e", [.init(x:4,y:25),.init(x:8,y:29),.init(x:8,y:41),.init(x:4,y:45)]),
        ("f", [.init(x:4,y:2),.init(x:8,y:6),.init(x:8,y:19),.init(x:4,y:22)]),
        ("g", [.init(x:5,y:23.5),.init(x:9,y:20.5),.init(x:21,y:20.5),.init(x:25,y:23.5),.init(x:21,y:26.5),.init(x:9,y:26.5)])
    ]
    var body: some View {
        Canvas { context, size in
            let width = text.reduce(CGFloat(0)) { $0 + (".,:".contains($1) ? 10 : 31) }
            let scale = min(size.width / max(width, 1), size.height / 48)
            context.translateBy(x: (size.width - width * scale) / 2, y: (size.height - 48 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            var x: CGFloat = 0
            for character in text {
                if ".,:".contains(character) {
                    let ys: [CGFloat] = character == ":" ? [15, 33] : [43]
                    for y in ys {
                        context.fill(Path(ellipseIn: CGRect(x:x + 2,y:y - 2,width:5,height:5)), with:.color(color))
                    }
                    x += 10
                } else {
                    for (name, points) in shapes {
                        var path = Path()
                        path.addLines(points.map { CGPoint(x:$0.x + x,y:$0.y) })
                        path.closeSubpath()
                        context.fill(path, with:.color(color.opacity((segments[character] ?? "").contains(name) ? 1 : 0.07)))
                    }
                    x += 31
                }
            }
        }
        .accessibilityLabel(text)
    }
}
