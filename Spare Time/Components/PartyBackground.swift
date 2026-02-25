import SwiftUI

struct PartyBackground: View {
    @State private var shapes: [Squiggle] = Squiggle.generate(count: 45)

    var body: some View {
        Canvas { context, size in
            for shape in shapes {
                var ctx = context
                let point = CGPoint(x: shape.x * size.width, y: shape.y * size.height)
                ctx.translateBy(x: point.x, y: point.y)
                ctx.rotate(by: .radians(shape.rotation))

                let s = shape.scale

                switch shape.kind {
                case .zigzag:
                    var path = Path()
                    path.move(to: CGPoint(x: -14 * s, y: -10 * s))
                    path.addLine(to: CGPoint(x: -5 * s, y: 10 * s))
                    path.addLine(to: CGPoint(x: 5 * s, y: -10 * s))
                    path.addLine(to: CGPoint(x: 14 * s, y: 10 * s))
                    ctx.stroke(path, with: .color(shape.color),
                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                case .spiral:
                    var path = Path()
                    let steps = 36
                    for i in 0...steps {
                        let t = Double(i) / Double(steps)
                        let angle = t * 1.8 * 2 * .pi
                        let r = t * 11 * s
                        let pt = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                        if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
                    }
                    ctx.stroke(path, with: .color(shape.color),
                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                case .dot:
                    let r: CGFloat = 4.5 * s
                    ctx.fill(Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)),
                             with: .color(shape.color))

                case .ring:
                    let r: CGFloat = 8 * s
                    ctx.stroke(Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)),
                               with: .color(shape.color),
                               style: StrokeStyle(lineWidth: 2.5))

                case .squiggle:
                    var path = Path()
                    path.move(to: CGPoint(x: -16 * s, y: 0))
                    path.addCurve(to: CGPoint(x: 0, y: 0),
                                  control1: CGPoint(x: -11 * s, y: -13 * s),
                                  control2: CGPoint(x: -5 * s, y: 13 * s))
                    path.addCurve(to: CGPoint(x: 16 * s, y: 0),
                                  control1: CGPoint(x: 5 * s, y: -13 * s),
                                  control2: CGPoint(x: 11 * s, y: 13 * s))
                    ctx.stroke(path, with: .color(shape.color),
                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

                case .dash:
                    var path = Path()
                    path.move(to: CGPoint(x: -7 * s, y: 0))
                    path.addLine(to: CGPoint(x: 7 * s, y: 0))
                    ctx.stroke(path, with: .color(shape.color),
                               style: StrokeStyle(lineWidth: 3, lineCap: .round))
                }
            }
        }
    }
}

// MARK: - Data

private enum SquiggleKind: CaseIterable {
    case zigzag, spiral, dot, ring, squiggle, dash
}

private struct Squiggle {
    let kind: SquiggleKind
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let color: Color

    static let palette: [Color] = [
        Color(red: 0.0, green: 0.90, blue: 0.80),  // cyan / teal
        Color(red: 1.0, green: 0.20, blue: 0.55),   // hot pink
        Color(red: 1.0, green: 0.93, blue: 0.20),   // yellow
        Color(red: 0.30, green: 0.40, blue: 1.0),    // blue
        Color(red: 0.60, green: 0.30, blue: 1.0),    // purple
    ]

    /// Approximate bounding radius for collision checks (in normalized 0-1 space, assuming ~400pt screen width).
    private static func radius(kind: SquiggleKind, scale: CGFloat) -> CGFloat {
        let base: CGFloat = switch kind {
        case .zigzag:   20
        case .spiral:   16
        case .squiggle: 20
        case .ring:     12
        case .dot:       7
        case .dash:     10
        }
        return base * scale / 400
    }

    static func generate(count: Int) -> [Squiggle] {
        var result: [Squiggle] = []
        var attempts = 0
        let maxAttempts = count * 12

        while result.count < count, attempts < maxAttempts {
            attempts += 1
            let kind = SquiggleKind.allCases.randomElement()!
            let scale = CGFloat.random(in: 0.8...1.3)
            let x = CGFloat.random(in: 0...1)
            let y = CGFloat.random(in: 0...1)
            let r = radius(kind: kind, scale: scale)

            let tooClose = result.contains { existing in
                let er = radius(kind: existing.kind, scale: existing.scale)
                let dx = x - existing.x
                let dy = y - existing.y
                return sqrt(dx * dx + dy * dy) < (r + er) * 1.3
            }
            guard !tooClose else { continue }

            result.append(Squiggle(
                kind: kind,
                x: x,
                y: y,
                rotation: Double.random(in: 0...(2 * .pi)),
                scale: scale,
                color: palette.randomElement()!
            ))
        }
        return result
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        PartyBackground()
            .ignoresSafeArea()
            .opacity(0.3)
    }
}
