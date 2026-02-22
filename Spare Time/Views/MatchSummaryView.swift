import SwiftUI

struct MatchSummaryView: View {
    let matchId: String
    let completedFrames: [Frame]
    var onDone: () -> Void = {}

    @State private var lane: String = ""
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var isSaving = false

    @FocusState private var focusedField: Field?

    private enum Field { case lane, location, notes }
    private let cellSize: CGFloat = 58

    var totalScore: Int {
        completedFrames.compactMap { $0.runningTotal }.last ?? 0
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 4) {
                        Text("Final Score")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Theme.secondary)
                            .padding(.top, 60)

                        Text("\(totalScore)")
                            .font(.system(size: 88, weight: .heavy))
                            .foregroundStyle(Theme.primary)
                    }

                    // Scorecard
                    scorecard
                        .padding(.horizontal, 10)

                    // Input fields
                    VStack(spacing: 14) {
                        inputField(
                            label: "Lane",
                            placeholder: "lane number",
                            text: $lane,
                            focus: .lane
                        )
                        .keyboardType(.numberPad)

                        inputField(
                            label: "Location",
                            placeholder: "where did you bowl?",
                            text: $location,
                            focus: .location
                        )

                        notesField
                    }
                    .padding(.horizontal, 24)

                    // Complete button
                    Button {
                        focusedField = nil
                        Task { await complete() }
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView().tint(Theme.background)
                            } else {
                                Text("Complete")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Theme.background)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Theme.neon)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }

    // MARK: - Scorecard

    private var scorecard: some View {
        VStack(spacing: 0) {
            frameNumberRow(Array(1...5))
            frameRow(Array(1...5))
            frameRow(Array(6...10))
            frameNumberRow(Array(6...10))
        }
    }

    private func frameNumberRow(_ numbers: [Int]) -> some View {
        HStack(spacing: 0) {
            ForEach(numbers, id: \.self) { n in
                Text("\(n)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
            }
        }
    }

    private func frameRow(_ numbers: [Int]) -> some View {
        HStack(spacing: -1) {
            ForEach(numbers, id: \.self) { n in
                let f = completedFrames.first { $0.id == n }
                if n == 10 {
                    tenthCell(frame: f)
                } else {
                    standardCell(frame: f)
                }
            }
        }
    }

    private func standardCell(frame: Frame?) -> some View {
        let half = cellSize / 2
        return ZStack {
            Theme.surface
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(frame?.displayFirst ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text(frame?.displaySecond ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(width: half, height: half)
                }
                .frame(height: half)

                Text(frame?.runningTotal.map { "\($0)" } ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    path.move(to:    CGPoint(x: w - half, y: 0))
                    path.addLine(to: CGPoint(x: w - half, y: half))
                    path.move(to:    CGPoint(x: w - half, y: half))
                    path.addLine(to: CGPoint(x: w,        y: half))
                }
                .stroke(Theme.scorecardLine, lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cellSize)
        .border(Theme.scorecardLine, width: 1)
    }

    private func tenthCell(frame: Frame?) -> some View {
        let half = cellSize / 2
        return ZStack {
            Theme.surface
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(frame?.displayFirst ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text(frame?.displaySecond ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text(frame?.displayThird ?? "")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: half)

                Text(frame?.runningTotal.map { "\($0)" } ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            GeometryReader { geo in
                let w = geo.size.width
                let third = w / 3
                Path { path in
                    path.move(to:    CGPoint(x: third,     y: 0))
                    path.addLine(to: CGPoint(x: third,     y: half))
                    path.move(to:    CGPoint(x: third * 2, y: 0))
                    path.addLine(to: CGPoint(x: third * 2, y: half))
                    path.move(to:    CGPoint(x: 0,         y: half))
                    path.addLine(to: CGPoint(x: w,         y: half))
                }
                .stroke(Theme.scorecardLine, lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cellSize)
        .border(Theme.scorecardLine, width: 1)
    }

    // MARK: - Input Fields

    private func inputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        focus: Field
    ) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.primary)
                .frame(width: 68, alignment: .leading)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundStyle(Theme.primary)
                .focused($focusedField, equals: focus)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .tint(Theme.neon)
        }
    }

    private var notesField: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("Notes")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.primary)
                .frame(width: 68, alignment: .leading)
                .padding(.top, 12)
            TextEditor(text: $notes)
                .font(.system(size: 15))
                .foregroundStyle(Theme.primary)
                .focused($focusedField, equals: .notes)
                .frame(height: 88)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .scrollContentBackground(.hidden)
                .tint(Theme.neon)
        }
    }

    // MARK: - Complete

    private func complete() async {
        isSaving = true
        do {
            try await APIService.updateMatch(
                matchId: matchId,
                totalScore: totalScore,
                lane: Int(lane),
                location: location.isEmpty ? nil : location,
                notes: notes.isEmpty ? nil : notes
            )
        } catch {
            print("[Summary] Failed to update match: \(error)")
        }
        isSaving = false
        onDone()
    }
}

