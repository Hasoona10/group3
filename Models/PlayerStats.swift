import Foundation

struct CS2PlayerStats: Codable, Identifiable {
    let id: String
    let userId: String
    let date: Date
    
    // Match Statistics
    var matchesPlayed: Int
    var matchesWon: Int
    var matchesLost: Int
    var matchesTied: Int
    
    // Performance Metrics
    var kills: Int
    var deaths: Int
    var assists: Int
    var headshots: Int
    var damageDealt: Int
    var damageTaken: Int
    var utilityDamage: Int
    var utilityThrown: Int
    var utilityEffectiveness: Double // Percentage of utility that caused damage or blocked enemies
    
    // Economy
    var moneySpent: Int
    var moneyEarned: Int
    var equipmentValue: Int
    
    // Map Performance
    var mapStats: [String: MapStats]
    
    // Team Chemistry
    var teammatesPlayedWith: [String: TeammateStats] // Steam ID: Stats
    
    // Computed Properties
    var kdRatio: Double {
        return deaths > 0 ? Double(kills) / Double(deaths) : Double(kills)
    }
    
    var adr: Double {
        return matchesPlayed > 0 ? Double(damageDealt) / Double(matchesPlayed) : 0
    }
    
    var winRate: Double {
        return matchesPlayed > 0 ? Double(matchesWon) / Double(matchesPlayed) : 0
    }
    
    var headshotPercentage: Double {
        return kills > 0 ? Double(headshots) / Double(kills) : 0
    }
    
    // Tilt Detection
    var recentPerformance: [MatchPerformance] // Last 5 matches for tilt detection
    
    // Initializer
    init(id: String = UUID().uuidString, 
         userId: String, 
         date: Date = Date(),
         matchesPlayed: Int = 0,
         matchesWon: Int = 0,
         matchesLost: Int = 0,
         matchesTied: Int = 0,
         kills: Int = 0,
         deaths: Int = 0,
         assists: Int = 0,
         headshots: Int = 0,
         damageDealt: Int = 0,
         damageTaken: Int = 0,
         utilityDamage: Int = 0,
         utilityThrown: Int = 0,
         utilityEffectiveness: Double = 0,
         moneySpent: Int = 0,
         moneyEarned: Int = 0,
         equipmentValue: Int = 0,
         mapStats: [String: MapStats] = [:],
         teammatesPlayedWith: [String: TeammateStats] = [:],
         recentPerformance: [MatchPerformance] = []) {
        self.id = id
        self.userId = userId
        self.date = date
        self.matchesPlayed = matchesPlayed
        self.matchesWon = matchesWon
        self.matchesLost = matchesLost
        self.matchesTied = matchesTied
        self.kills = kills
        self.deaths = deaths
        self.assists = assists
        self.headshots = headshots
        self.damageDealt = damageDealt
        self.damageTaken = damageTaken
        self.utilityDamage = utilityDamage
        self.utilityThrown = utilityThrown
        self.utilityEffectiveness = utilityEffectiveness
        self.moneySpent = moneySpent
        self.moneyEarned = moneyEarned
        self.equipmentValue = equipmentValue
        self.mapStats = mapStats
        self.teammatesPlayedWith = teammatesPlayedWith
        self.recentPerformance = recentPerformance
    }
}

// Map-specific statistics
struct MapStats: Codable {
    var matchesPlayed: Int
    var matchesWon: Int
    var averageKdRatio: Double
    var averageAdr: Double
    var winRate: Double
    var favoritePositions: [String] // Positions/roles the player prefers on this map
}

// Teammate statistics for team chemistry
struct TeammateStats: Codable {
    var matchesPlayedTogether: Int
    var matchesWonTogether: Int
    var winRateTogether: Double
    var averageKdRatioCombined: Double
    var synergyScore: Double // Calculated based on complementary playstyles
    var lastPlayedTogether: Date
}

// Match performance for tilt detection
struct MatchPerformance: Codable {
    let date: Date
    let map: String
    let kdRatio: Double
    let adr: Double
    let utilityEffectiveness: Double
    let result: MatchResult
    let tiltScore: Double // Calculated based on performance metrics
    
    enum MatchResult: String, Codable {
        case win
        case loss
        case tie
    }
} 