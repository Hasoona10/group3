import Foundation

struct GamingSession: Codable, Identifiable {
    let id: String
    let userId: String
    let startTime: Date
    var endTime: Date?
    let gameType: String
    var breakCount: Int
    var lastBreakTime: Date?
    
    var duration: TimeInterval {
        endTime?.timeIntervalSince(startTime) ?? Date().timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        endTime == nil
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         startTime: Date = Date(),
         endTime: Date? = nil,
         gameType: String,
         breakCount: Int = 0,
         lastBreakTime: Date? = nil) {
        self.id = id
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
        self.gameType = gameType
        self.breakCount = breakCount
        self.lastBreakTime = lastBreakTime
    }
}

// MARK: - Session Manager
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published private(set) var currentSession: GamingSession?
    @Published private(set) var todaysSessions: [GamingSession] = []
    
    private let userDefaults = UserDefaults.standard
    private let sessionKey = "current_gaming_session"
    private let maxSessionDuration: TimeInterval = 4 * 60 * 60 // 4 hours
    private let breakInterval: TimeInterval = 45 * 60 // 45 minutes
    private let maxDailyPlaytime: TimeInterval = 3 * 60 * 60 // 3 hours
    
    private init() {
        loadSessions()
    }
    
    func startSession(userId: String, gameType: String) -> GamingSession {
        let session = GamingSession(
            userId: userId,
            gameType: gameType
        )
        currentSession = session
        saveSessions()
        return session
    }
    
    func endSession(_ session: GamingSession) {
        var updatedSession = session
        updatedSession.endTime = Date()
        todaysSessions.append(updatedSession)
        currentSession = nil
        saveSessions()
    }
    
    func takeBreak() {
        guard var session = currentSession else { return }
        session.breakCount += 1
        session.lastBreakTime = Date()
        currentSession = session
        saveSessions()
    }
    
    var totalPlaytimeToday: TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return todaysSessions
            .filter { calendar.isDate($0.startTime, inSameDayAs: today) }
            .reduce(0) { $0 + $1.duration }
    }
    
    func shouldTakeBreak() -> Bool {
        guard let session = currentSession else { return false }
        
        // Check if session duration exceeds max
        if session.duration >= maxSessionDuration {
            return true
        }
        
        // Check if it's time for a break based on interval
        if let lastBreak = session.lastBreakTime {
            return Date().timeIntervalSince(lastBreak) >= breakInterval
        }
        
        // Take first break after 45 minutes
        return session.duration >= breakInterval
    }
    
    var shouldTakeDailyBreak: Bool {
        totalPlaytimeToday >= maxDailyPlaytime
    }
    
    private func loadSessions() {
        if let data = userDefaults.data(forKey: sessionKey),
           let session = try? JSONDecoder().decode(GamingSession.self, from: data) {
            currentSession = session
        }
    }
    
    private func saveSessions() {
        if let session = currentSession,
           let encoded = try? JSONEncoder().encode(session) {
            userDefaults.set(encoded, forKey: sessionKey)
        }
    }
} 