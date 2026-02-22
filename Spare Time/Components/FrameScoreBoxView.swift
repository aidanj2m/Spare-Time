import SwiftUI

struct FrameScoreBoxView: View {
    let frame: Frame
    let runningTotal: Int?

    private let outerSize:    CGFloat = 120
    private let innerBoxSize: CGFloat = 60
    private let corner:       CGFloat = 16

    var body: some View {
        ZStack {
            Theme.surface

            VStack(spacing: 0) {
                if frame.id == 10 {
                    HStack(spacing: 0) {
                        Text(frame.displayFirst)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Text(frame.displaySecond)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Text(frame.displayThird)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: innerBoxSize)
                } else {
                    HStack(spacing: 0) {
                        Text(frame.displayFirst)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        Text(frame.displaySecond)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                            .frame(width: innerBoxSize, height: innerBoxSize)
                    }
                    .frame(height: innerBoxSize)
                }

                Text(runningTotal.map { "\($0)" } ?? "")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            GeometryReader { geo in
                let w = geo.size.width
                Path { path in
                    if frame.id == 10 {
                        let col = w / 3
                        path.move(to:    CGPoint(x: col,     y: 0))
                        path.addLine(to: CGPoint(x: col,     y: innerBoxSize))
                        path.move(to:    CGPoint(x: col * 2, y: 0))
                        path.addLine(to: CGPoint(x: col * 2, y: innerBoxSize))
                        path.move(to:    CGPoint(x: 0,       y: innerBoxSize))
                        path.addLine(to: CGPoint(x: w,       y: innerBoxSize))
                    } else {
                        path.move(to:    CGPoint(x: w - innerBoxSize, y: 0))
                        path.addLine(to: CGPoint(x: w - innerBoxSize, y: innerBoxSize))
                        path.move(to:    CGPoint(x: w - innerBoxSize, y: innerBoxSize))
                        path.addLine(to: CGPoint(x: w,                y: innerBoxSize))
                    }
                }
                .stroke(Theme.scorecardLine, lineWidth: 1)
            }
        }
        .frame(width: outerSize, height: outerSize)
        .clipShape(RoundedRectangle(cornerRadius: corner))
        .overlay(
            RoundedRectangle(cornerRadius: corner)
                .stroke(Theme.scorecardLine, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    VStack(spacing: 20) {
        let strike = Frame(id: 1, firstShot: 10)
        FrameScoreBoxView(frame: strike, runningTotal: 10)

        let spare = Frame(id: 1, firstShot: 9, secondShot: -1)
        FrameScoreBoxView(frame: spare, runningTotal: 10)
    }
    .padding()
    .background(Theme.background)
}
