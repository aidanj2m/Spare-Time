import SwiftUI

struct ReleaseView: View {
    @Binding var releaseCoord: LaneCoordinate
    @Binding var arrowsCoord: LaneCoordinate

    @State private var releaseValue: Double = 0.5
    @State private var arrowsValue: Double = 0.5

    // Mirror First15FeetLaneView constants
    private let gutterRatio: CGFloat    = 25.0 / 246.0
    private let boardCount: CGFloat     = 39
    private let foulLineHRatio: CGFloat = 20.0 / 335.0
    private let markerBoards            = [4, 9, 14, 19, 24, 29, 34]
    private let arrowYRatios: [CGFloat]  = [83/335, 64/335, 45/335, 27/335, 45/335, 64/335, 83/335]
    private let arrowHRatios: [CGFloat]  = [24/335, 25/335, 25/335, 24/335, 25/335, 24/335, 24/335]

    // Real-world Y for each arrow: outer=12, inner=13, 14, center=15
    private let arrowRealY: [Double] = [12, 13, 14, 15, 14, 13, 12]

    var body: some View {
        VStack(spacing: 8) {
            Text("first 15 feet")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.secondary)

            ZStack {
                First15FeetLaneView()

                // Overlay markers using same coordinate space
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    let relPos  = releasePos(t: CGFloat(releaseValue), w: w, h: h)
                    let arwPos  = arrowPos(t: CGFloat(arrowsValue), w: w, h: h)

                    // Release ball — moves horizontally at the lane/foul-line edge
                    Image("ballImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .position(relPos)

                    // Arrows ball — follows the V-path at triangle centers
                    Image("ballImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .position(arwPos)
                }
            }
            .aspectRatio(246.0 / 335.0, contentMode: .fit)

            // Sliders
            VStack(alignment: .leading, spacing: 16) {
                sliderRow(label: "Release", value: $releaseValue)
                sliderRow(label: "Arrows",  value: $arrowsValue)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
        }
        .onChange(of: releaseValue) { updateReleaseCoord() }
        .onChange(of: arrowsValue) { updateArrowsCoord() }
        .onAppear {
            updateReleaseCoord()
            updateArrowsCoord()
        }
    }

    // MARK: - Coordinate conversion

    private func updateReleaseCoord() {
        let t = releaseValue
        releaseCoord = LaneCoordinate(x: t * 3.5, y: 0)
    }

    private func updateArrowsCoord() {
        let t = CGFloat(arrowsValue)
        let segCount = CGFloat(markerBoards.count - 1)
        let scaled   = min(max(t * segCount, 0), segCount - 0.0001)
        let idx      = Int(scaled)
        let frac     = Double(scaled - CGFloat(idx))

        // X: interpolate board positions to real-world feet
        let x0 = Double(markerBoards[idx]) / Double(boardCount) * 3.5
        let x1 = Double(markerBoards[idx + 1]) / Double(boardCount) * 3.5
        let realX = x0 + (x1 - x0) * frac

        // Y: interpolate real-world Y along the V-path
        let realY = arrowRealY[idx] + (arrowRealY[idx + 1] - arrowRealY[idx]) * frac

        arrowsCoord = LaneCoordinate(x: realX, y: realY)
    }

    // MARK: - Custom Slider

    private func sliderRow(label: String, value: Binding<Double>) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.secondary)
                .frame(width: 64, alignment: .leading)
            CustomSlider(value: value)
        }
        .frame(height: 36)
    }

    struct CustomSlider: View {
        @Binding var value: Double
        @State private var isDragging = false

        private let trackHeight: CGFloat = 2
        private let thumbSize: CGFloat = 12
        private let thumbGrown: CGFloat = 18
        private let trackColor = Theme.sliderTrack
        private let fillColor = Theme.sliderFill

        var body: some View {
            GeometryReader { geo in
                let w = geo.size.width
                let thumbR = isDragging ? thumbGrown / 2 : thumbSize / 2
                let thumbX = thumbR + CGFloat(value) * (w - thumbR * 2)

                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(trackColor)
                        .frame(height: trackHeight)

                    // Fill
                    Capsule()
                        .fill(fillColor)
                        .frame(width: thumbX, height: trackHeight)

                    // Thumb
                    Circle()
                        .fill(fillColor)
                        .frame(width: isDragging ? thumbGrown : thumbSize,
                               height: isDragging ? thumbGrown : thumbSize)
                        .position(x: thumbX, y: geo.size.height / 2)
                        .animation(.easeOut(duration: 0.15), value: isDragging)
                }
                .frame(height: geo.size.height)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            isDragging = true
                            let clamped = min(max(drag.location.x, thumbSize / 2), w - thumbSize / 2)
                            value = Double((clamped - thumbSize / 2) / (w - thumbSize))
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 24)
        }
    }

    // MARK: - Position helpers (view space)

    /// Release marker: moves horizontally at the top of the foul-line strip (lane start edge)
    private func releasePos(t: CGFloat, w: CGFloat, h: CGFloat) -> CGPoint {
        let gutterW = w * gutterRatio
        let laneW   = w - gutterW * 2
        let x = gutterW + t * laneW
        let y = h * (314.0 / 335.0)   // top edge of foul-line strip = bottom edge of lane boards
        return CGPoint(x: x, y: y)
    }

    /// Arrows marker: interpolates along the V-shaped arrow path
    private func arrowPos(t: CGFloat, w: CGFloat, h: CGFloat) -> CGPoint {
        let gutterW = w * gutterRatio
        let laneW   = w - gutterW * 2
        let boardW  = laneW / boardCount

        let segCount = CGFloat(markerBoards.count - 1)
        let scaled   = min(max(t * segCount, 0), segCount - 0.0001)
        let idx      = Int(scaled)
        let frac     = scaled - CGFloat(idx)

        let x0 = gutterW + CGFloat(markerBoards[idx])     * boardW + boardW / 2
        let x1 = gutterW + CGFloat(markerBoards[idx + 1]) * boardW + boardW / 2
        // centroid of upward triangle = tip + 2/3 * height
        let y0 = h * (arrowYRatios[idx]     + arrowHRatios[idx]     * 2/3)
        let y1 = h * (arrowYRatios[idx + 1] + arrowHRatios[idx + 1] * 2/3)

        return CGPoint(x: x0 + (x1 - x0) * frac, y: y0 + (y1 - y0) * frac)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var release = LaneCoordinate(x: 1.75, y: 0)
        @State var arrows = LaneCoordinate(x: 1.75, y: 15)
        var body: some View {
            ReleaseView(releaseCoord: $release, arrowsCoord: $arrows)
                .frame(width: 260)
                .padding()
                .background(Theme.background)
        }
    }
    return PreviewWrapper()
}
