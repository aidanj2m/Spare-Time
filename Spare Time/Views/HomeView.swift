//
//  HomeView.swift
//  Spare Time
//
//  Created by Aidan McKenzie on 2/21/26.
//

import SwiftUI

struct HomeView: View {
    let userId: String

    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? ""
    @State private var average: Int?
    @State private var recentMatches: [APIService.MatchResponse] = []
    @State private var activeMatchId: String = ""
    @State private var navigateToMatch = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        // Greeting
                        Text("Hi, \(userName)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.primary)
                            .padding(.top, 8)

                        // Average ring
                        averageRing
                            .frame(maxWidth: .infinity)

                        // Recent Matches
                        Text("Recent Matches")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Theme.primary)

                        if recentMatches.isEmpty {
                            Text("No games yet. Start bowling!")
                                .foregroundStyle(Theme.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(recentMatches, id: \.id) { match in
                                    NavigationLink {
                                        MatchView(match: match)
                                    } label: {
                                        matchRow(match)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            startNewMatch()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Theme.background)
                                .frame(width: 60, height: 60)
                                .background(Theme.neon)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 32)
                    }
                }
                .navigationDestination(isPresented: $navigateToMatch) {
                    ContentView(userId: userId, matchId: $activeMatchId)
                        .navigationBarBackButtonHidden()
                }
            }
        }
        .task {
            await loadData()
        }
        .onChange(of: navigateToMatch) { _, isNavigating in
            if !isNavigating {
                activeMatchId = ""
                Task { await loadData() }
            }
        }
    }

    // MARK: - Average Ring

    private var averageRing: some View {
        let score = average ?? 0
        let progress = Double(score) / 300.0

        return VStack(spacing: 8) {
            ZStack {
                // Background track
                Circle()
                    .stroke(Theme.neon.opacity(0.2), lineWidth: 14)
                    .frame(width: 140, height: 140)

                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.neon, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Theme.neon.opacity(0.6), radius: 12, x: 0, y: 0)

                // Score label
                Text("\(score)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Theme.primary)
            }

            Text("Your\nAverage")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Match Row

    private func matchRow(_ match: APIService.MatchResponse) -> some View {
        HStack {
            Text(formattedDate(match.date_played))
                .font(.system(size: 17))
                .foregroundStyle(Theme.primary)

            Spacer()

            Text("Score: \(match.total_score ?? 0)")
                .font(.system(size: 17))
                .foregroundStyle(Theme.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            let display = DateFormatter()
            display.dateFormat = "M/dd"
            return display.string(from: date)
        }
        // Fallback: try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: isoString) {
            let display = DateFormatter()
            display.dateFormat = "M/dd"
            return display.string(from: date)
        }
        return isoString
    }

    private func startNewMatch() {
        print("[Home] FAB tapped, creating match...")
        navigateToMatch = true
        let formatter = ISO8601DateFormatter()
        let payload = APIService.MatchPayload(
            user_id: userId,
            date_played: formatter.string(from: Date()),
            total_score: nil,
            lane: nil,
            location: nil,
            notes: nil
        )
        Task {
            do {
                let id = try await APIService.createMatch(payload)
                print("[Home] Match created: \(id)")
                activeMatchId = id
            } catch {
                print("[Home] Failed to create match: \(error)")
            }
        }
    }

    private func loadData() async {
        async let userTask: () = loadUser()
        async let matchesTask: () = loadMatches()
        _ = await (userTask, matchesTask)
    }

    private func loadUser() async {
        do {
            let user = try await APIService.fetchUser(userId: userId)
            average = user.average
            if let name = user.name {
                userName = name
            }
        } catch {
            print("[Home] Failed to load user: \(error)")
        }
    }

    private func loadMatches() async {
        do {
            recentMatches = try await APIService.fetchMatches(userId: userId)
        } catch {
            print("[Home] Failed to load matches: \(error)")
        }
    }
}

#Preview {
    HomeView(userId: "preview-user")
}
