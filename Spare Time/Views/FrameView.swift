import SwiftUI

enum FrameStep {
    case keypad
    case pinSelection
    case drawing
    case breakpoint
}

struct FrameView: View {
    let frameNumber: Int
    var previousTotal: Int = 0
    var onComplete: (Frame, [Int], LineDrawing?, FrameStep) -> Void = { _, _, _, _ in }
    var onPreviousFrame: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil

    @State private var frame: Frame
    @State private var step: FrameStep = .keypad
    @State private var enteringFirst: Bool = true
    @State private var enteringThird: Bool = false
    @State private var pins: [Pin] = Pin.defaultSet()

    // Coordinate state
    @State private var releaseCoord = LaneCoordinate(x: 1.75, y: 0)
    @State private var arrowsCoord = LaneCoordinate(x: 1.75, y: 15)
    @State private var breakpointCoord: LaneCoordinate? = nil
    @State private var entryCoord: LaneCoordinate? = nil
    @State private var skippedDrawing = false

    private let bgColor = Theme.background

    init(
        frameNumber: Int,
        previousTotal: Int = 0,
        initialFrame: Frame? = nil,
        initialStep: FrameStep = .keypad,
        onComplete: @escaping (Frame, [Int], LineDrawing?, FrameStep) -> Void = { _, _, _, _ in },
        onPreviousFrame: (() -> Void)? = nil,
        onCancel: (() -> Void)? = nil
    ) {
        self.frameNumber = frameNumber
        self.previousTotal = previousTotal
        self.onComplete = onComplete
        self.onPreviousFrame = onPreviousFrame
        self.onCancel = onCancel
        _frame = State(initialValue: initialFrame ?? Frame(id: frameNumber))
        _step = State(initialValue: initialStep)
    }

    var runningTotal: Int? {
        guard let ft = frame.frameTotal else { return nil }
        return previousTotal + ft
    }

    var canAdvance: Bool {
        switch step {
        case .keypad:
            if frameNumber == 10 {
                guard frame.firstShot != nil, frame.secondShot != nil else { return false }
                return !frame.earnsThirdShot || frame.thirdShot != nil
            }
            return frame.firstShot != nil && (frame.isStrike || frame.secondShot != nil)
        case .pinSelection:
            let needed = frame.pinsRemaining
            return pins.filter { $0.isSelected }.count == needed
        case .drawing, .breakpoint:
            return true
        }
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: back-to-previous-frame arrow + frame label
                HStack {
                    if let cancel = onCancel, frameNumber == 1, step == .keypad {
                        Button {
                            cancel()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.primary.opacity(0.5))
                        }
                        .padding(.leading, 20)
                    } else if let goBack = onPreviousFrame, step == .keypad {
                        Button {
                            goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Theme.primary.opacity(0.6))
                        }
                        .padding(.leading, 20)
                    }

