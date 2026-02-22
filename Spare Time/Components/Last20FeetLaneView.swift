import SwiftUI

struct Last20FeetLaneView: View {
    // Figma lane area: 244 x 575

    // MARK: - Colors

    private let boardColorA = Theme.boardColorA
    private let boardColorB = Theme.boardColorB
    private let gutterColor = Theme.gutter
    private let markingColor = Theme.laneMarking

    // MARK: - Layout constants (from Figma, as ratios of 244 x 575)

    private let boardCount = 39
    private let gutterRatio: CGFloat = 25.0 / 244.0
    private let pinDiameterRatio: CGFloat = 24.0 / 244.0

    /// Pin center positions relative to the lane bounding box (244 x 575).
    /// Standard 4-3-2-1 triangle: back row at top, head pin lower.
    private let pinPositions: [(x: CGFloat, y: CGFloat)] = [
        // Row 1 — 4 pins (7, 8, 9, 10)
        (54.0 / 244.0, 29.0 / 575.0),
        (99.0 / 244.0, 29.0 / 575.0),
        (145.0 / 244.0, 29.0 / 575.0),
        (190.0 / 244.0, 29.0 / 575.0),
        // Row 2 — 3 pins (4, 5, 6)
        (75.0 / 244.0, 60.0 / 575.0),
        (123.0 / 244.0, 60.0 / 575.0),
        (168.0 / 244.0, 60.0 / 575.0),
        // Row 3 — 2 pins (2, 3)
        (99.0 / 244.0, 91.0 / 575.0),
        (145.0 / 244.0, 91.0 / 575.0),
        // Row 4 — head pin (1)
        (123.0 / 244.0, 123.0 / 575.0),
    ]

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let gutterW = w * gutterRatio

            ZStack {
                laneBody(w: w, h: h, gutterW: gutterW)
                gutters(w: w, h: h, gutterW: gutterW)
                pins(w: w, h: h)
            }
        }
        .aspectRatio(244.0 / 575.0, contentMode: .fit)
        .clipped()
    }

    // MARK: - Lane Body (39 boards with thin black separators)

    @ViewBuilder
    private func laneBody(w: CGFloat, h: CGFloat, gutterW: CGFloat) -> some View {
        let laneW = w - gutterW * 2

        HStack(spacing: 0) {
            ForEach(0..<boardCount, id: \.self) { i in
                Rectangle()
                    .fill(i.isMultiple(of: 2) ? boardColorA : boardColorB)
            }
        }
        .frame(width: laneW, height: h)
        .position(x: w / 2, y: h / 2)
    }

    // MARK: - Gutters

    @ViewBuilder
    private func gutters(w: CGFloat, h: CGFloat, gutterW: CGFloat) -> some View {
        Rectangle()
            .fill(gutterColor)
            .frame(width: gutterW, height: h)
            .position(x: gutterW / 2, y: h / 2)

        Rectangle()
            .fill(gutterColor)
            .frame(width: gutterW, height: h)
            .position(x: w - gutterW / 2, y: h / 2)
    }

    // MARK: - Pins (10 pins in 4-3-2-1 triangle)

    @ViewBuilder
    private func pins(w: CGFloat, h: CGFloat) -> some View {
        let diameter = w * pinDiameterRatio

        ZStack {
            ForEach(0..<pinPositions.count, id: \.self) { i in
                Circle()
                    .fill(Theme.pinFill)
                    .overlay(Circle().stroke(Theme.pinStroke, lineWidth: 0.75))
                    .frame(width: diameter, height: diameter)
                    .position(x: w * pinPositions[i].x, y: h * pinPositions[i].y)
            }
        }
    }
}

#Preview {
    Last20FeetLaneView()
        .frame(width: 244, height: 575)
        .padding()
        .background(Theme.background)
}