// MARK: - Confetti

private struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = ConfettiParticle.generate(count: 100)
    @State private var startDate: Date = .init()

    var body: some View {
        TimelineView(.animation) { tl in
            let elapsed = tl.date.timeIntervalSince(startDate)
            Canvas { ctx, size in
                let fade = elapsed < 4.5 ? 1.0 : max(0, 1.0 - (elapsed - 4.5) * 0.4)
                guard fade > 0 else { return }
                for p in particles {
                    let progress = (elapsed * p.speed + p.offset).truncatingRemainder(dividingBy: 1.0)
                    let x = p.x * size.width + sin(elapsed * p.wobble + p.phase) * 20
                    let y = progress * (size.height + 80) - 40
                    let rect = CGRect(x: x - p.w / 2, y: y, width: p.w, height: p.h)
                    ctx.fill(Path(rect), with: .color(p.color.opacity(fade * 0.88)))
                }
            }
        }
    }
}

private struct ConfettiParticle {
    var x: CGFloat
    var speed: Double
    var offset: Double
    var wobble: Double
    var phase: Double
    var w: CGFloat
    var h: CGFloat
    var color: Color

    static let palette: [Color] = [
        .red, .orange,
        Color(red: 1, green: 0.85, blue: 0),
        .green, .cyan, .blue, .purple, .pink,
        Color(red: 1, green: 0.4, blue: 0.7)
    ]

    static func generate(count: Int) -> [ConfettiParticle] {
        (0..<count).map { _ in
            let side = CGFloat.random(in: 7...14)
            return ConfettiParticle(
                x:      CGFloat.random(in: 0...1),
                speed:  Double.random(in: 0.10...0.25),
                offset: Double.random(in: 0...1),
                wobble: Double.random(in: 1.5...4.0),
                phase:  Double.random(in: 0...(.pi * 2)),
                w:      side,
                h:      side * CGFloat.random(in: 0.35...0.65),
                color:  palette.randomElement()!
            )
        }
    }
}

#Preview {
    MatchSummaryView(
        matchId: "preview",
        completedFrames: [
            Frame(id: 1,  firstShot: 10, secondShot: nil, runningTotal: 27),
            Frame(id: 2,  firstShot: 9,  secondShot: -1,  runningTotal: 47),
            Frame(id: 3,  firstShot: 7,  secondShot: 2,   runningTotal: 56),
            Frame(id: 4,  firstShot: 8,  secondShot: 1,   runningTotal: 65),
            Frame(id: 5,  firstShot: 10, secondShot: nil, runningTotal: 92),
            Frame(id: 6,  firstShot: 10, secondShot: nil, runningTotal: 112),
            Frame(id: 7,  firstShot: 7,  secondShot: 2,   runningTotal: 121),
            Frame(id: 8,  firstShot: 9,  secondShot: -1,  runningTotal: 141),
            Frame(id: 9,  firstShot: 10, secondShot: nil, runningTotal: 171),
            Frame(id: 10, firstShot: 10, secondShot: 10,  thirdShot: 10, runningTotal: 201),
        ]
    )
}
