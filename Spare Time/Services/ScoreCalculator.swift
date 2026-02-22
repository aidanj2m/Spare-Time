import Foundation

struct ScoreCalculator {

    /// Returns running totals for each frame. Returns nil for frames not yet complete
    /// or where bonus balls haven't been bowled yet.
    static func runningTotals(for frames: [Frame]) -> [Int?] {
        var totals: [Int?] = Array(repeating: nil, count: frames.count)
        var cumulative = 0

        for (i, frame) in frames.enumerated() {
            guard let first = frame.firstShot else { break }

            if frame.isStrike {
                // Strike: 10 + next two shots
                if let bonus = strikeBonus(frames: frames, afterIndex: i) {
                    cumulative += 10 + bonus
                    totals[i] = cumulative
                }
            } else if frame.isSpare {
                // Spare: 10 + next one shot
                if let bonus = spareBonus(frames: frames, afterIndex: i) {
                    cumulative += 10 + bonus
                    totals[i] = cumulative
                }
            } else {
                guard let second = frame.secondShot else { break }
                let pinCount = second == -1 ? (10 - first) : second
                cumulative += first + pinCount
                totals[i] = cumulative
            }
        }

        return totals
    }

    private static func strikeBonus(frames: [Frame], afterIndex i: Int) -> Int? {
        var shots: [Int] = []
        for j in (i + 1)..<frames.count {
            let f = frames[j]
            guard let first = f.firstShot else { return nil }
            shots.append(first == 10 ? 10 : first)
            if shots.count == 1 && first != 10, let second = f.secondShot {
                let s = second == -1 ? (10 - first) : second
                shots.append(s)
            }
            if shots.count >= 2 { break }
        }
        guard shots.count >= 2 else { return nil }
        return shots[0] + shots[1]
    }

    private static func spareBonus(frames: [Frame], afterIndex i: Int) -> Int? {
        guard i + 1 < frames.count, let next = frames[i + 1].firstShot else { return nil }
        return next == 10 ? 10 : next
    }
}
