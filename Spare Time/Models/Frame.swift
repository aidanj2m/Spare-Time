import Foundation

struct LaneCoordinate: Codable {
    var x: Double  // 0 to 3.5 (feet across lane)
    var y: Double  // 0 (foul line) to ~62 (pin deck)
}

struct LineDrawing: Codable {
    var release: LaneCoordinate
    var arrows: LaneCoordinate
    var breakpoint: LaneCoordinate
    var entry_point: LaneCoordinate
}

struct Frame: Identifiable {
    let id: Int
    var firstShot: Int? = nil    // nil = not entered, 10 = strike
    var secondShot: Int? = nil   // nil = not entered, -1 = spare
    var thirdShot: Int? = nil    // 10th frame bonus ball; -1 = spare on remaining (X,n,/)

    var isStrike: Bool { firstShot == 10 }
    var isSpare: Bool {
        guard !isStrike, let f = firstShot, let s = secondShot else { return false }
        return s == -1 || (f + s == 10)
    }

    /// 10th frame: first two balls earned a third shot
    var earnsThirdShot: Bool {
        guard id == 10, let f = firstShot, let s = secondShot else { return false }
        return f == 10 || s == -1  // strike or spare
    }

    var pinsRemaining: Int {
        guard let f = firstShot, !isStrike else { return 0 }
        return 10 - f
    }

    // MARK: Display

    var displayFirst: String {
        guard let f = firstShot else { return "" }
        if id == 10 { return f == 10 ? "X" : "\(f)" }
        return f == 10 ? "" : "\(f)"
    }

    var displaySecond: String {
        if id == 10 {
            guard let f = firstShot, let s = secondShot else { return "" }
            if f == 10 { return s == 10 ? "X" : "\(s)" }
            return s == -1 ? "/" : "\(s)"
        }
        if isStrike { return "X" }
        guard let s = secondShot else { return "" }
        return s == -1 ? "/" : "\(s)"
    }

    var displayThird: String {
        guard id == 10, let f = firstShot, let s = secondShot, let t = thirdShot else { return "" }
        if f == 10 && s == 10 { return t == 10 ? "X" : "\(t)" }
        if f == 10 && s < 10  { return t == -1 ? "/" : (t == 10 ? "X" : "\(t)") }
        return t == 10 ? "X" : "\(t)"   // n,/,_ — fresh rack
    }

    // MARK: Scoring

    var frameTotal: Int? {
        guard let f = firstShot else { return nil }

        if id == 10 {
            guard let s = secondShot else { return nil }
            let sVal = s == -1 ? (10 - f) : s
            if earnsThirdShot {
                guard let t = thirdShot else { return nil }
                let tVal = (f == 10 && s < 10 && t == -1) ? (10 - s) : t
                return f + sVal + tVal
            }
            return f + sVal
        }

        if isStrike { return nil }
        guard let s = secondShot else { return nil }
        if isSpare { return nil }
        return f + s
    }

    var runningTotal: Int? = nil
}
