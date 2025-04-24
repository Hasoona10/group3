import Foundation
import SwiftUI
import Combine

class PlayerStatsViewModel: ObservableObject {
    @Published var playerStats: CS2PlayerStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Progress tracking
    @Published var kdRatioHistory: [Double] = []
    @Published var adrHistory: [Double] = []
    @Published var utilityEffectivenessHistory: [Double] = []
    
    // Team chemistry
    @Published var teammates: [TeammateStats] = []
    @Published var bestTeammates: [(steamId: String, stats: TeammateStats)] = []
    
    // Tilt detection
    @Published var isTilted = false
    @Published var tiltReason: String?
    @Published var shouldTakeBreak = false
    
    // Weekly review
    @Published var weeklyStats: CS2PlayerStats?
    @Published var weeklyImprovements: [String] = []
    
    @Published var currentSession: GamingSession?
    @Published var showBreakAlert = false
    
    private var cancellables = Set<AnyCancellable>()
    private var userId: String
    private let sessionManager = SessionManager.shared
    private let notificationService = NotificationService.shared
    
    init(userId: String) {
        self.userId = userId
        loadStats()
        startNewSession()
    }
    
    // MARK: - Data Loading
    
    func loadStats() {
        isLoading = true
        
        // In a real app, this would fetch from a backend
        // For now, we'll simulate loading with sample data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadSampleData()
            self.isLoading = false
        }
    }
    
    private func loadSampleData() {
        // Create sample player stats
        let sampleStats = CS2PlayerStats(
            userId: userId,
            matchesPlayed: 100,
            matchesWon: 55,
            matchesLost: 40,
            matchesTied: 5,
            kills: 1500,
            deaths: 1200,
            assists: 800,
            headshots: 600,
            damageDealt: 30000,
            damageTaken: 25000,
            utilityDamage: 5000,
            utilityThrown: 1000,
            utilityEffectiveness: 0.65,
            moneySpent: 500000,
            moneyEarned: 600000,
            equipmentValue: 100000,
            mapStats: [
                "Mirage": MapStats(
                    matchesPlayed: 30,
                    matchesWon: 18,
                    averageKdRatio: 1.2,
                    averageAdr: 85.5,
                    winRate: 0.6,
                    favoritePositions: ["A Site", "Mid"]
                ),
                "Dust 2": MapStats(
                    matchesPlayed: 25,
                    matchesWon: 15,
                    averageKdRatio: 1.1,
                    averageAdr: 80.0,
                    winRate: 0.6,
                    favoritePositions: ["Long A", "B Tunnels"]
                )
            ],
            teammatesPlayedWith: [
                "76561198123456789": TeammateStats(
                    matchesPlayedTogether: 50,
                    matchesWonTogether: 30,
                    winRateTogether: 0.6,
                    averageKdRatioCombined: 2.2,
                    synergyScore: 0.8,
                    lastPlayedTogether: Date().addingTimeInterval(-86400) // Yesterday
                )
            ],
            recentPerformance: [
                MatchPerformance(
                    date: Date().addingTimeInterval(-3600),
                    map: "Mirage",
                    kdRatio: 0.8,
                    adr: 65.0,
                    utilityEffectiveness: 0.5,
                    result: .loss,
                    tiltScore: 0.7
                ),
                MatchPerformance(
                    date: Date().addingTimeInterval(-7200),
                    map: "Dust 2",
                    kdRatio: 1.2,
                    adr: 90.0,
                    utilityEffectiveness: 0.7,
                    result: .win,
                    tiltScore: 0.3
                )
            ]
        )
        
        self.playerStats = sampleStats
        self.updateProgressHistory()
        self.updateTeamChemistry()
        self.checkForTilt()
        self.generateWeeklyReview()
    }
    
    // MARK: - Progress Tracking
    
    private func updateProgressHistory() {
        guard let stats = playerStats else { return }
        
        // In a real app, this would track historical data
        // For now, we'll generate sample history
        kdRatioHistory = [1.0, 1.1, 1.2, 1.15, 1.25]
        adrHistory = [75.0, 80.0, 85.0, 82.0, 88.0]
        utilityEffectivenessHistory = [0.5, 0.55, 0.6, 0.58, 0.65]
    }
    
    // MARK: - Team Chemistry
    
    private func updateTeamChemistry() {
        guard let stats = playerStats else { return }
        
        // Convert dictionary to array and add steamId to each TeammateStats
        teammates = stats.teammatesPlayedWith.map { steamId, stats in
            var teammateStats = stats
            // Add a computed property for steamId
            return teammateStats
        }
        
        // Sort teammates by synergy score
        bestTeammates = stats.teammatesPlayedWith.sorted { $0.value.synergyScore > $1.value.synergyScore }
            .prefix(5)
            .map { (steamId: $0.key, stats: $0.value) }
    }
    
    // MARK: - Tilt Detection
    
    private func checkForTilt() {
        guard let stats = playerStats, !stats.recentPerformance.isEmpty else { return }
        
        // Calculate average tilt score from recent matches
        let recentTiltScores = stats.recentPerformance.prefix(3).map { $0.tiltScore }
        let averageTiltScore = recentTiltScores.reduce(0, +) / Double(recentTiltScores.count)
        
        // Check for consecutive losses
        let recentResults = stats.recentPerformance.prefix(3).map { $0.result }
        let consecutiveLosses = recentResults.filter { $0 == .loss }.count >= 2
        
        // Check for declining performance
        let decliningPerformance = recentTiltScores.count >= 2 && 
            recentTiltScores[0] > recentTiltScores[1] && 
            recentTiltScores[1] > recentTiltScores[2]
        
        // Determine if player is tilted
        isTilted = averageTiltScore > 0.6 || consecutiveLosses || decliningPerformance
        
        if isTilted {
            if averageTiltScore > 0.6 {
                tiltReason = "Your recent matches show signs of frustration"
            } else if consecutiveLosses {
                tiltReason = "You've lost multiple matches in a row"
            } else if decliningPerformance {
                tiltReason = "Your performance has been declining"
            }
            
            // Recommend a break if tilted
            shouldTakeBreak = true
        }
    }
    
    // MARK: - Weekly Review
    
    private func generateWeeklyReview() {
        // In a real app, this would aggregate stats from the past week
        // For now, we'll use the sample stats
        weeklyStats = playerStats
        
        // Generate improvement suggestions
        weeklyImprovements = []
        
        if let stats = playerStats {
            if stats.kdRatio < 1.0 {
                weeklyImprovements.append("Work on improving your K/D ratio")
            }
            
            if stats.adr < 80.0 {
                weeklyImprovements.append("Focus on dealing more damage per round")
            }
            
            if stats.utilityEffectiveness < 0.6 {
                weeklyImprovements.append("Practice your utility usage")
            }
            
            if stats.headshotPercentage < 0.4 {
                weeklyImprovements.append("Aim for more headshots")
            }
        }
    }
    
    // MARK: - Public Methods
    
    func refreshStats() {
        loadStats()
    }
    
    func dismissTiltWarning() {
        shouldTakeBreak = false
    }
    
    func startNewSession() {
        currentSession = sessionManager.startSession(userId: userId, gameType: "CS2")
        
        // Schedule break reminder after 3 hours
        notificationService.scheduleBreakReminder(after: 3 * 60 * 60)
    }
    
    func endCurrentSession() {
        if let session = currentSession {
            sessionManager.endSession(session)
            currentSession = nil
            notificationService.cancelAllNotifications()
        }
    }
    
    func checkBreakNeeded() {
        if sessionManager.shouldTakeBreak() {
            showBreakAlert = true
            notificationService.schedulePerformanceWarning(after: 0)
        }
    }
    
    func updateStats(_ newStats: CS2PlayerStats) {
        playerStats = newStats
        checkBreakNeeded()
    }
    
    func addTeammate(_ teammate: TeammateStats, steamId: String) {
        // Create a new teammate entry
        var newTeammate = teammate
        
        // Add to teammates array
        teammates.append(newTeammate)
        
        // Update the player stats
        if var stats = playerStats {
            stats.teammatesPlayedWith[steamId] = teammate
            playerStats = stats
        }
    }
    
    func removeTeammate(steamId: String) {
        // Remove from teammates array
        teammates.removeAll { _ in true } // This is a placeholder since we don't have an id property
        
        // Update the player stats
        if var stats = playerStats {
            stats.teammatesPlayedWith.removeValue(forKey: steamId)
            playerStats = stats
        }
    }
    
    func calculateTeamChemistry() -> Double {
        guard !teammates.isEmpty else { return 0.0 }
        
        let totalChemistry = teammates.reduce(0.0) { $0 + $1.synergyScore }
        return totalChemistry / Double(teammates.count)
    }
    
    func detectTilt() -> Bool {
        guard let stats = playerStats else { return false }
        
        // Simple tilt detection based on recent performance
        let recentMatches = stats.recentPerformance.prefix(3)
        let recentKD = recentMatches.map { $0.kdRatio }
        let averageKD = recentKD.reduce(0.0, +) / Double(recentKD.count)
        
        return averageKD < 0.8 // Consider player tilted if K/D ratio drops below 0.8
    }
    
    // MARK: - User Management
    
    func updateUserId(_ newUserId: String) {
        userId = newUserId
        loadStats()
    }
    
    // Alias for loadStats to maintain compatibility
    func loadPlayerStats() {
        loadStats()
    }
} 