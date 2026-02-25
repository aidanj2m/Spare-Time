//
//  Spare_TimeApp.swift
//  Spare Time
//
//  Created by Aidan McKenzie on 2/19/26.
//

import SwiftUI

@main
struct Spare_TimeApp: App {
    @State private var userId: String? = UserDefaults.standard.string(forKey: "userId")
    @State private var splashDone = false
    @State private var preloadedUserName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var preloadedMatches: [APIService.MatchResponse] = []

    var body: some Scene {
        WindowGroup {
            Group {
                if let userId {
                    if splashDone {
                        HomeView(
                            userId: userId,
                            initialUserName: preloadedUserName,
                            initialMatches: preloadedMatches
                        )
                        .transition(.opacity)
                    } else {
                        SplashView()
                            .task { await preload(userId: userId) }
                            .transition(.opacity)
                    }
                } else {
                    OnboardingView { id in
                        preloadedUserName = UserDefaults.standard.string(forKey: "userName") ?? ""
                        splashDone = true
                        userId = id
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func preload(userId: String) async {
        let start = Date()

        let userTask = Task { try? await APIService.fetchUser(userId: userId) }
        let matchesTask = Task { try? await APIService.fetchMatches(userId: userId) }

        let user = await userTask.value
        let matches = await matchesTask.value

        if let user {
            preloadedUserName = user.name ?? preloadedUserName
        }
        preloadedMatches = matches ?? []

        // Ensure minimum 1.5s splash duration
        let remaining = 1.5 - Date().timeIntervalSince(start)
        if remaining > 0 {
            try? await Task.sleep(for: .seconds(remaining))
        }

        withAnimation(.easeInOut(duration: 0.4)) {
            splashDone = true
        }
    }
}
