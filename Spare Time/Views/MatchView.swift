//
//  MatchView.swift
//  Spare Time
//
//  Created by Aidan McKenzie on 2/21/26.
//

import SwiftUI

struct MatchView: View {
    let match: APIService.MatchResponse

    @State private var frames: [APIService.FrameResponse] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                // Date header
                Text(formattedDate(match.date_played))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .padding(.top, 32)

                // Scorecard
                if !frames.isEmpty {
                    VStack(spacing: 0) {
                        // Frame numbers 1-5
                        frameNumberLabels(Array(1...5))
                        // Cells row 1
                        cellRow(Array(1...5))
                        // Cells row 2 (shared border with row 1)
                        cellRow(Array(6...10))
                        // Frame numbers 6-10
                        frameNumberLabels(Array(6...10))
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18))
                        .foregroundStyle(Theme.primary)
                }
            }
        }
        .task {
            await loadFrames()
        }
    }

    // MARK: - Layout Constants
    // Mirrors FrameScoreBoxView proportions: inner box = 50% of cell

    private let cellSize: CGFloat = 68

    // MARK: - Frame Number Labels

    private func frameNumberLabels(_ numbers: [Int]) -> some View {
        HStack(spacing: 0) {
            ForEach(numbers, id: \.self) { num in
                Text("\(num)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Cell Row (5 frames)

    private func cellRow(_ frameNumbers: [Int]) -> some View {
        HStack(spacing: -1) {
            ForEach(frameNumbers, id: \.self) { num in
                let frame = frames.first { $0.frame_number == num }
                if num == 10 {
                    tenthFrameCell(frame: frame)
                } else {
                    standardFrameCell(frame: frame)
                }
            }
        }
    }

    // MARK: - Standard Frame Cell (1-9)

    private func standardFrameCell(frame: APIService.FrameResponse?) -> some View {
        let half = cellSize / 2

        return ZStack {
            Theme.surface

            // Content
            VStack(spacing: 0) {
                // Top half: first shot (left) + second shot (right box)
                HStack(spacing: 0) {
                    Text(displayFirstShot(frame))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Text(displaySecondShot(frame))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(width: half, height: half)
                }
                .frame(height: half)

                // Bottom half: running total
                Text(frame?.running_total.map { "\($0)" } ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Inner box lines (vertical + horizontal)
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    path.move(to: CGPoint(x: w - half, y: 0))
                    path.addLine(to: CGPoint(x: w - half, y: half))
                    path.move(to: CGPoint(x: w - half, y: half))
                    path.addLine(to: CGPoint(x: w, y: half))
                }
                .stroke(Theme.scorecardLine, lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cellSize)
        .border(Theme.scorecardLine, width: 1)
    }

    // MARK: - 10th Frame Cell

    private func tenthFrameCell(frame: APIService.FrameResponse?) -> some View {
        let half = cellSize / 2

        return ZStack {
            Theme.surface

            VStack(spacing: 0) {
                // Top half: three shot boxes
                HStack(spacing: 0) {
                    Text(displayTenthFirst(frame))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Text(displayTenthSecond(frame))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    Text(displayTenthThird(frame))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: half)

                // Bottom half: running total
                Text(frame?.running_total.map { "\($0)" } ?? "")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Inner lines: two verticals dividing 3 boxes + horizontal at half
            GeometryReader { geo in
                let w = geo.size.width
                let third = w / 3

                Path { path in
                    path.move(to: CGPoint(x: third, y: 0))
                    path.addLine(to: CGPoint(x: third, y: half))
                    path.move(to: CGPoint(x: third * 2, y: 0))
                    path.addLine(to: CGPoint(x: third * 2, y: half))
                    path.move(to: CGPoint(x: 0, y: half))
                    path.addLine(to: CGPoint(x: w, y: half))
                }
                .stroke(Theme.scorecardLine, lineWidth: 1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: cellSize)
        .border(Theme.scorecardLine, width: 1)
    }

    // MARK: - Display Helpers

    private func displayFirstShot(_ frame: APIService.FrameResponse?) -> String {
        guard let frame else { return "" }
        if frame.is_strike { return "" }
        guard let shot = frame.first_shot else { return "" }
        return "\(shot)"
    }

    private func displaySecondShot(_ frame: APIService.FrameResponse?) -> String {
        guard let frame else { return "" }
        if frame.is_strike { return "X" }
        if frame.is_spare { return "/" }
        guard let shot = frame.second_shot else { return "" }
        return "\(shot)"
    }

    private func displayTenthFirst(_ frame: APIService.FrameResponse?) -> String {
        guard let frame, let shot = frame.first_shot else { return "" }
        return shot == 10 ? "X" : "\(shot)"
    }

    private func displayTenthSecond(_ frame: APIService.FrameResponse?) -> String {
        guard let frame, let shot = frame.second_shot else { return "" }
        if shot == 10 { return "X" }
        if frame.first_shot == 10 {
            return "\(shot)"
        }
        if frame.is_spare { return "/" }
        return "\(shot)"
    }

    private func displayTenthThird(_ frame: APIService.FrameResponse?) -> String {
        guard let frame, let shot = frame.third_shot else { return "" }
        return shot == 10 ? "X" : "\(shot)"
    }

    // MARK: - Date Formatting

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            let display = DateFormatter()
            display.dateFormat = "M/dd"
            return display.string(from: date)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: isoString) {
            let display = DateFormatter()
            display.dateFormat = "M/dd"
            return display.string(from: date)
        }
        return isoString
    }

    // MARK: - Data Loading

    private func loadFrames() async {
        do {
            let fetched = try await APIService.fetchFrames(matchId: match.id)
            frames = fetched.isEmpty ? Self.mockFrames : fetched
        } catch {
            print("[Match] Failed to load frames: \(error)")
            frames = Self.mockFrames
        }
    }

    // MARK: - Mock Data

    private static let mockFrames: [APIService.FrameResponse] = [
        .init(game_id: "mock", frame_number: 1,  first_shot: 9,  second_shot: 1,  third_shot: nil, is_strike: false, is_spare: true,  running_total: 19,  ball_speed: nil),
        .init(game_id: "mock", frame_number: 2,  first_shot: 9,  second_shot: 1,  third_shot: nil, is_strike: false, is_spare: true,  running_total: 36,  ball_speed: nil),
        .init(game_id: "mock", frame_number: 3,  first_shot: 7,  second_shot: 2,  third_shot: nil, is_strike: false, is_spare: false, running_total: 45,  ball_speed: nil),
        .init(game_id: "mock", frame_number: 4,  first_shot: 8,  second_shot: 1,  third_shot: nil, is_strike: false, is_spare: false, running_total: 54,  ball_speed: nil),
        .init(game_id: "mock", frame_number: 5,  first_shot: 9,  second_shot: 1,  third_shot: nil, is_strike: false, is_spare: true,  running_total: 74,  ball_speed: nil),
        .init(game_id: "mock", frame_number: 6,  first_shot: 10, second_shot: nil, third_shot: nil, is_strike: true,  is_spare: false, running_total: 101, ball_speed: nil),
        .init(game_id: "mock", frame_number: 7,  first_shot: 10, second_shot: nil, third_shot: nil, is_strike: true,  is_spare: false, running_total: 121, ball_speed: nil),
        .init(game_id: "mock", frame_number: 8,  first_shot: 7,  second_shot: 2,  third_shot: nil, is_strike: false, is_spare: false, running_total: 130, ball_speed: nil),
        .init(game_id: "mock", frame_number: 9,  first_shot: 10, second_shot: nil, third_shot: nil, is_strike: true,  is_spare: false, running_total: 160, ball_speed: nil),
        .init(game_id: "mock", frame_number: 10, first_shot: 10, second_shot: 10, third_shot: 10,  is_strike: true,  is_spare: false, running_total: 190, ball_speed: nil),
    ]
}

#Preview {
    NavigationStack {
        MatchView(match: APIService.MatchResponse(
            id: "preview",
            user_id: "preview-user",
            date_played: "2026-02-20T00:00:00Z",
            total_score: 190
        ))
    }
}
