import Foundation
import SwiftUI
import UserNotifications

// CS2 Highlight Models
struct CS2Highlight: Codable, Identifiable {
    let id: String
    let timestamp: Int
    let matchId: String
    let roundNumber: Int
    let description: String
    let videoUrl: String?
    let thumbnailUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case matchId = "match_id"
        case roundNumber = "round_number"
        case description
        case videoUrl = "video_url"
        case thumbnailUrl = "thumbnail_url"
    }
}

struct CS2HighlightsResponse: Codable {
    let success: Bool
    let highlights: [CS2Highlight]
}

// Add after the CS2Highlight models
struct PlaytimeWarning: Identifiable {
    let id = UUID()
    let gameName: String
    let recentPlaytime: Int
    let threshold: Int
    let date: Date
}

// Add new CS2 API response models
struct CS2UserStatsResponse: Codable {
    let playerstats: CS2SteamAPIResponse
}

struct CS2SteamAPIResponse: Codable {
    let steamID: String
    let gameName: String
    let stats: [CS2Stat]
    
    enum CodingKeys: String, CodingKey {
        case steamID = "steamID"
        case gameName = "gameName"
        case stats = "stats"
    }
}

struct CS2Stat: Codable {
    let name: String
    let value: Int
}

// Add after the CS2Highlight models
struct PremierMatch: Codable, Identifiable {
    let id: String
    let matchId: String
    let timestamp: Int
    let map: String
    let score: String
    let result: String
    let kills: Int
    let deaths: Int
    let assists: Int
    let headshots: Int
    let damage: Int
    let mvp: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case timestamp
        case map = "map_name"
        case score = "score"
        case result = "result"
        case kills = "kills"
        case deaths = "deaths"
        case assists = "assists"
        case headshots = "headshots"
        case damage = "damage"
        case mvp = "mvp"
    }
}

struct PremierMatchesResponse: Codable {
    let success: Bool
    let matches: [PremierMatch]
}

// Update the CS2Stats model
struct CS2Stats: Codable {
    var totalPlaytime: Int
    var recentPlaytime: Int
    var achievementCount: Int
    let totalAchievements: Int
    var lastPlayed: Int
}

// Add after the CS2Stats model
struct AchievementsResponse: Codable {
    let playerstats: SteamPlayerStats
}

struct SteamPlayerStats: Codable {
    let steamID: String
    let gameName: String
    let achievements: [Achievement]
    
    enum CodingKeys: String, CodingKey {
        case steamID = "steamID"
        case gameName = "gameName"
        case achievements
    }
}

struct Achievement: Codable {
    let apiname: String
    let achieved: Int
    let unlocktime: Int
}

// Add after the SteamError enum
struct User: Codable, Identifiable {
    let id: String
    let steamId: String
    let username: String
    let email: String
    let passwordHash: String
    let createdAt: Date
    let lastLogin: Date
    let isEmailVerified: Bool
    let verificationToken: String
    var avatarUrl: String
    var preferences: UserPreferences
    
    init(id: String = UUID().uuidString,
         steamId: String,
         username: String,
         email: String,
         passwordHash: String,
         createdAt: Date = Date(),
         lastLogin: Date = Date(),
         isEmailVerified: Bool = false,
         verificationToken: String = UUID().uuidString,
         avatarUrl: String = "",
         preferences: UserPreferences = UserPreferences()) {
        self.id = id
        self.steamId = steamId
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.createdAt = createdAt
        self.lastLogin = lastLogin
        self.isEmailVerified = isEmailVerified
        self.verificationToken = verificationToken
        self.avatarUrl = avatarUrl
        self.preferences = preferences
    }
}

struct UserPreferences: Codable {
    var notificationsEnabled: Bool
    var playtimeWarningsEnabled: Bool
    var weeklyReportEnabled: Bool
    var theme: AppTheme
    
    init(notificationsEnabled: Bool = true, 
         playtimeWarningsEnabled: Bool = true, 
         weeklyReportEnabled: Bool = true, 
         theme: AppTheme = .dark) {
        self.notificationsEnabled = notificationsEnabled
        self.playtimeWarningsEnabled = playtimeWarningsEnabled
        self.weeklyReportEnabled = weeklyReportEnabled
        self.theme = theme
    }
}

enum AppTheme: String, Codable {
    case light
    case dark
    case system
}

