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

    var body: some Scene {
        WindowGroup {
            Group {
                if let userId {
                    HomeView(userId: userId)
                } else {
                    OnboardingView { id in
                        userId = id
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
