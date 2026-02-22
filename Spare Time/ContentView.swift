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
    @State private var frameLastStep: [Int: FrameStep] = [:]  // frameNumber -> last step
    @State private var showSummary = false
    @Environment(\.dismiss) private var dismiss

    /// Last resolved cumulative running total from completed frames
    private var previousTotal: Int {
        // Walk backwards through completed frames to find the last non-nil running total
        for frame in completedFrames.reversed() {
            if let total = frame.runningTotal {
                return total
            }
        }
        return 0
    }

    var body: some View {
        FrameView(
            frameNumber: currentFrame,
            previousTotal: previousTotal,
            initialFrame: completedFrames.first { $0.id == currentFrame },
            initialStep: frameLastStep[currentFrame] ?? .keypad,
            onComplete: handleFrameComplete,
            onPreviousFrame: currentFrame > 1 ? { goToPreviousFrame() } : nil,
            onCancel: { Task { await cancelMatch() } }
        )
        .id(currentFrame)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
        .fullScreenCover(isPresented: $showSummary) {
            MatchSummaryView(
                matchId: matchId,
                completedFrames: completedFrames,
                onDone: {
                    showSummary = false
                    dismiss()
                }
            )
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

    private func handleFrameComplete(frame: Frame, pinsStanding: [Int], lineDrawing: LineDrawing?, lastStep: FrameStep) {
        frameLastStep[frame.id] = lastStep
        framePins[frame.id] = pinsStanding
        if let ld = lineDrawing {
            frameDrawings[frame.id] = ld
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
                    line_drawing: frameDrawings[f.id]
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

    // MARK: - Cancel / delete match

    private func cancelMatch() async {
        guard !matchId.isEmpty else { dismiss(); return }
        do {
            try await APIService.deleteMatch(matchId: matchId)
        } catch {
            print("[API] Failed to delete match: \(error)")
        }
        dismiss()
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
