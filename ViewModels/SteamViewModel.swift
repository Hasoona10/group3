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
    let playerstats: CS2PlayerStats
}

struct CS2PlayerStats: Codable {
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
    let totalPlaytime: Int
    let recentPlaytime: Int
    let achievementCount: Int
    let totalAchievements: Int
    let lastPlayed: Int
}

// Add after the CS2Stats model
struct AchievementsResponse: Codable {
    let playerstats: PlayerStats
}

struct PlayerStats: Codable {
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

class SteamViewModel: ObservableObject {
    @Published var steamProfile: SteamProfile?
    @Published var recentGames: [Game] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var steamStatus: SteamStatus = .unknown
    @Published var steamId: String = ""
    @Published var profile: SteamProfile?
    @Published var cs2Highlights: [CS2Highlight] = []
    @Published var selectedHighlight: CS2Highlight?
    @Published var isHighlightViewPresented = false
    @Published var playtimeWarnings: [PlaytimeWarning] = []
    @Published var hasActiveWarnings = false
    @Published var recentSearches: [String] = []
    @Published var lastSearchedId: String = ""
    @Published var cs2Stats: CS2Stats?
    @Published var isCS2StatsViewPresented = false
    @Published var premierMatches: [PremierMatch] = []
    @Published var isPremierMatchesViewPresented = false
    
