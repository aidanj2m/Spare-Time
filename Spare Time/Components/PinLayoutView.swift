import SwiftUI

struct PinView: View {
    let pin: Pin

    var body: some View {
        Image(pin.isSelected ? "pinImageSelected" : "pinImage")
            .resizable()
            .scaledToFit()
            .opacity(pin.isStanding ? 1.0 : 0.15)
            .shadow(color: pin.isSelected ? Theme.neon.opacity(0.9) : .clear, radius: 10, x: 0, y: 0)
            .shadow(color: pin.isSelected ? Theme.neon.opacity(0.5) : .clear, radius: 20, x: 0, y: 0)
    }
}

struct PinLayoutView: View {
    @Binding var pins: [Pin]
    let requiredSelections: Int

    var selectedCount: Int { pins.filter { $0.isSelected }.count }

    private let rows: [[Int]] = [
        [7, 8, 9, 10],
        [4, 5, 6],
        [2, 3],
        [1]
    ]

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<rows.count, id: \.self) { rowIdx in
                HStack(spacing: 22) {
                    ForEach(rows[rowIdx], id: \.self) { id in
                        pinButton(for: id)
                    }
                }
            }
        }
        .padding(.vertical, 20)
    }

    private func pinButton(for id: Int) -> some View {
        let idx = pins.firstIndex(where: { $0.id == id })!
        let pin = pins[idx]

        return Button {
            guard pin.isStanding else { return }
            if pin.isSelected {
                pins[idx].isSelected = false
            } else if selectedCount < requiredSelections {
                pins[idx].isSelected = true
            }
        } label: {
            PinView(pin: pin)
                .frame(width: 65, height: 100)
        }
        .buttonStyle(.plain)
    }
}
