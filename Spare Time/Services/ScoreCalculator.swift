import Foundation

struct ScoreCalculator {

    /// Returns running totals for each frame. Returns nil for frames not yet complete
    /// or where bonus balls haven't been bowled yet.
    static func runningTotals(for frames: [Frame]) -> [Int?] {
        var totals: [Int?] = Array(repeating: nil, count: frames.count)
        var cumulative = 0

        for (i, frame) in frames.enumerated() {
            guard let first = frame.firstShot else { break }

            if frame.id == 10 {
                // 10th frame: sum all shots bowled (no bonus from future frames)
                guard let second = resolveSecondShot(for: frame) else { break }
                if frame.earnsThirdShot {
                    guard let third = resolveThirdShot(for: frame) else { break }
                    cumulative += first + second + third
                } else {
                    cumulative += first + second
                }
                totals[i] = cumulative
            } else if frame.isStrike {
                if let bonus = strikeBonus(frames: frames, afterIndex: i) {
                    cumulative += 10 + bonus
                    totals[i] = cumulative
                }
            } else if frame.isSpare {
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

            // If this frame couldn't resolve, no later frames can either
            if totals[i] == nil { break }
        }

        return totals
    }

    private static func strikeBonus(frames: [Frame], afterIndex i: Int) -> Int? {
        var shots: [Int] = []
        for j in (i + 1)..<frames.count {
            let f = frames[j]
            guard let first = f.firstShot else { return nil }
            shots.append(first)
            // Get second shot from this frame if it's not a strike,
            // OR if it's the 10th frame (which always has a second shot)
            if shots.count == 1 && (first != 10 || f.id == 10), let second = f.secondShot {
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
        return next
    }

    private static func resolveSecondShot(for frame: Frame) -> Int? {
        guard let s = frame.secondShot else { return nil }
        return s == -1 ? (10 - (frame.firstShot ?? 0)) : s
    }

    private static func resolveThirdShot(for frame: Frame) -> Int? {
        guard frame.id == 10, let t = frame.thirdShot else { return nil }
        if t == -1, let f = frame.firstShot, f == 10, let s = frame.secondShot, s < 10 {
            return 10 - s
        }
        return t
    }
}
