//
//  HomeView.swift
//  Spare Time
//
//  Created by Aidan McKenzie on 2/21/26.
//

import SwiftUI

struct HomeView: View {
    let userId: String

    @State private var userName: String
    @State private var recentMatches: [APIService.MatchResponse]
    @State private var seriesList: [APIService.SeriesResponse] = []
    @State private var activeMatchId: String = ""
    @State private var navigateToMatch = false
    @State private var ringProgress: Double = 0
    @State private var scoreRingProgress: Double = 0
    @State private var seriesRingProgress: Double = 0
    @State private var speedRingProgress: Double = 0
    @State private var hasAnimatedRing = false
    @State private var hasAnimatedRows = false
    @State private var visibleRowCount: Int = 0

    init(
        userId: String,
        initialUserName: String = "",
        initialMatches: [APIService.MatchResponse] = []
    ) {
        self.userId = userId
        _userName = State(initialValue: initialUserName)
        _recentMatches = State(initialValue: initialMatches)
    }

    private var average: Int? {
        let scores = recentMatches.compactMap { $0.total_score }
        guard !scores.isEmpty else { return nil }
        return scores.reduce(0, +) / scores.count
    }

    private var highestScore: Int {
        recentMatches.compactMap { $0.total_score }.max() ?? 0
    }

    private var highestSeries: Int {
        seriesList.map { $0.series }.max() ?? 0
    }
    private var averageBallSpeed: Int { 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                PartyBackground()
                    .ignoresSafeArea()
                    .opacity(0.3)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Greeting
                        Text("Hi, \(userName)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.primary)
                            .padding(.top, 8)

                        // Main average card
                        averageCard

                        // Stats row
                        statsRow

                        // Recent Matches
                        HStack(alignment: .center) {
                            Text("Recent Matches")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Theme.primary)

                            Spacer()

                            Button {
                                startNewMatch()
                            } label: {
                                HStack(alignment: .center, spacing: 6) {
                                    Text("Add Match")
                                        .font(.system(size: 20, weight: .semibold))
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                }
                                .foregroundStyle(Theme.neon)
                            }
                        }
                        .padding(.top, 4)

                        if recentMatches.isEmpty {
                            Text("No games yet. Start bowling!")
                                .foregroundStyle(Theme.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(recentMatches.enumerated()), id: \.element.id) { index, match in
                                    Group {
                                        if match.total_score != nil {
                                            NavigationLink {
                                                MatchView(match: match)
                                            } label: {
                                                matchRow(match)
                                            }
                                        } else {
                                            Button {
                                                activeMatchId = match.id
                                                navigateToMatch = true
                                            } label: {
                                                matchRow(match)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .opacity(visibleRowCount > index ? 1 : 0)
                                    .offset(y: visibleRowCount > index ? 0 : 16)
                                    .animation(
                                        .easeOut(duration: 0.45).delay(Double(index) * 0.1),
                                        value: visibleRowCount
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
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

    // MARK: - Average Card

    private var averageCard: some View {
        let score = average ?? 0

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    CountingText(value: ringProgress * 300)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(Theme.primary)
                    Text("/300")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.secondary)
                }
                Text("Bowling average")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.secondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Theme.secondary.opacity(0.25), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(Theme.secondary.opacity(0.7), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image("averageImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
            .frame(width: 90, height: 90)
        }
        .padding(20)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            guard !hasAnimatedRing else { return }
            hasAnimatedRing = true
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                ringProgress = Double(score) / 300.0
                scoreRingProgress = Double(highestScore) / 300.0
                seriesRingProgress = Double(highestSeries) / 900.0
                speedRingProgress = Double(averageBallSpeed) / 25.0
            }
            animateRows()
        }
        .onChange(of: average) { _, newAvg in
            withAnimation(.easeOut(duration: 0.8)) {
                ringProgress = Double(newAvg ?? 0) / 300.0
            }
        }
        .onChange(of: recentMatches) { _, _ in
            withAnimation(.easeOut(duration: 0.8)) {
                scoreRingProgress = Double(highestScore) / 300.0
            }
            animateRows()
        }
        .onChange(of: seriesList) { _, _ in
            withAnimation(.easeOut(duration: 0.8)) {
                seriesRingProgress = Double(highestSeries) / 900.0
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(
                value: highestScore,
                max: 300,
                label: "Highest score",
                imageName: "scoreImage",
                color: Theme.gold,
                progress: scoreRingProgress
            )
            statCard(
                value: highestSeries,
                max: 900,
                label: "Highest series",
                imageName: "seriesImage",
                color: Theme.neon,
                progress: seriesRingProgress
            )
            statCard(
                value: averageBallSpeed,
                max: 25,
                unit: "mph",
                label: "Average ball speed",
                imageName: "speedImage",
                color: Theme.pink,
                progress: speedRingProgress
            )
        }
    }

    private func statCard(
        value: Int,
        max: Int,
        unit: String? = nil,
        label: String,
        imageName: String,
        color: Color,
        progress: Double
    ) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(value)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Theme.primary)
                Text("/\(max)\(unit ?? "")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.5), radius: 6, x: 0, y: 0)
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
            }
            .frame(width: 65, height: 65)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Match Row

    private func matchRow(_ match: APIService.MatchResponse) -> some View {
        HStack {
            Text(formattedDate(match.date_played))
                .font(.system(size: 17))
                .foregroundStyle(Theme.primary)

            Spacer()

            if let score = match.total_score {
                Text("Score: \(score)")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.primary)
            } else {
                Text("Unfinished")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.secondary)
            }
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
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: isoString) {
            let display = DateFormatter()
            display.dateFormat = "M/dd"
            return display.string(from: date)
        }
        return isoString
    }

    private func startNewMatch() {
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
                activeMatchId = id
            } catch {
                print("[Home] Failed to create match: \(error)")
            }
        }
    }

    private func animateRows() {
        guard !hasAnimatedRows, !recentMatches.isEmpty else { return }
        hasAnimatedRows = true
        for i in 0..<recentMatches.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i) * 0.1) {
                visibleRowCount = i + 1
            }
        }
    }

    private func loadData() async {
        async let userTask: () = loadUser()
        async let matchesTask: () = loadMatches()
        async let seriesTask: () = loadSeries()
        _ = await (userTask, matchesTask, seriesTask)
    }

    private func loadUser() async {
        do {
            let user = try await APIService.fetchUser(userId: userId)
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

    private func loadSeries() async {
        do {
            seriesList = try await APIService.fetchSeries(userId: userId)
        } catch {
            print("[Home] Failed to load series: \(error)")
        }
    }
}

// MARK: - Animatable counting text

private struct CountingText: View, Animatable {
    var value: Double

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text("\(Int(value))")
    }
}

#Preview {
    HomeView(userId: "preview-user")
}
