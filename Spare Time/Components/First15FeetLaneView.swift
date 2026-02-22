import SwiftUI

struct First15FeetLaneView: View {
    // Figma frame: 246 x 335

    // MARK: - Colors

    private let boardColorA = Theme.boardColorA
    private let boardColorB = Theme.boardColorB
    private let gutterColor = Theme.gutter
    private let foulLineColor = Theme.foulLine
    private let markingColor = Theme.laneMarking

    // MARK: - Layout constants (from Figma, as ratios of 246 x 335)

    private let boardCount = 39
    private let gutterRatio: CGFloat = 25.0 / 246.0
    private let laneHeightRatio: CGFloat = 314.0 / 335.0
    private let foulLineHeightRatio: CGFloat = 20.0 / 335.0

    /// Boards where arrows and dots sit (1-indexed: 5, 10, 15, 20, 25, 30, 35)
    private let markerBoards = [4, 9, 14, 19, 24, 29, 34] // 0-indexed

    /// Arrow top-y positions (ratio of frame height), forming a V shape
    private let arrowYRatios: [CGFloat] = [
        83.0 / 335.0, 64.0 / 335.0, 45.0 / 335.0,
        27.0 / 335.0,
        45.0 / 335.0, 64.0 / 335.0, 83.0 / 335.0
    ]

    /// Arrow heights (ratio of frame height)
    private let arrowHRatios: [CGFloat] = [
        24.0 / 335.0, 25.0 / 335.0, 25.0 / 335.0,
        24.0 / 335.0,
        25.0 / 335.0, 24.0 / 335.0, 24.0 / 335.0
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
                arrows(w: w, h: h, gutterW: gutterW)
                foulLine(w: w, h: h)
                approachDots(w: w, h: h, gutterW: gutterW)
            }
        }
        .aspectRatio(246.0 / 335.0, contentMode: .fit)
        .clipped()
    }

    // MARK: - Lane Body (39 boards with thin black separators)

    @ViewBuilder
    private func laneBody(w: CGFloat, h: CGFloat, gutterW: CGFloat) -> some View {
        let laneW = w - gutterW * 2
        let laneH = h * laneHeightRatio
        let boardW = laneW / CGFloat(boardCount)

        HStack(spacing: 0) {
            ForEach(0..<boardCount, id: \.self) { i in
                Rectangle()
                    .fill(i.isMultiple(of: 2) ? boardColorA : boardColorB)
            }
        }
        .frame(width: laneW, height: laneH)
        .position(x: w / 2, y: laneH / 2)
    }

    // MARK: - Gutters

    @ViewBuilder
    private func gutters(w: CGFloat, h: CGFloat, gutterW: CGFloat) -> some View {
        let laneH = h * laneHeightRatio

        Rectangle()
            .fill(gutterColor)
            .frame(width: gutterW, height: laneH)
            .position(x: gutterW / 2, y: laneH / 2)

        Rectangle()
            .fill(gutterColor)
            .frame(width: gutterW, height: laneH)
            .position(x: w - gutterW / 2, y: laneH / 2)
    }

    // MARK: - Arrows (7 triangles in V-pattern)

    @ViewBuilder
    private func arrows(w: CGFloat, h: CGFloat, gutterW: CGFloat) -> some View {
        let laneW = w - gutterW * 2
        let boardW = laneW / CGFloat(boardCount)

        ZStack {
            ForEach(0..<markerBoards.count, id: \.self) { i in
                let centerX = gutterW + CGFloat(markerBoards[i]) * boardW + boardW / 2
                let arrowH = h * arrowHRatios[i]
                let arrowW = boardW
                let topY = h * arrowYRatios[i]

                LaneArrowShape()
                    .fill(markingColor)
                    .frame(width: arrowW, height: arrowH)
                    .position(x: centerX, y: topY + arrowH / 2)
            }
        }
    }

    // MARK: - Foul Line Strip

    @ViewBuilder
    private func foulLine(w: CGFloat, h: CGFloat) -> some View {
        let foulH = h * foulLineHeightRatio

        Rectangle()
            .fill(foulLineColor)
            .frame(width: w, height: foulH)
            .position(x: w / 2, y: h - foulH / 2)
    }

    // MARK: - Approach Dots

    @ViewBuilder
    private func approachDots(w: CGFloat, h: CGFloat, gutterW: CGFloat) -> some View {
        let laneW = w - gutterW * 2
        let boardW = laneW / CGFloat(boardCount)
        let dotSize = boardW
        let dotY = h * (1 - foulLineHeightRatio / 2) // centered in foul line strip

        ZStack {
            ForEach(0..<markerBoards.count, id: \.self) { i in
                let centerX = gutterW + CGFloat(markerBoards[i]) * boardW + boardW / 2

                Circle()
                    .fill(markingColor)
                    .frame(width: dotSize, height: dotSize)
                    .position(x: centerX, y: dotY)
            }
        }
    }
}

// MARK: - Arrow Shape (triangle pointing up)

private struct LaneArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

#Preview {
    First15FeetLaneView()
        .frame(width: 246, height: 335)
        .padding()
        .background(Theme.background)
}
