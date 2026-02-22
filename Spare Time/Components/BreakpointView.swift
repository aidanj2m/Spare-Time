import SwiftUI

struct BreakpointView: View {
    @Binding var breakpointCoord: LaneCoordinate?
    @Binding var entryCoord: LaneCoordinate?

    @State private var tapPoint: CGPoint? = nil      // view-space breakpoint
    @State private var entryValue: Double = 0.5      // slider 0–1
    @State private var viewSize: CGSize = .zero       // captured from GeometryReader

    // Mirror Last20FeetLaneView constants
    private let gutterRatio: CGFloat = 25.0 / 244.0
    private let boardCount: CGFloat = 39
    // Head pin position in view ratio (244 x 575)
    private let headPinX: CGFloat = 123.0 / 244.0
    private let headPinY: CGFloat = 123.0 / 575.0

    // Real-world Y for head pin level (in the 42–62 range)
    private var headPinRealY: Double {
        42.0 + (1.0 - Double(headPinY)) * 20.0
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("last 20 feet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.secondary)

            ZStack {
                Last20FeetLaneView()

                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let gutterW = w * gutterRatio
                    let entryPt = entryPos(t: CGFloat(entryValue), w: w, h: h)

                    // V guide lines (faint)
                    Path { path in
                        let leftEnd = CGPoint(x: gutterW, y: 0)
                        let apex = CGPoint(x: w * headPinX, y: h * headPinY)
                        let rightEnd = CGPoint(x: w - gutterW, y: 0)
                        path.move(to: leftEnd)
                        path.addLine(to: apex)
                        path.addLine(to: rightEnd)
                    }
                    .stroke(Theme.guideLines, lineWidth: 1)

                    // Line from breakpoint to entry point + arrowhead
                    if let bp = tapPoint {
                        Path { path in
                            path.move(to: bp)
                            path.addLine(to: entryPt)
                        }
                        .stroke(Theme.trajectory, lineWidth: 2.5)

                        arrowhead(from: bp, to: entryPt)
                            .fill(Theme.trajectory)

                        // Breakpoint ball
                        Image("ballImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .position(bp)

                        // Entry point ball
                        Image("ballImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .position(entryPt)
                    }

                    // Invisible tap target
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { drag in
                                    let pt = drag.location
                                    // Clamp to lane area (below pin deck, inside gutters)
                                    let minY = h * headPinY + 20  // below head pin
                                    let clampedY = max(pt.y, minY)
                                    let clampedX = min(max(pt.x, gutterW), w - gutterW)
                                    let clamped = CGPoint(x: clampedX, y: clampedY)

                                    tapPoint = clamped
                                    viewSize = geo.size
                                    convertBreakpoint(clamped, w: w, h: h)
                                    updateEntryCoord()
                                }
                        )
                        .onAppear { viewSize = geo.size }
                }
            }
            .aspectRatio(244.0 / 575.0, contentMode: .fit)

            // Entry angle slider — only shown after breakpoint is placed
            if tapPoint != nil {
                VStack(alignment: .leading, spacing: 10) {
                    sliderRow(label: "Entry", value: $entryValue)
                }
                .padding(.horizontal, 20)
            }
        }
        .onChange(of: entryValue) { updateEntryCoord() }
    }

    // MARK: - V-path position (view space)

    private func entryPos(t: CGFloat, w: CGFloat, h: CGFloat) -> CGPoint {
        let gutterW = w * gutterRatio
        let leftEnd  = CGPoint(x: gutterW, y: 0)
        let apex     = CGPoint(x: w * headPinX, y: h * headPinY)
        let rightEnd = CGPoint(x: w - gutterW, y: 0)

        if t <= 0.5 {
            let frac = t / 0.5
            return CGPoint(
                x: leftEnd.x + (apex.x - leftEnd.x) * frac,
                y: leftEnd.y + (apex.y - leftEnd.y) * frac
            )
        } else {
            let frac = (t - 0.5) / 0.5
            return CGPoint(
                x: apex.x + (rightEnd.x - apex.x) * frac,
                y: apex.y + (rightEnd.y - apex.y) * frac
            )
        }
    }

    // MARK: - Arrowhead shape

    private func arrowhead(from start: CGPoint, to end: CGPoint) -> Path {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let len = sqrt(dx * dx + dy * dy)
        guard len > 0 else { return Path() }

        let ux = dx / len
        let uy = dy / len
        let size: CGFloat = 8

        let tip = end
        let left = CGPoint(x: tip.x - ux * size - uy * size * 0.5,
                           y: tip.y - uy * size + ux * size * 0.5)
        let right = CGPoint(x: tip.x - ux * size + uy * size * 0.5,
                            y: tip.y - uy * size - ux * size * 0.5)

        return Path { p in
            p.move(to: tip)
            p.addLine(to: left)
            p.addLine(to: right)
            p.closeSubpath()
        }
    }

    // MARK: - Coordinate conversion

    private func convertBreakpoint(_ pt: CGPoint, w: CGFloat, h: CGFloat) {
        let gutterW = w * gutterRatio
        let laneW = w - gutterW * 2

        let realX = Double((pt.x - gutterW) / laneW) * 3.5
        let realY = 42.0 + Double(1.0 - pt.y / h) * 20.0

        breakpointCoord = LaneCoordinate(
            x: min(max(realX, 0), 3.5),
            y: min(max(realY, 42), 62)
        )
    }

    private func updateEntryCoord() {
        guard tapPoint != nil else { return }
        let t = entryValue
        // V-path in real-world coords
        // Left end: x=0, y=62 (top-left of view = far end of lane)
        // Apex (head pin): x=1.75, y=headPinRealY
        // Right end: x=3.5, y=62
        let leftX = 0.0, leftY = 62.0
        let apexX = 1.75, apexY = headPinRealY
        let rightX = 3.5, rightY = 62.0

        if t <= 0.5 {
            let frac = t / 0.5
            entryCoord = LaneCoordinate(
                x: leftX + (apexX - leftX) * frac,
                y: leftY + (apexY - leftY) * frac
            )
        } else {
            let frac = (t - 0.5) / 0.5
            entryCoord = LaneCoordinate(
                x: apexX + (rightX - apexX) * frac,
                y: apexY + (rightY - apexY) * frac
            )
        }
    }

    // MARK: - Slider

    private func sliderRow(label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Theme.secondary)
                .frame(width: 56, alignment: .leading)
            ReleaseView.CustomSlider(value: value)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var bp: LaneCoordinate? = nil
        @State var entry: LaneCoordinate? = nil
        var body: some View {
            BreakpointView(breakpointCoord: $bp, entryCoord: $entry)
                .frame(width: 260)
                .padding()
                .background(Theme.background)
        }
    }
    return PreviewWrapper()
}
