import Foundation

struct Pin: Identifiable {
    let id: Int         // 1–10, standard pin numbering
    var isStanding: Bool = true
    var isSelected: Bool = false

    // Standard pin layout positions as (row, col) in a grid
    // Row 0 = back (pins 7-10), Row 3 = front (pin 1)
    // Col is centered within each row
    static let layoutPositions: [(id: Int, row: Int, col: Int)] = [
        (7, 0, 0), (8, 0, 1), (9, 0, 2), (10, 0, 3),
        (4, 1, 0), (5, 1, 1), (6, 1, 2),
        (2, 2, 0), (3, 2, 1),
        (1, 3, 0)
    ]

    static func defaultSet() -> [Pin] {
        (1...10).map { Pin(id: $0) }
    }
}