                    Spacer()
                }
                .overlay {
                    if step != .drawing && step != .breakpoint {
                        Text("Frame \(frameNumber)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.primary)
                    }
                }
                .padding(.top, 20)

                if step != .drawing && step != .breakpoint {
                    Spacer()
                }

                // Score box — hidden during drawing/breakpoint steps
                if step != .drawing && step != .breakpoint {
                    FrameScoreBoxView(frame: frame, runningTotal: runningTotal)

                    Spacer()
                }

                // Step content
                Group {
                    switch step {
                    case .keypad:
                        KeypadView(onTap: handleKeyTap)
                            .padding(.horizontal, 40)

                    case .pinSelection:
                        VStack(spacing: 8) {
                            Text("Select the \(frame.pinsRemaining) remaining pin\(frame.pinsRemaining == 1 ? "" : "s")")
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.secondary)
                            PinLayoutView(pins: $pins, requiredSelections: frame.pinsRemaining)
                        }

                    case .drawing:
                        VStack(spacing: 16) {
                            Text("Estimate your ball position\nat release and the arrows")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Theme.primary)
                                .multilineTextAlignment(.center)

                            ReleaseView(
                                releaseCoord: $releaseCoord,
                                arrowsCoord: $arrowsCoord
                            )
                            .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)

                    case .breakpoint:
                        VStack(spacing: 16) {
                            Text("Tap where your ball breaks,\nthen set entry angle")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Theme.primary)
                                .multilineTextAlignment(.center)

                            BreakpointView(
                                breakpointCoord: $breakpointCoord,
                                entryCoord: $entryCoord
                            )
                            .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: step)

                Spacer()

                // Navigation row
                if step == .drawing || step == .breakpoint {
                    HStack {
                        Button {
                            goBackStep()
                        } label: {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20))
                                .foregroundStyle(Theme.primary)
                        }
                        .padding(.leading, 28)

                        Spacer()

                        Button {
                            skipDrawing()
                        } label: {
                            Text("Skip this step")
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.secondary)
                        }

                        Button {
                            advanceStep()
                        } label: {
                            Text("Continue")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.primary.opacity(canContinueDrawing ? 0.8 : 0.3))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.surface.opacity(canContinueDrawing ? 1 : 0.3))
                                )
                        }
                        .disabled(!canContinueDrawing)
                        .padding(.trailing, 28)
                    }
                    .padding(.bottom, 36)
                } else {
                    HStack {
                        if step != .keypad {
                            Button {
                                goBackStep()
                            } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Theme.primary)
                            }
                            .padding(.leading, 28)
                        }

                        Spacer()

                        Button {
                            advanceStep()
                        } label: {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 20))
                                .foregroundStyle(Theme.primary)
                                .opacity(canAdvance ? 1 : 0.3)
                        }
                        .disabled(!canAdvance)
                        .padding(.trailing, 28)
                    }
                    .padding(.bottom, 36)
                }
            }
        }
    }

    private func handleKeyTap(_ key: String) {
        if frameNumber == 10 {
            handle10thFrameKey(key)
        } else if enteringFirst {
            handleFirstShot(key)
        } else {
            handleSecondShot(key)
        }
    }

    private func handleFirstShot(_ key: String) {
        switch key {
        case "X":
            frame.firstShot = 10
            enteringFirst = false
        case "<":
            frame.firstShot = nil
        case "/":
            break
        default:
            if let val = Int(key), val >= 0, val <= 9 {
                frame.firstShot = val
                enteringFirst = false
            }
        }
    }

    private func handleSecondShot(_ key: String) {
        guard let first = frame.firstShot else { return }
        switch key {
        case "X":
            break
        case "<":
            frame.secondShot = nil
            enteringFirst = true
        case "/":
            frame.secondShot = -1
        default:
            if let val = Int(key), val >= 0, val + first <= 10 {
                frame.secondShot = val
            }
        }
    }

    // MARK: - 10th Frame Key Handling

    private func handle10thFrameKey(_ key: String) {
        if enteringFirst {
            handle10thShot1(key)
        } else if enteringThird {
            handle10thShot3(key)
        } else {
            handle10thShot2(key)
        }
    }

    private func handle10thShot1(_ key: String) {
        switch key {
        case "X":
            frame.firstShot = 10
            enteringFirst = false
        case "<":
            frame.firstShot = nil
        case "/":
            break
        default:
            if let val = Int(key), val >= 0, val <= 9 {
                frame.firstShot = val
                enteringFirst = false
            }
        }
    }

    private func handle10thShot2(_ key: String) {
        guard let first = frame.firstShot else { return }
        switch key {
        case "<":
            frame.secondShot = nil
            enteringFirst = true
            enteringThird = false
        case "X":
            if first == 10 {
                frame.secondShot = 10
                enteringThird = true
            }
        case "/":
            if first < 10 {
                frame.secondShot = -1
                enteringThird = true
            }
        default:
            if let val = Int(key), val >= 0 {
                if first == 10 {
                    if val <= 9 {
                        frame.secondShot = val
                        enteringThird = true
                    }
                } else if val + first < 10 {
                    frame.secondShot = val
                }
            }
        }
    }

    private func handle10thShot3(_ key: String) {
        guard let first = frame.firstShot, let second = frame.secondShot else { return }
        switch key {
        case "<":
            frame.thirdShot = nil
        case "X":
            if (first == 10 && second == 10) || (first < 10 && second == -1) {
                frame.thirdShot = 10
            }
        case "/":
            if first == 10 && second >= 0 && second < 10 {
                frame.thirdShot = -1
            }
        default:
            if let val = Int(key), val >= 0 {
                if first == 10 && second == 10 {
                    if val <= 9 { frame.thirdShot = val }
                } else if first == 10 && second < 10 {
                    if val < (10 - second) { frame.thirdShot = val }
                } else if first < 10 && second == -1 {
                    if val <= 9 { frame.thirdShot = val }
                }
            }
        }
    }

    var canContinueDrawing: Bool {
        switch step {
        case .drawing:
            return true // sliders have defaults
        case .breakpoint:
            return breakpointCoord != nil // must tap to place breakpoint
        default:
            return true
        }
    }

    private func skipDrawing() {
        skippedDrawing = true
        let pinsStanding = pins.filter { $0.isSelected }.map { $0.id }
        onComplete(frame, pinsStanding, nil, step)
    }

    private func goBackStep() {
        switch step {
        case .keypad:
            break
        case .pinSelection:
            pins = Pin.defaultSet()
            step = .keypad
        case .drawing:
            if frameNumber == 10 {
                step = .keypad
                enteringFirst = false
                enteringThird = frame.earnsThirdShot
            } else {
                step = frame.isStrike ? .keypad : .pinSelection
            }
        case .breakpoint:
            step = .drawing
        }
    }

    private func advanceStep() {
        switch step {
        case .keypad:
            if frameNumber == 10 || frame.isStrike {
                step = .drawing
            } else {
                step = .pinSelection
            }
        case .pinSelection:
            step = .drawing
        case .drawing:
            step = .breakpoint
        case .breakpoint:
            let pinsStanding = pins.filter { $0.isSelected }.map { $0.id }
            let lineDrawing: LineDrawing? = {
                guard let bp = breakpointCoord, let ep = entryCoord else { return nil }
                return LineDrawing(
                    release: releaseCoord,
                    arrows: arrowsCoord,
                    breakpoint: bp,
                    entry_point: ep
                )
            }()
            onComplete(frame, pinsStanding, lineDrawing, .breakpoint)
        }
    }
}

#Preview {
    FrameView(frameNumber: 1)
}