enum SteamError: LocalizedError {
    case invalidSteamId
    case invalidEmail
    case invalidPassword
    case profileNotFound
    case profilePrivate
    case networkError
    case apiError(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidSteamId:
            return "Invalid Steam ID format"
        case .invalidEmail:
            return "Invalid email format"
        case .invalidPassword:
            return "Password must be at least 8 characters"
        case .profileNotFound:
            return "Steam profile not found"
        case .profilePrivate:
            return "Steam profile is private"
        case .networkError:
            return "Network error occurred"
        case .apiError(let message):
            return "API Error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}

class SteamViewModel: ObservableObject {
    @Published var steamProfile: SteamProfile?
    @Published var recentGames: [Game] = []
    @Published var ownedGames: [Game] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var steamStatus: SteamStatus = .unknown
    @Published var steamId: String = ""
    @Published var profile: SteamProfile?
    @Published var playtimeWarnings: [PlaytimeWarning] = []
    @Published var hasActiveWarnings = false
    @Published var recentSearches: [String] = []
    @Published var lastSearchedId: String = ""
    @Published var cs2Stats: CS2Stats?
    @Published var isCS2StatsViewPresented = false
    @Published var premierMatches: [PremierMatch] = []
    @Published var isCS2CombinedViewPresented = false
    @Published var currentUser: User?
    @Published var isSignedIn = false
    @Published var isAuthenticated = false
    @Published var users: [User] = []
    
    private let steamAPIKey = "CDF53EA372999EA2A5226F4EEF897D18"
    private let defaults = UserDefaults.standard
    private let recentSearchesKey = "recentSearches"
    private let lastSearchedIdKey = "lastSearchedId"
    private let currentUserKey = "currentUser"
    private let usersKey = "users"
    
    // Update OpenID properties
    private let steamOpenIDURL = "https://steamcommunity.com/openid/login"
    private let returnURL = "playmate://steam-auth" // Updated URL scheme
    
    enum SteamStatus {
        case online
        case offline
        case issues
        case unknown
        
        var description: String {
            switch self {
            case .online:
                return "Steam servers are online and running smoothly 🚀✨"
            case .offline:
                return "Steam servers are currently offline ❌"
            case .issues:
                return "Steam servers are experiencing issues ⚠️"
            case .unknown:
                return "Checking Steam server status..."
            }
        }
        
        var color: Color {
            switch self {
            case .online:
                return .green
            case .offline:
                return .red
            case .issues:
                return .yellow
            case .unknown:
                return .gray
            }
        }
    }
    
    init() {
        Task {
            await checkSteamStatus()
        }
        loadSavedData()
        loadUsers()
        loadCurrentUser()
    }
    
    private func loadSavedData() {
        recentSearches = defaults.stringArray(forKey: recentSearchesKey) ?? []
        lastSearchedId = defaults.string(forKey: lastSearchedIdKey) ?? ""
    }
    
    private func saveData() {
        defaults.set(recentSearches, forKey: recentSearchesKey)
        defaults.set(lastSearchedId, forKey: lastSearchedIdKey)
    }
    
    private func addToRecentSearches(_ steamId: String) {
        // Remove if already exists to avoid duplicates
        recentSearches.removeAll { $0 == steamId }
        
        // Add to the beginning of the array
        recentSearches.insert(steamId, at: 0)
        
        // Keep only the last 5 searches
        if recentSearches.count > 5 {
            recentSearches = Array(recentSearches.prefix(5))
        }
        
        // Save to UserDefaults
        saveData()
    }
    
    private func loadCurrentUser() {
        if let userData = defaults.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isSignedIn = true
            self.steamId = user.steamId
            
            // Auto-fetch profile if user is signed in
            Task {
                await fetchProfile(username: user.steamId)
            }
        }
    }
    
    private func saveCurrentUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            defaults.set(encoded, forKey: currentUserKey)
            self.currentUser = user
            self.isSignedIn = true
        }
    }
    
    private func loadUsers() {
        if let usersData = defaults.data(forKey: usersKey),
           let decodedUsers = try? JSONDecoder().decode([User].self, from: usersData) {
            self.users = decodedUsers
        }
    }
    
    private func saveUsers() {
        if let encoded = try? JSONEncoder().encode(users) {
            defaults.set(encoded, forKey: usersKey)
        }
    }
    
    // Add password hashing function
    private func hashPassword(_ password: String) -> String {
        // In a real app, use a proper hashing algorithm like bcrypt
        // This is a simplified version for demonstration
        return password.data(using: .utf8)?.base64EncodedString() ?? ""
    }
    
    // Update signUp function
    func signUp(username: String, email: String, steamId: String, password: String) async throws {
        print("Starting sign up process")
        
        // Validate inputs
        guard isValidEmail(email) else {
            throw SteamError.invalidEmail
        }
        
        guard password.count >= 8 else {
            throw SteamError.invalidPassword
        }
        
        // Check if username is already taken
        if users.contains(where: { $0.username == username }) {
            throw SteamError.apiError("Username already taken")
        }
        
        // Check if email is already registered
        if users.contains(where: { $0.email == email }) {
            throw SteamError.apiError("Email already registered")
        }
        
        // Create PlayMate account first
        let playMateUser = User(
            id: UUID().uuidString,
            steamId: "", // Will be updated after Steam verification
            username: username,
            email: email,
            passwordHash: hashPassword(password),
            createdAt: Date(),
            lastLogin: Date(),
            isEmailVerified: false,
            verificationToken: UUID().uuidString,
            avatarUrl: "",
            preferences: UserPreferences()
        )
        
        // Add user to users array
        users.append(playMateUser)
        saveUsers()
        
        // Verify Steam ID and fetch profile
        do {
            let profile = try await fetchProfile(username: steamId)
            print("Steam profile fetched successfully")
            
            // Update user with Steam ID
            let updatedUser = User(
                id: playMateUser.id,
                steamId: steamId,
                username: playMateUser.username,
                email: playMateUser.email,
                passwordHash: playMateUser.passwordHash,
                createdAt: playMateUser.createdAt,
                lastLogin: playMateUser.lastLogin,
                isEmailVerified: playMateUser.isEmailVerified,
                verificationToken: playMateUser.verificationToken,
                avatarUrl: playMateUser.avatarUrl,
                preferences: playMateUser.preferences
            )
            
            // Update user in users array
            if let index = users.firstIndex(where: { $0.id == playMateUser.id }) {
                users[index] = updatedUser
                saveUsers()
            }
            
            // Save as current user
            await MainActor.run {
                self.currentUser = updatedUser
                self.isSignedIn = true
            }
            saveCurrentUser(updatedUser)
            
            // Send verification email
            try await sendVerificationEmail(to: email, token: updatedUser.verificationToken)
            print("Verification email sent")
            
        } catch {
            print("Error during sign up: \(error)")
            // Remove the user if Steam verification fails
            users.removeAll { $0.id == playMateUser.id }
            saveUsers()
            throw error
        }
    }
    
    private func sendVerificationEmail(to email: String, token: String) async throws {
        // Simulate sending verification email
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        print("Verification email would be sent to \(email) with token \(token)")
    }
    
    func sendPasswordResetEmail(to email: String) async -> Bool {
        // Check if email exists in our system
        guard let user = currentUser, user.email == email else {
            return false
        }
        
        // Generate a reset token
        let resetToken = UUID().uuidString
        
        // In a real app, this would use a proper email service
        let resetLink = "https://playmate.app/reset-password?token=\(resetToken)"
        print("Password reset email sent to \(email) with link: \(resetLink)")
        
        // Simulate email sending delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        return true
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async {
        guard let user = currentUser else { return }
        
        let updatedUser = User(
            id: user.id,
            steamId: user.steamId,
            username: user.username,
            email: user.email,
            passwordHash: user.passwordHash,
            createdAt: user.createdAt,
            lastLogin: user.lastLogin,
            isEmailVerified: user.isEmailVerified,
            verificationToken: user.verificationToken,
            avatarUrl: user.avatarUrl,
            preferences: preferences
        )
        
        await MainActor.run {
            saveCurrentUser(updatedUser)
        }
    }
    
    @MainActor
    func checkSteamStatus() async {
        do {
            let url = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=\(steamAPIKey)&steamids=76561197960435530"
            guard let requestURL = URL(string: url) else {
                steamStatus = .unknown
                return
            }
            
            let (_, response) = try await URLSession.shared.data(from: requestURL)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                steamStatus = .unknown
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                steamStatus = .online
            case 403:
                steamStatus = .issues
            default:
            
                steamStatus = .offline
            }
        } catch {
            steamStatus = .issues
        }
    }
    
    func fetchProfile(username: String) async {
        print("fetchProfile called with username: \(username)")
        guard !username.isEmpty else {
            print("Username is empty")
            await MainActor.run {
                self.error = "Please enter a Steam ID"
                self.isLoading = false
            }
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            var steamID = username
            print("Original steamID: \(steamID)")
            
            // Handle different Steam ID formats
            if username.contains("/") {
                // Extract Steam ID from profile URL
                if let id = username.split(separator: "/").last {
                    steamID = String(id)
                    print("Extracted Steam ID from URL: \(steamID)")
                }
            } else if username.contains("STEAM_") {
                // Convert STEAM_X:Y:Z format to Steam64 ID
                let components = username.split(separator: ":")
                if components.count == 3,
                   let x = Int(components[1]),
                   let z = Int(components[2]) {
                    let steam64 = Int64(z) * 2 + Int64(x) + 76561197960265728
                    steamID = String(steam64)
                    print("Converted STEAM_X:Y:Z format to Steam64 ID: \(steamID)")
                }
            }
            
            self.lastSearchedId = steamID
            saveData()
            
            // Print the URL we're calling for debugging
            let profileURL = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=\(steamAPIKey)&steamids=\(steamID)"
            print("Calling Steam API URL: \(profileURL)")
            
            guard let url = URL(string: profileURL) else {
                print("Invalid URL")
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 10 // Reduce timeout to 10 seconds
            
            print("Sending request to Steam API")
            
            // Use a task with timeout to prevent getting stuck
            let task = Task {
                let (data, response) = try await URLSession.shared.data(from: url)
                return (data, response)
            }
            
            // Set a timeout of 15 seconds
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 15 * 1_000_000_000)
                return nil as (Data, URLResponse)?
            }
            
            // Wait for either the data or the timeout
            let result: (Data, URLResponse)? = await withTaskGroup(of: (Data, URLResponse)?.self) { group in
                group.addTask { try? await task.value }
                group.addTask { try? await timeoutTask.value }
                
                for await value in group {
                    if let value = value {
                        return value
                    }
                }
                return nil
            }
            
            // If we timed out, use sample data
            guard let (data, response) = result else {
                print("Request timed out, using sample data")
                await useSampleData(steamID: steamID)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                throw URLError(.badServerResponse)
            }
            
            print("Profile API Response Status Code: \(httpResponse.statusCode)")
            
            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Profile API Raw Response: \(responseString)")
            }
            
            // Handle API key issues
            if httpResponse.statusCode == 403 {
                print("API key invalid or rate limited")
                await MainActor.run {
                    self.error = "Steam API key is invalid or rate limited. Using sample data instead."
                    self.isLoading = false
                }
                await useSampleData(steamID: steamID)
                return
            }
            
            // Check for empty response
            if data.isEmpty {
                print("Empty response from Steam API")
                await MainActor.run {
                    self.error = "Empty response from Steam API. Using sample data instead."
                    self.isLoading = false
                }
                await useSampleData(steamID: steamID)
                return
            }
            
            let decoder = JSONDecoder()
            let profileResponse = try decoder.decode(SteamProfileResponse.self, from: data)
            
            guard let profile = profileResponse.response.players.first else {
                print("No player found in response")
                await MainActor.run {
                    self.error = "No player found with the provided Steam ID. Using sample data instead."
                    self.isLoading = false
                }
                await useSampleData(steamID: steamID)
                return
            }
            
            // Update the user's avatar URL if we have a current user
            if let currentUser = currentUser {
                var updatedUser = currentUser
                updatedUser.avatarUrl = profile.avatarfull
                saveCurrentUser(updatedUser)
            }
            
            await MainActor.run {
                self.steamProfile = profile
                self.addToRecentSearches(steamID)
                self.isLoading = false
            }
            
            // Fetch recent games
            print("Fetching recent games")
            await fetchRecentGames(steamId: steamID)
        } catch let steamError as SteamError {
            print("Steam error: \(steamError.localizedDescription)")
            await MainActor.run {
                self.error = steamError.localizedDescription
                self.isLoading = false
            }
            // Use sample data as fallback
            await useSampleData(steamID: username)
        } catch {
            print("Error fetching profile: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "Failed to fetch Steam profile. Using sample data instead."
                self.isLoading = false
            }
            // Use sample data as fallback
            await useSampleData(steamID: username)
        }
    }
    
    // Add a method to use sample data when the API is unavailable
    private func useSampleData(steamID: String) async {
        print("Using sample data for Steam ID: \(steamID)")
        
        // Create a sample profile
        let sampleProfile = SteamProfile(
            steamid: steamID,
            personaname: "Sample User",
            profileurl: "https://steamcommunity.com/profiles/\(steamID)",
            avatar: "https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fe/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg",
            avatarmedium: "https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fe/fef49e7fa7ea1997310d705b2a6158ff8dc1cdfeb_medium.jpg",
            avatarfull: "https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fe/fef49e7fa7ea1997310d705b2a6158ff8dc1cdfeb_full.jpg",
            personastate: 1,
            communityvisibilitystate: 3,
            profilestate: 1,
            lastlogoff: Int(Date().timeIntervalSince1970),
            commentpermission: 1,
            realname: "Sample User",
            primaryclanid: "103582791429521408",
            timecreated: Int(Date().timeIntervalSince1970) - 31536000,
            gameid: "730",
            gameserverip: nil,
            gameextrainfo: "Counter-Strike 2",
            loccountrycode: "US",
            locstatecode: "CA",
            loccityid: 1
        )
        
        await MainActor.run {
            self.steamProfile = sampleProfile
            self.addToRecentSearches(steamID)
        }
        
        // Create sample games
        let sampleGames = [
            Game(
                appid: 730,
                name: "Counter-Strike 2",
                playtime_2weeks: nil,
                playtime_forever: 3600,
                img_icon_url: "69f7ebe2735c366c65c0b33dae00e12dc40edbe4",
                img_logo_url: "d4f8368392541f386f2b9c016a0dc01d7f3b5f29",
                last_played: nil
            )
        ]
        
        await MainActor.run {
            self.recentGames = sampleGames
            self.ownedGames = sampleGames
        }
        
        // Create sample CS2 stats
        let sampleStats = CS2Stats(
            totalPlaytime: 3600,
            recentPlaytime: 1200,
            achievementCount: 25,
            totalAchievements: 100,
            lastPlayed: Int(Date().timeIntervalSince1970)
        )
        
        await MainActor.run {
            self.cs2Stats = sampleStats
        }
        
        // Create a sample user
        let sampleUser = User(
            id: UUID().uuidString,
            steamId: steamID,
            username: "Sample User",
            email: "sample@example.com",
            passwordHash: "",
            createdAt: Date(),
            lastLogin: Date(),
            isEmailVerified: true,
            verificationToken: "",
            avatarUrl: sampleProfile.avatarfull,
            preferences: UserPreferences()
        )
        
        // Add to users array if not already there
        if !users.contains(where: { $0.steamId == steamID }) {
            users.append(sampleUser)
            saveUsers()
        }
        
        // Set as current user
        await MainActor.run {
            self.currentUser = sampleUser
            self.isSignedIn = true
            self.isAuthenticated = true
            self.error = nil
            self.isLoading = false
        }
        
        saveCurrentUser(sampleUser)
    }
    
    // MARK: - Game Fetching
    func fetchRecentGames(steamId: String) async {
        print("Fetching recent games for Steam ID: \(steamId)")
        
        // Create a task with timeout
        let task = Task {
            do {
                // First, get recently played games
                let recentGamesURL = "https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/?key=\(steamAPIKey)&steamid=\(steamId)&count=5"
                print("Calling Recent Games API URL: \(recentGamesURL)")
                
                guard let url = URL(string: recentGamesURL) else {
                    throw URLError(.badURL)
                }
                
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                print("Recent Games API Response Status Code: \(httpResponse.statusCode)")
                
                // Print raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Recent Games API Response: \(responseString)")
                }
                
                if httpResponse.statusCode == 403 {
                    throw NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "Invalid Steam API key or rate limited"])
                }
                
                let recentGamesResponse = try JSONDecoder().decode(RecentGamesResponse.self, from: data)
                var games = recentGamesResponse.response.games
                
                // If we have less than 5 recent games, fetch owned games to fill the rest
                if games.count < 5 {
                    let ownedGamesURL = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=\(steamAPIKey)&steamid=\(steamId)&include_appinfo=1&include_played_free_games=1"
                    print("Calling Owned Games API URL: \(ownedGamesURL)")
                    
                    guard let ownedURL = URL(string: ownedGamesURL) else {
                        throw URLError(.badURL)
                    }
                    
                    let (ownedData, ownedResponse) = try await URLSession.shared.data(from: ownedURL)
                    
                    guard let ownedHttpResponse = ownedResponse as? HTTPURLResponse else {
                        throw URLError(.badServerResponse)
                    }
                    
                    print("Owned Games API Response Status Code: \(ownedHttpResponse.statusCode)")
                    
                    // Print raw response for debugging
                    if let ownedResponseString = String(data: ownedData, encoding: .utf8) {
                        print("Owned Games API Response: \(ownedResponseString)")
                    }
                    
                    if ownedHttpResponse.statusCode == 403 {
                        throw NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "Invalid Steam API key or rate limited"])
                    }
                    
                    let ownedGamesResponse = try JSONDecoder().decode(OwnedGamesResponse.self, from: ownedData)
                    
                    // Filter out games that are already in recent games and sort by playtime
                    let additionalGames = ownedGamesResponse.response.games
                        .filter { owned in !games.contains(where: { $0.appid == owned.appid }) }
                        .sorted(by: { $0.playtime_forever > $1.playtime_forever })
                        .map { $0.toGame() }
                    
                    // Add the most played games until we have 5 total
                    let remainingCount = 5 - games.count
                    games.append(contentsOf: additionalGames.prefix(remainingCount))
                }
                
                await MainActor.run {
                    self.recentGames = games
                    if games.isEmpty {
                        self.error = "No games found"
                    }
                    self.checkPlaytimeWarnings()
                }
                
                return true
            } catch {
                print("Error fetching games: \(error.localizedDescription)")
                await MainActor.run {
                    self.error = "Error fetching games: \(error.localizedDescription)"
                }
                return false
            }
        }
        
        // Create a timeout task
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 15 * 1_000_000_000) // 15 seconds timeout
            return false
        }
        
        // Wait for either the task to complete or the timeout
        let result = await withTaskGroup(of: Bool.self) { group in
            group.addTask { 
                if let value = try? await task.value {
                    return value
                }
                return false
            }
            group.addTask { 
                if let value = try? await timeoutTask.value {
                    return value
                }
                return false
            }
            
            for await value in group {
                return value
            }
            return false
        }
        
        // If we timed out or the task failed, use sample data
        if !result {
            print("Games fetch timed out or failed, using sample data")
            await MainActor.run {
                self.recentGames = [
                    Game(
                        appid: 730,
                        name: "Counter-Strike 2",
                        playtime_2weeks: 1200,
                        playtime_forever: 3600,
                        img_icon_url: "69f7ebe2735c366c65c0b33dae00e12dc40edbe4",
                        img_logo_url: "d4f8368392541f386f2b9c016a0dc01d7f3b5f29",
                        last_played: Int(Date().timeIntervalSince1970)
                    )
                ]
                self.ownedGames = self.recentGames
            }
        }
    }
    
    private func checkPlaytimeWarnings() {
        let now = Date()
        
        // Check each game's recent playtime
        for game in recentGames {
            // Get recent playtime (last 7 days)
            let recentPlaytime = game.playtime_2weeks ?? 0
            
            // Check if playtime exceeds threshold (15 hours = 900 minutes)
            if recentPlaytime > 900 {
                let warning = PlaytimeWarning(
                    gameName: game.name,
                    recentPlaytime: recentPlaytime,
                    threshold: 900,
                    date: now
                )
                
                // Only add if we don't already have a warning for this game
                if !playtimeWarnings.contains(where: { $0.gameName == game.name }) {
                    playtimeWarnings.append(warning)
                    hasActiveWarnings = true
                    sendPlaytimeWarning(for: warning)
                }
            }
        }
    }
    
    private func sendPlaytimeWarning(for warning: PlaytimeWarning) {
        let content = UNMutableNotificationContent()
        content.title = "High Playtime Warning"
        content.body = "You've played \(warning.gameName) for over 15 hours in the past week. Consider taking a break!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: warning.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Add notification permission request
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    // Add method to clear recent searches
    func clearRecentSearches() {
        recentSearches.removeAll()
        saveData()
    }
    
    // Update the fetchCS2Stats function
    func fetchCS2Stats(steamId: String) async {
        print("Fetching CS2 stats for Steam ID: \(steamId)")
        
        // First, get player achievements
        let achievementsURL = "https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v1/?appid=730&key=\(steamAPIKey)&steamid=\(steamId)"
        
        // Use a more accurate endpoint for CS2 stats
        let statsURL = "https://api.steampowered.com/ISteamUserStats/GetUserStatsForGame/v2/?appid=730&key=\(steamAPIKey)&steamid=\(steamId)"
        
        // Also get playtime stats as a fallback
        let playtimeURL = "https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v1/?key=\(steamAPIKey)&steamid=\(steamId)"
        
        do {
            // Fetch achievements
            guard let achievementsURLObj = URL(string: achievementsURL) else {
                print("Error: Invalid achievements URL")
                return
            }
            
            let (achievementsData, achievementsResponse) = try await URLSession.shared.data(from: achievementsURLObj)
            
            guard let achievementsHttpResponse = achievementsResponse as? HTTPURLResponse else {
                print("Error: Invalid achievements response type")
                return
            }
            
            print("Achievements API Response Status: \(achievementsHttpResponse.statusCode)")
            
            if let responseString = String(data: achievementsData, encoding: .utf8) {
                print("Achievements response body: \(responseString)")
            }
            
            // Fetch detailed stats
            guard let statsURLObj = URL(string: statsURL) else {
                print("Error: Invalid stats URL")
                return
            }
            
            let (statsData, statsResponse) = try await URLSession.shared.data(from: statsURLObj)
            
            guard let statsHttpResponse = statsResponse as? HTTPURLResponse else {
                print("Error: Invalid stats response type")
                return
            }
            
            print("Stats API Response Status: \(statsHttpResponse.statusCode)")
            
            if let responseString = String(data: statsData, encoding: .utf8) {
                print("Stats response body: \(responseString)")
            }
            
            // Fetch playtime as fallback
            guard let playtimeURLObj = URL(string: playtimeURL) else {
                print("Error: Invalid playtime URL")
                return
            }
            
            let (playtimeData, playtimeResponse) = try await URLSession.shared.data(from: playtimeURLObj)
            
            guard let playtimeHttpResponse = playtimeResponse as? HTTPURLResponse else {
                print("Error: Invalid playtime response type")
                return
            }
            
            print("Playtime API Response Status: \(playtimeHttpResponse.statusCode)")
            
            if let responseString = String(data: playtimeData, encoding: .utf8) {
                print("Playtime response body: \(responseString)")
            }
            
            // Process the responses
            let totalAchievements = 100 // CS2 has 100 achievements
            var stats = CS2Stats(
                totalPlaytime: 0,
                recentPlaytime: 0,
                achievementCount: 0,
                totalAchievements: totalAchievements,
                lastPlayed: 0
            )
            
            // Process achievements
            if achievementsHttpResponse.statusCode == 200 {
                do {
                    let achievementsResponse = try JSONDecoder().decode(AchievementsResponse.self, from: achievementsData)
                    stats.achievementCount = achievementsResponse.playerstats.achievements.filter { $0.achieved == 1 }.count
                } catch {
                    print("Error decoding achievements: \(error)")
                }
            }
            
            // Process detailed stats
            if statsHttpResponse.statusCode == 200 {
                do {
                    // Try to parse the stats response
                    if let json = try JSONSerialization.jsonObject(with: statsData) as? [String: Any],
                       let playerstats = json["playerstats"] as? [String: Any],
                       let statsArray = playerstats["stats"] as? [[String: Any]] {
                        
                        // Look for specific stats
                        for stat in statsArray {
                            if let name = stat["name"] as? String, let value = stat["value"] as? Int {
                                if name == "total_time_played" {
                                    stats.totalPlaytime = value
                                } else if name == "time_played_2weeks" {
                                    stats.recentPlaytime = value
                                } else if name == "last_played" {
                                    stats.lastPlayed = value
                                }
                            }
                        }
                    }
                } catch {
                    print("Error processing stats: \(error)")
                }
            }
            
            // Use playtime data as fallback if detailed stats didn't provide values
            if stats.totalPlaytime == 0 || stats.recentPlaytime == 0 || stats.lastPlayed == 0 {
                if playtimeHttpResponse.statusCode == 200 {
                    do {
                        let playtimeResponse = try JSONDecoder().decode(RecentGamesResponse.self, from: playtimeData)
                        let cs2Games = playtimeResponse.response.games.filter { $0.appid == 730 }
                        if let cs2Game = cs2Games.first {
                            if stats.totalPlaytime == 0 {
                                stats.totalPlaytime = cs2Game.playtime_forever
                            }
                            if stats.recentPlaytime == 0 {
                                stats.recentPlaytime = cs2Game.playtime_2weeks ?? 0
                            }
                            if stats.lastPlayed == 0 {
                                stats.lastPlayed = cs2Game.last_played ?? 0
                            }
                        }
                    } catch {
                        print("Error processing playtime: \(error)")
                    }
                }
            }
            
            // Update the UI with the combined data
            await MainActor.run {
                self.cs2Stats = stats
            }
            
        } catch {
            print("Error fetching CS2 stats: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "Error fetching CS2 stats: \(error.localizedDescription)"
            }
        }
    }
    
    // Update the fetchPremierMatches function to fetch all CS2 matches
    func fetchPremierMatches(steamId: String) async {
        // Use the general CS2 match history endpoint instead of Premier-specific one
        let urlString = "https://api.steampowered.com/ICSGOServers_730/GetMatchHistory/v1/?key=\(steamAPIKey)&steamid=\(steamId)&limit=8"
        
        print("Fetching CS2 matches from URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            await showSampleMatches()
            return
        }
        
        do {
            print("Fetching CS2 matches for Steam ID: \(steamId)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid response type")
                await showSampleMatches()
                return
            }
            
            print("CS2 Matches API Response Status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            
            if httpResponse.statusCode == 200 {
                do {
                    let matchesResponse = try JSONDecoder().decode(PremierMatchesResponse.self, from: data)
                    print("Successfully decoded CS2 matches response")
                    print("Number of matches: \(matchesResponse.matches.count)")
                    
                    // Log each match's details
                    for match in matchesResponse.matches {
                        print("Match found:")
                        print("- Map: \(match.map)")
                        print("- Score: \(match.score)")
                        print("- Result: \(match.result)")
                        print("- K/D/A: \(match.kills)/\(match.deaths)/\(match.assists)")
                        print("- Headshots: \(match.headshots)")
                        print("- Damage: \(match.damage)")
                        print("- MVP: \(match.mvp)")
                        print("- Date: \(Date(timeIntervalSince1970: TimeInterval(match.timestamp)))")
                        print("---")
                    }
                    
                    await MainActor.run {
                        self.premierMatches = matchesResponse.matches
                        self.isCS2CombinedViewPresented = true
                    }
                } catch {
                    print("Error decoding CS2 matches: \(error)")
                    print("Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
                    await showSampleMatches()
                }
            } else {
                print("Error: API returned status code \(httpResponse.statusCode)")
                await showSampleMatches()
            }
        } catch {
            print("Error fetching CS2 matches: \(error)")
            await showSampleMatches()
        }
    }
    
    @MainActor
    private func showSampleMatches() {
        self.premierMatches = [
            PremierMatch(
                id: "1",
                matchId: "sample1",
                timestamp: Int(Date().timeIntervalSince1970),
                map: "Nuke",
                score: "16-14",
                result: "Victory",
                kills: 25,
                deaths: 18,
                assists: 5,
                headshots: 12,
                damage: 3200,
                mvp: true
            ),
            PremierMatch(
                id: "2",
                matchId: "sample2",
                timestamp: Int(Date().timeIntervalSince1970) - 3600,
                map: "Inferno",
                score: "13-16",
                result: "Defeat",
                kills: 20,
                deaths: 22,
                assists: 3,
                headshots: 8,
                damage: 2800,
                mvp: false
            )
        ]
        self.isCS2CombinedViewPresented = true
    }
    
    // Update signOut function
    func signOut() {
        isLoading = true
        
        // Clear all user data and state
        currentUser = nil
        isSignedIn = false
        isAuthenticated = false
        steamProfile = nil
        recentGames = []
        cs2Stats = nil
        premierMatches = []
        error = nil
        steamId = "" // Reset the Steam ID
        
        // Clear current user from UserDefaults but keep the users array
        UserDefaults.standard.removeObject(forKey: currentUserKey)
        
        // Reset loading state
        isLoading = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // Add login method
    func login(username: String, password: String) async -> Bool {
        let hashedPassword = hashPassword(password)
        
        if let user = users.first(where: { $0.username == username && $0.passwordHash == hashedPassword }) {
            await MainActor.run {
                self.currentUser = user
                self.isSignedIn = true
                saveCurrentUser(user)
            }
            return true
        }
        return false
    }
    
    // Add continueWithSteam method
    func continueWithSteam(steamId: String) async throws {
        print("Starting Steam authentication")
        
        // Validate Steam ID
        guard !steamId.isEmpty else {
            throw SteamError.invalidSteamId
        }
        
        // Check if user already exists with this Steam ID
        if let existingUser = users.first(where: { $0.steamId == steamId }) {
            // User exists, sign them in
            await MainActor.run {
                self.currentUser = existingUser
                self.isSignedIn = true
                self.error = nil
            }
            saveCurrentUser(existingUser)
            
            // Fetch recent games for existing user
            await fetchRecentGames(steamId: steamId)
            return
        }
        
        // Fetch Steam profile to verify the ID
        do {
            try await fetchProfile(username: steamId)
            print("Steam profile fetched successfully")
            
            // Get the profile that was just fetched
            guard let profile = steamProfile else {
                throw SteamError.profileNotFound
            }
            
            // Create a new user with just the Steam ID
            let newUser = User(
                id: UUID().uuidString,
                steamId: steamId,
                username: profile.personaname,
                email: "", // Will be filled later if user wants to add email
                passwordHash: "", // No password needed for Steam auth
                createdAt: Date(),
                lastLogin: Date(),
                isEmailVerified: true, // Steam already verified this user
                verificationToken: "",
                avatarUrl: profile.avatarfull,
                preferences: UserPreferences()
            )
            
            // Add user to users array
            users.append(newUser)
            saveUsers()
            
            // Save as current user
            await MainActor.run {
                self.currentUser = newUser
                self.isSignedIn = true
                self.error = nil
            }
            saveCurrentUser(newUser)
            
            // Automatically fetch recent games
            await fetchRecentGames(steamId: steamId)
            
            // Also fetch CS2 stats if available
            await fetchCS2Stats(steamId: steamId)
            
        } catch {
            print("Error during Steam authentication: \(error)")
            throw error
        }
    }
    
    // Update authenticateWithSteam method
    func authenticateWithSteam() async throws {
        print("Starting Steam authentication")
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        // Use the last searched Steam ID if available
        let steamId = self.lastSearchedId.isEmpty ? "76561197960435530" : self.lastSearchedId
        
        // Create a task with a global timeout for the entire authentication process
        let authTask = Task {
            do {
                // Fetch Steam profile
                try await fetchProfile(username: steamId)
                
                guard let profile = steamProfile else {
                    print("Profile not found after fetch")
                    return false
                }
                
                // Check if user exists
                if let existingUser = users.first(where: { $0.steamId == steamId }) {
                    // User exists, sign them in
                    await MainActor.run {
                        self.currentUser = existingUser
                        self.isSignedIn = true
                        self.isAuthenticated = true
                        self.error = nil
                    }
                    saveCurrentUser(existingUser)
                    
                    // Fetch recent games
                    await fetchRecentGames(steamId: steamId)
                    return true
                }
                
                // Create new user
                let newUser = User(
                    id: UUID().uuidString,
                    steamId: steamId,
                    username: profile.personaname,
                    email: "", // Will be filled later if user wants to add email
                    passwordHash: "", // No password needed for Steam auth
                    createdAt: Date(),
                    lastLogin: Date(),
                    isEmailVerified: true, // Steam already verified this user
                    verificationToken: "",
                    avatarUrl: profile.avatarfull,
                    preferences: UserPreferences()
                )
                
                // Save user to users array
                users.append(newUser)
                saveUsers()
                
                // Set as current user
                await MainActor.run {
                    self.currentUser = newUser
                    self.isSignedIn = true
                    self.isAuthenticated = true
                    self.error = nil
                }
                saveCurrentUser(newUser)
                
                // Fetch games and stats
                await fetchRecentGames(steamId: steamId)
                await fetchCS2Stats(steamId: steamId)
                
                return true
            } catch {
                print("Error during Steam authentication: \(error)")
                return false
            }
        }
        
        // Create a timeout task
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 30 * 1_000_000_000) // 30 seconds timeout
            return false
        }
        
        // Wait for either the authentication to complete or the timeout
        let result = await withTaskGroup(of: Bool.self) { group in
            group.addTask { 
                if let value = try? await authTask.value {
                    return value
                }
                return false
            }
            group.addTask { 
                if let value = try? await timeoutTask.value {
                    return value
                }
                return false
            }
            
            for await value in group {
                return value
            }
            return false
        }
        
        // Handle the result
        if !result {
            print("Authentication failed or timed out, using sample data")
            await MainActor.run {
                self.error = "Failed to connect to Steam. Using sample data instead."
            }
            await useSampleData(steamID: steamId)
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
}

// MARK: - Models
struct SteamProfile: Codable {
    let steamid: String
    let personaname: String
    let profileurl: String
    let avatar: String
    let avatarmedium: String
    let avatarfull: String
    let personastate: Int
    let communityvisibilitystate: Int
    let profilestate: Int
    let lastlogoff: Int
    let commentpermission: Int?
    let realname: String?
    let primaryclanid: String?
    let timecreated: Int?
    let gameid: String?
    let gameserverip: String?
    let gameextrainfo: String?
    let loccountrycode: String?
    let locstatecode: String?
    let loccityid: Int?
}

struct SteamProfileResponse: Codable {
    let response: SteamProfileResponseData
}

struct SteamProfileResponseData: Codable {
    let players: [SteamProfile]
}

// Update the Game model
struct Game: Codable, Identifiable, Equatable {
    let appid: Int
    let name: String
    let playtime_2weeks: Int?
    let playtime_forever: Int
    let img_icon_url: String
    let img_logo_url: String?
    let last_played: Int?
    
    var id: Int { appid }
    
    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.appid == rhs.appid
    }
}

struct RecentGamesResponse: Codable {
    let response: RecentGamesResponseData
}

struct RecentGamesResponseData: Codable {
    let total_count: Int
    let games: [Game]
}

// New models for owned games
struct OwnedGamesResponse: Codable {
    let response: OwnedGamesResponseData
}

struct OwnedGamesResponseData: Codable {
    let game_count: Int
    let games: [OwnedGame]
}

struct OwnedGame: Codable {
    let appid: Int
    let name: String?
    let playtime_forever: Int
    let img_icon_url: String?
    
    // Convert to Game model
    func toGame() -> Game {
        return Game(
            appid: appid,
            name: name ?? "Unknown Game",
            playtime_2weeks: nil,
            playtime_forever: playtime_forever,
            img_icon_url: img_icon_url ?? "",
            img_logo_url: nil,
            last_played: nil
        )
    }
} 
