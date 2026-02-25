//
//  ContentView.swift
//  Spare Time
//
//  Created by Aidan McKenzie on 2/19/26.
//

import SwiftUI

struct ContentView: View {
    let userId: String
    @Binding var matchId: String

    @State private var currentFrame: Int = 1
    @State private var completedFrames: [Frame] = []
    @State private var framePins: [Int: [Int]] = [:]  // frameNumber -> pinsStanding
    @State private var frameDrawings: [Int: LineDrawing] = [:]  // frameNumber -> lineDrawing
    @State private var frameBallSpeeds: [Int: Int] = [:]  // frameNumber -> ballSpeed
    @State private var frameLastStep: [Int: FrameStep] = [:]  // frameNumber -> last step
    @State private var showSummary = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FrameView(
            frameNumber: currentFrame,
            completedFrames: completedFrames,
            initialFrame: completedFrames.first { $0.id == currentFrame },
            initialStep: frameLastStep[currentFrame] ?? .keypad,
            onComplete: handleFrameComplete,
            onPreviousFrame: currentFrame > 1 ? { goToPreviousFrame() } : nil,
            onCancel: { goHome() }
        )
        .id(currentFrame)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
        .fullScreenCover(isPresented: $showSummary) {
            MatchSummaryView(
                matchId: matchId,
                userId: userId,
                completedFrames: completedFrames,
                onDone: {
                    showSummary = false
                    dismiss()
                }
            )
        }
        .task(id: matchId) {
            await loadExistingFrames()
        }
    }

    // MARK: - Bowling Score Calculation

    /// Get the raw shot value for a frame's second shot (converts spare sentinel -1 to actual pins)
    private func actualSecondShot(for frame: Frame) -> Int? {
        guard let s = frame.secondShot else { return nil }
        if s == -1 { return frame.pinsRemaining }
        return s
    }

    /// Get the raw pin count for the 10th frame's third shot
    private func actualThirdShot(for frame: Frame) -> Int? {
        guard frame.id == 10, let t = frame.thirdShot else { return nil }
        if t == -1, let f = frame.firstShot, let s = frame.secondShot, f == 10, s < 10 {
            return 10 - s
        }
        return t
    }

    /// Recalculate running totals for all completed frames using standard bowling rules.
    private func recalculateRunningTotals(_ frames: [Frame]) -> [Frame] {
        var updated = frames
        var cumulative = 0

        for i in 0..<updated.count {
            let f = updated[i]
            guard let first = f.firstShot else {
                updated[i].runningTotal = nil
                continue
            }

            // 10th frame: sum all shots bowled (no bonus from other frames)
            if f.id == 10 {
                let second = actualSecondShot(for: f) ?? 0
                let third  = actualThirdShot(for: f)  ?? 0
                cumulative += first + second + third
                updated[i].runningTotal = cumulative
            } else if f.isStrike {
                let nextBalls = getNextTwoBalls(after: i, in: frames)
                if let (b1, b2) = nextBalls {
                    cumulative += 10 + b1 + b2
                    updated[i].runningTotal = cumulative
                } else {
                    updated[i].runningTotal = nil
                }
            } else if f.isSpare {
                let nextBall = getNextOneBall(after: i, in: frames)
                if let b1 = nextBall {
                    cumulative += 10 + b1
                    updated[i].runningTotal = cumulative
                } else {
                    updated[i].runningTotal = nil
                }
            } else {
                // Open frame
                let second = actualSecondShot(for: f) ?? 0
                cumulative += first + second
                updated[i].runningTotal = cumulative
            }

            if updated[i].runningTotal == nil {
                for j in (i + 1)..<updated.count {
                    updated[j].runningTotal = nil
                }
                break
            }
        }

        return updated
    }

    private func getNextOneBall(after index: Int, in frames: [Frame]) -> Int? {
        let next = index + 1
        guard next < frames.count, let first = frames[next].firstShot else { return nil }
        return first
    }

    private func getNextTwoBalls(after index: Int, in frames: [Frame]) -> (Int, Int)? {
        let next = index + 1
        guard next < frames.count, let first = frames[next].firstShot else { return nil }

        if frames[next].isStrike && next < 9 {
            let nextNext = next + 1
            guard nextNext < frames.count, let secondBall = frames[nextNext].firstShot else { return nil }
            return (first, secondBall)
        } else {
            guard let second = actualSecondShot(for: frames[next]) else { return nil }
            return (first, second)
        }
    }

    // MARK: - Frame Completion

    private func handleFrameComplete(frame: Frame, pinsStanding: [Int], lineDrawing: LineDrawing?, ballSpeed: Int?, lastStep: FrameStep) {
        frameLastStep[frame.id] = lastStep
        framePins[frame.id] = pinsStanding
        if let ld = lineDrawing {
            frameDrawings[frame.id] = ld
        }
        if let speed = ballSpeed {
            frameBallSpeeds[frame.id] = speed
        }

        let oldTotals = completedFrames.map { $0.runningTotal }

        // Replace if editing, otherwise append
        if let idx = completedFrames.firstIndex(where: { $0.id == frame.id }) {
            completedFrames[idx] = frame
        } else {
            completedFrames.append(frame)
        }
        completedFrames = recalculateRunningTotals(completedFrames)

        // Upsert current frame + any previous frames whose running_total changed
        let framesToUpsert = completedFrames
        let currentMatchId = matchId
        Task {
            guard !currentMatchId.isEmpty else { return }
            for (i, f) in framesToUpsert.enumerated() {
                let isCurrentFrame = f.id == frame.id
                let totalChanged = i < oldTotals.count && oldTotals[i] != f.runningTotal
                guard isCurrentFrame || totalChanged else { continue }

                let payload = APIService.FramePayload(
                    game_id: currentMatchId,
                    frame_number: f.id,
                    first_shot: f.firstShot,
                    second_shot: actualSecondShot(for: f),
                    third_shot: actualThirdShot(for: f),
                    is_strike: f.isStrike,
                    is_spare: f.isSpare,
                    pins_standing: framePins[f.id] ?? [],
                    running_total: f.runningTotal,
                    line_drawing: frameDrawings[f.id],
                    ball_speed: frameBallSpeeds[f.id]
                )
                do {
                    try await APIService.upsertFrame(payload)
                } catch {
                    print("[API] Failed to upsert frame \(f.id): \(error)")
                }
            }
        }

        // Advance or finish
        if currentFrame < 10 {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentFrame += 1
            }
        } else {
            showSummary = true
        }
    }

    // MARK: - Go Home

    private func goHome() {
        if completedFrames.isEmpty && !matchId.isEmpty {
            // No frames entered — delete the empty match
            Task {
                try? await APIService.deleteMatch(matchId: matchId)
                dismiss()
            }
        } else {
            dismiss()
        }
    }

    // MARK: - Resume existing match

    private func loadExistingFrames() async {
        guard !matchId.isEmpty else { return }
        do {
            let apiFrames = try await APIService.fetchFrames(matchId: matchId)
            guard !apiFrames.isEmpty else { return }

            var loaded: [Frame] = []
            for af in apiFrames.sorted(by: { $0.frame_number < $1.frame_number }) {
                var frame = Frame(id: af.frame_number)
                frame.firstShot = af.first_shot

                if af.frame_number < 10 {
                    frame.secondShot = af.is_spare ? -1 : af.second_shot
                } else {
                    // 10th frame second shot
                    if af.is_spare {
                        frame.secondShot = -1
                    } else {
                        frame.secondShot = af.second_shot
                    }
                    // 10th frame third shot: detect spare (X, n, /)
                    if let first = af.first_shot, first == 10,
                       let second = af.second_shot, second > 0, second < 10,
                       let third = af.third_shot, second + third == 10 {
                        frame.thirdShot = -1
                    } else {
                        frame.thirdShot = af.third_shot
                    }
                }

                frame.runningTotal = af.running_total
                loaded.append(frame)

                if let speed = af.ball_speed {
                    frameBallSpeeds[af.frame_number] = speed
                }
            }

            completedFrames = loaded
            currentFrame = min(loaded.count + 1, 10)
        } catch {
            print("[ContentView] Failed to load existing frames: \(error)")
        }
    }

    // MARK: - Navigation

    private func goToPreviousFrame() {
        withAnimation(.easeInOut(duration: 0.35)) {
            currentFrame -= 1
        }
    }
}

#Preview {
    ContentView(userId: "preview-user", matchId: .constant("preview-match"))
}
