import Foundation

struct APIService {
    static let baseURL = "https://bowling-api-eight.vercel.app"

    // MARK: - Auth

    struct OTPResponse: Codable {
        let message: String
        let sid: String
    }

    struct AuthResponse: Codable {
        let user_id: String
        let phone_number: String
        let is_new_user: Bool
    }

    static func sendOTP(phoneNumber: String) async throws -> OTPResponse {
        guard let url = URL(string: "\(baseURL)/auth/send-otp") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["phone_number": phoneNumber])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(OTPResponse.self, from: data)
    }

    static func verifyOTP(phoneNumber: String, code: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/verify-otp") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode([
            "phone_number": phoneNumber,
            "code": code
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    static func updateUser(userId: String, name: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/user/\(userId)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["name": name])

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Matches

    struct MatchPayload: Codable {
        let user_id: String
        let date_played: String
        let total_score: Int?
        let lane: Int?
        let location: String?
        let notes: String?
    }

    struct MatchResponse: Codable, Equatable {
        let id: String
        let user_id: String
        let date_played: String
        let total_score: Int?
    }

    static func createMatch(_ payload: MatchPayload) async throws -> String {
        guard let url = URL(string: "\(baseURL)/matches/") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let match = try JSONDecoder().decode(MatchResponse.self, from: data)
        return match.id
    }

    static func updateMatch(matchId: String, totalScore: Int?, lane: Int?, location: String?, notes: String?) async throws {
        // Fetch existing match to get required user_id and date_played
        guard let getUrl = URL(string: "\(baseURL)/matches/\(matchId)") else {
            throw URLError(.badURL)
        }
        let (getData, getResponse) = try await URLSession.shared.data(from: getUrl)
        guard let getHttp = getResponse as? HTTPURLResponse, (200...299).contains(getHttp.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let existing = try JSONDecoder().decode(MatchResponse.self, from: getData)

        // PUT to /matches/ (upsert) with full payload
        guard let url = URL(string: "\(baseURL)/matches/") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        struct UpsertPayload: Codable {
            let id: String
            let user_id: String
            let date_played: String
            let total_score: Int?
            let lane: Int?
            let location: String?
            let notes: String?
        }

        request.httpBody = try JSONEncoder().encode(UpsertPayload(
            id: matchId,
            user_id: existing.user_id,
            date_played: existing.date_played,
            total_score: totalScore,
            lane: lane,
            location: location,
            notes: notes
        ))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            print("[API] updateMatch failed: HTTP \(code) — \(body)")
            throw URLError(.badServerResponse)
        }
    }

    static func deleteMatch(matchId: String) async throws {
        guard let url = URL(string: "\(baseURL)/matches/\(matchId)/") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    static func fetchMatches(userId: String) async throws -> [MatchResponse] {
        guard let url = URL(string: "\(baseURL)/matches/?user_id=\(userId)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([MatchResponse].self, from: data)
    }

    // MARK: - Frames

    struct FramePayload: Codable {
        let game_id: String
        let frame_number: Int
        let first_shot: Int?
        let second_shot: Int?
        let third_shot: Int?
        let is_strike: Bool
        let is_spare: Bool
        let pins_standing: [Int]
        let running_total: Int?
        let line_drawing: LineDrawing?
        let ball_speed: Int?
    }

    struct FrameResponse: Codable {
        let game_id: String
        let frame_number: Int
        let first_shot: Int?
        let second_shot: Int?
        let third_shot: Int?
        let is_strike: Bool
        let is_spare: Bool
        let running_total: Int?
        let ball_speed: Int?
    }

    static func upsertFrame(_ payload: FramePayload) async throws {
        guard let url = URL(string: "\(baseURL)/frames/") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    static func fetchFrames(matchId: String) async throws -> [FrameResponse] {
        guard let url = URL(string: "\(baseURL)/frames/game/\(matchId)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([FrameResponse].self, from: data)
    }

    // MARK: - Series

    struct SeriesPayload: Codable {
        let user_id: String
        let game_ids: [String]
        let series: Int
    }

    struct SeriesResponse: Codable, Equatable {
        let id: String
        let user_id: String
        let game_ids: [String]
        let series: Int
    }

    static func createSeries(_ payload: SeriesPayload) async throws -> SeriesResponse {
        guard let url = URL(string: "\(baseURL)/series/") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(SeriesResponse.self, from: data)
    }

    static func fetchSeries(userId: String) async throws -> [SeriesResponse] {
        guard let url = URL(string: "\(baseURL)/series/?user_id=\(userId)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([SeriesResponse].self, from: data)
    }

    // MARK: - User profile

    struct UserProfile: Codable {
        let id: String
        let name: String?
        let average: Int?
    }

    static func fetchUser(userId: String) async throws -> UserProfile {
        guard let url = URL(string: "\(baseURL)/auth/user/\(userId)") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(UserProfile.self, from: data)
    }
}