    private let steamAPIKey = "CDF53EA372999EA2A5226F4EEF897D18"
    private let defaults = UserDefaults.standard
    private let recentSearchesKey = "recentSearches"
    private let lastSearchedIdKey = "lastSearchedId"
    
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
        if !recentSearches.contains(steamId) {
            recentSearches.insert(steamId, at: 0)
            if recentSearches.count > 5 {
                recentSearches.removeLast()
            }
            saveData()
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
        guard !username.isEmpty else {
            await MainActor.run {
                self.error = "Please enter a Steam ID"
                self.isLoading = false
            }
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let steamID = username
            self.lastSearchedId = steamID
            saveData()
            
            // Validate Steam ID format
            guard steamID.allSatisfy({ $0.isNumber }) else {
                throw SteamError.invalidSteamId
            }
            
            // Print the URL we're calling for debugging
            let profileURL = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=\(steamAPIKey)&steamids=\(steamID)"
            print("Calling Steam API URL: \(profileURL)")
            
            guard let url = URL(string: profileURL) else {
                throw URLError(.badURL)
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            print("Profile API Response Status Code: \(httpResponse.statusCode)")
            
            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("Profile API Raw Response: \(responseString)")
            }
            
            if httpResponse.statusCode == 403 {
                throw NSError(domain: "", code: 403, userInfo: [NSLocalizedDescriptionKey: "Invalid Steam API key or rate limited"])
            }
            
            let decodedResponse = try JSONDecoder().decode(SteamProfileResponse.self, from: data)
            
            if let profile = decodedResponse.response.players.first {
                print("Successfully decoded profile for: \(profile.personaname)")
                await MainActor.run {
                    self.steamProfile = profile
                    self.addToRecentSearches(steamID)
                }
                
                // Fetch recent games
                await fetchRecentGames(steamID: steamID)
            } else {
                throw SteamError.profileNotFound
            }
        } catch let steamError as SteamError {
            await MainActor.run {
                self.error = steamError.localizedDescription
                self.isLoading = false
            }
        } catch {
            print("Error fetching profile: \(error.localizedDescription)")
            await MainActor.run {
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        self.error = "No internet connection"
                    case .timedOut:
                        self.error = "Request timed out"
                    case .badServerResponse:
                        self.error = "Server error. Please try again later"
                    default:
                        self.error = "Network error: \(urlError.localizedDescription)"
                    }
                } else {
                    self.error = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
    
    private func fetchRecentGames(steamID: String) async {
        do {
            // First, get recently played games
            let recentGamesURL = "https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/?key=\(steamAPIKey)&steamid=\(steamID)&count=5"
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
                let ownedGamesURL = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=\(steamAPIKey)&steamid=\(steamID)&include_appinfo=1&include_played_free_games=1"
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
        } catch {
            print("Error fetching games: \(error.localizedDescription)")
            await MainActor.run {
                self.error = "Error fetching games: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchCS2Highlights(steamId: String) async {
        guard let apiKey = ProcessInfo.processInfo.environment["STEAM_API_KEY"] else {
            print("Error: Steam API key not found")
            return
        }
        
        // Using the Steam Web API for CS2 highlights
        let urlString = "https://api.steampowered.com/ICSGOServers_730/GetGameMapsPlaytime/v1/?key=\(apiKey)&steamid=\(steamId)&interval=all"
        
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            return
        }
        
        do {
            print("Fetching CS2 highlights for Steam ID: \(steamId)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid response type")
                return
            }
            
            print("CS2 Highlights API Response Status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                let response = try JSONDecoder().decode(CS2HighlightsResponse.self, from: data)
                print("Successfully decoded CS2 highlights response")
                print("Number of highlights: \(response.highlights.count)")
                
                await MainActor.run {
                    self.cs2Highlights = response.highlights
                    if let firstHighlight = response.highlights.first {
                        self.selectedHighlight = firstHighlight
                        self.isHighlightViewPresented = true
                    } else {
                        print("No highlights found")
                        // Create a sample highlight if none are found
                        self.selectedHighlight = CS2Highlight(
                            id: "sample",
                            timestamp: Int(Date().timeIntervalSince1970),
                            matchId: "sample_match",
                            roundNumber: 1,
                            description: "Sample highlight - No recent highlights available",
                            videoUrl: nil,
                            thumbnailUrl: nil
                        )
                        self.isHighlightViewPresented = true
                    }
                }
            } else {
                print("Error: API returned status code \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
            }
        } catch {
            print("Error fetching CS2 highlights: \(error)")
            // Create a sample highlight on error
            await MainActor.run {
                self.selectedHighlight = CS2Highlight(
                    id: "error",
                    timestamp: Int(Date().timeIntervalSince1970),
                    matchId: "error_match",
                    roundNumber: 1,
                    description: "Error loading highlights - Please try again later",
                    videoUrl: nil,
                    thumbnailUrl: nil
                )
                self.isHighlightViewPresented = true
            }
        }
    }
    
    private func checkPlaytimeWarnings() {
        let calendar = Calendar.current
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
        
        // Then, get playtime stats
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
            
            // Fetch playtime
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
            if achievementsHttpResponse.statusCode == 200 && playtimeHttpResponse.statusCode == 200 {
                do {
                    // Decode achievements
                    let achievementsResponse = try JSONDecoder().decode(AchievementsResponse.self, from: achievementsData)
                    let totalAchievements = achievementsResponse.playerstats.achievements.count
                    let achievementCount = achievementsResponse.playerstats.achievements.filter { $0.achieved == 1 }.count
                    
                    // Decode playtime
                    let playtimeResponse = try JSONDecoder().decode(RecentGamesResponse.self, from: playtimeData)
                    let cs2Game = playtimeResponse.response.games.first { $0.appid == 730 }
                    
                    let totalPlaytime = cs2Game?.playtime_forever ?? 0
                    let recentPlaytime = cs2Game?.playtime_2weeks ?? 0
                    let lastPlayed = cs2Game?.last_played ?? Int(Date().timeIntervalSince1970)
                    
                    await MainActor.run {
                        self.cs2Stats = CS2Stats(
                            totalPlaytime: totalPlaytime,
                            recentPlaytime: recentPlaytime,
                            achievementCount: achievementCount,
                            totalAchievements: totalAchievements,
                            lastPlayed: lastPlayed
                        )
                        self.isCS2StatsViewPresented = true
                    }
                    
                } catch {
                    print("Error processing responses: \(error)")
                }
            }
        } catch {
            print("Error fetching CS2 stats: \(error)")
        }
    }
    
    func fetchPremierMatches(steamId: String) async {
        let urlString = "https://api.steampowered.com/ICSGOServers_730/GetMatchHistory/v1/?key=\(steamAPIKey)&steamid=\(steamId)&mode=competitive&limit=8"
        
        print("Fetching Premier matches from URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL")
            return
        }
        
        do {
            print("Fetching Premier matches for Steam ID: \(steamId)")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid response type")
                return
            }
            
            print("Premier Matches API Response Status: \(httpResponse.statusCode)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response body: \(responseString)")
            }
            
            if httpResponse.statusCode == 200 {
                do {
                    let matchesResponse = try JSONDecoder().decode(PremierMatchesResponse.self, from: data)
                    print("Successfully decoded Premier matches response")
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
                        self.isPremierMatchesViewPresented = true
                    }
                } catch {
                    print("Error decoding Premier matches: \(error)")
                    print("Raw data: \(String(data: data, encoding: .utf8) ?? "Unable to convert data to string")")
                    // Show sample data on error
                    await MainActor.run {
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
                        self.isPremierMatchesViewPresented = true
                    }
                }
            } else {
                print("Error: API returned status code \(httpResponse.statusCode)")
                // Show sample data on error
                await MainActor.run {
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
                    self.isPremierMatchesViewPresented = true
                }
            }
        } catch {
            print("Error fetching Premier matches: \(error)")
            // Show sample data on error
            await MainActor.run {
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
                self.isPremierMatchesViewPresented = true
            }
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

// Add custom error types
enum SteamError: LocalizedError {
    case invalidSteamId
    case profileNotFound
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidSteamId:
            return "Invalid Steam ID format. Please enter a valid Steam ID"
        case .profileNotFound:
            return "Profile not found or is private"
        case .apiError(let message):
            return "Steam API Error: \(message)"
        }
    }
} 
