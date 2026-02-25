import SwiftUI

enum Theme {
    // MARK: - Core Palette

    /// Primary text color - warm cream (#F0EDE5)
    static let primary = Color(red: 0xF0 / 255, green: 0xED / 255, blue: 0xE5 / 255)

    /// Secondary text / labels - muted blue-gray (#8A9BAD)
    static let secondary = Color(red: 0x8A / 255, green: 0x9B / 255, blue: 0xAD / 255)

    /// Main background - dark navy (#1B2D3E)
    static let background = Color(red: 0x1B / 255, green: 0x2D / 255, blue: 0x3E / 255)

    /// Card/surface background (#243447)
    static let surface = Color(red: 0x24 / 255, green: 0x34 / 255, blue: 0x47 / 255)

    /// Secondary surface - medium blue (#315171)
    static let surfaceSecondary = Color(red: 0x31 / 255, green: 0x51 / 255, blue: 0x71 / 255)

    /// Neon accent / highlighter (#00E5CC)
    static let neon = Color(red: 0x00 / 255, green: 0xE5 / 255, blue: 0xCC / 255)

    /// Gold accent for stats (#FFA800)
    static let gold = Color(red: 0xFF / 255, green: 0xA8 / 255, blue: 0x00 / 255)

    /// Hot pink accent for stats (#FF3366)
    static let pink = Color(red: 0xFF / 255, green: 0x33 / 255, blue: 0x66 / 255)

    // MARK: - Semantic Aliases

    static let error = Color.red
    static let border = secondary.opacity(0.3)
    static let scorecardLine = secondary.opacity(0.5)

    // MARK: - Lane Colors

    static let boardColorA = surfaceSecondary                                        // #315171
    static let boardColorB = secondary                                               // #8A9BAD
    static let gutter = Color(red: 0x45 / 255, green: 0x45 / 255, blue: 0x45 / 255) // #454545
    static let laneMarking = primary                                                 // #F0EDE5
    static let foulLine = boardColorA
    static let pinFill = primary                                                     // #F0EDE5
    static let pinStroke = background

    // MARK: - Slider / Trajectory

    static let sliderTrack = neon.opacity(0.3)
    static let sliderFill = neon
    static let trajectory = neon.opacity(0.9)
    static let guideLines = neon.opacity(0.25)
}
