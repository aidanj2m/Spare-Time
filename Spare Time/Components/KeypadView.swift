import SwiftUI

struct KeypadView: View {
    let onTap: (String) -> Void

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["/", "X", "<"]
    ]

    private let keySize: CGFloat = 76
    private let spacing: CGFloat = 10

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \.self) { key in
                        KeypadButton(key: key, size: keySize, onTap: onTap)
                    }
                }
            }
        }
    }
}

private struct KeypadButton: View {
    let key: String
    let size: CGFloat
    let onTap: (String) -> Void

    @State private var isPressed = false

    var body: some View {
        Text(key)
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(Theme.primary)
            .frame(width: size, height: size)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.border, lineWidth: 1.2)
            )
            .scaleEffect(isPressed ? 0.88 : 1.0)
            .opacity(isPressed ? 0.6 : 1.0)
            .animation(.easeOut(duration: 0.08), value: isPressed)
            .onTapGesture {
                isPressed = true
                onTap(key)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
    }
}

#Preview {
    KeypadView { key in print(key) }
        .padding()
        .background(Theme.background)
}
