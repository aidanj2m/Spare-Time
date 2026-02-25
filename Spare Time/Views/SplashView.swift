import SwiftUI

struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            PartyBackground()
                .ignoresSafeArea()
                .opacity(0.3)

            Text("Spare Time")
                .font(.system(size: 40, weight: .heavy))
                .foregroundStyle(Theme.primary)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.92)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
        }
    }
}

#Preview {
    SplashView()
}
