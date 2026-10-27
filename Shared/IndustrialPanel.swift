import SwiftUI
import WidgetKit

struct CutPanel: Shape {
    func path(in rect: CGRect) -> Path {
        let c = min(8.0, rect.height / 5)
        return Path { p in
            p.addLines([
                CGPoint(x: c, y: 0),
                CGPoint(x: rect.width - c, y: 0),
                CGPoint(x: rect.width, y: c),
                CGPoint(x: rect.width, y: rect.height - c),
                CGPoint(x: rect.width - c, y: rect.height),
                CGPoint(x: c, y: rect.height),
                CGPoint(x: 0, y: rect.height - c),
                CGPoint(x: 0, y: c)])
            p.closeSubpath()
        }
    }
}

struct IndustrialPanel: View {
    let label: String
    let value: String
    let symbol: String
    var compact = false
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.isLuminanceReduced) private var dimmed
    private let orange = Color(red: 1, green: 0.49, blue: 0.015)

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 1 : 3) {
            Label(label, systemImage: symbol)
                .font(.system(size: compact ? 8 : 10, weight: .bold, design: .monospaced))
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(value)
                .font(.system(size: compact ? 18 : 28, weight: .bold, design: .monospaced))
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 5 : 8)
        .foregroundStyle(mode == .fullColor && !dimmed ? Color.black : Color.primary)
        .background {
            if mode == .fullColor && !dimmed {
                CutPanel().fill(LinearGradient(colors: [orange, Color(red: 1, green: 0.67, blue: 0.12), orange],
                                              startPoint: .topLeading, endPoint: .bottomTrailing))
            } else {
                CutPanel().fill(Color.primary.opacity(0.08))
            }
        }
        .overlay {
            CutPanel().strokeBorderCompat(mode == .fullColor ? Color.gray : Color.primary.opacity(0.6))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }
}

private extension CutPanel {
    func strokeBorderCompat(_ color: Color) -> some View {
        self.stroke(color, lineWidth: 1)
    }
}

