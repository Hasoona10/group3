import SwiftUI

struct GameDetailView: View {
    let game: Game
    @StateObject private var viewModel: GameDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(game: Game) {
        self.game = game
        _viewModel = StateObject(wrappedValue: GameDetailViewModel(gameId: String(game.id)))
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.2, blue: 0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Game Header
                    VStack(spacing: 10) {
                        // Game Icon
                        AsyncImage(url: URL(string: game.img_icon_url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 120, height: 120)
                        .cornerRadius(20)
                        
                        Text(game.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(game.playtime_forever) hours played")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    
                    // Game Stats
                    if let stats = viewModel.gameStats {
                        VStack(spacing: 15) {
                            StatCard(title: "Recent Performance") {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("\(stats.recentMatches) matches")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    StatRow(title: "Win Rate", value: String(format: "%.1f%%", stats.winRate * 100), icon: "chart.bar.fill", color: .green)
                                    StatRow(title: "K/D Ratio", value: String(format: "%.2f", stats.kdRatio), icon: "target", color: .blue)
                                    StatRow(title: "ADR", value: String(format: "%.1f", stats.adr), icon: "flame.fill", color: .orange)
                                }
                            }
                            
                            StatCard(title: "Achievements") {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("\(stats.achievementCount)/\(stats.totalAchievements)")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    StatRow(title: "Completion", value: String(format: "%.1f%%", (Double(stats.achievementCount) / Double(stats.totalAchievements)) * 100), icon: "checkmark.circle.fill", color: .green)
                                    StatRow(title: "Rare Achievements", value: "\(stats.rareAchievements)", icon: "star.fill", color: .yellow)
                                }
                            }
                            
                            if !stats.recentAchievements.isEmpty {
                                StatCard(title: "Recent Achievements") {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("\(stats.recentAchievements.count) new")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                        
                                        ForEach(stats.recentAchievements, id: \.name) { achievement in
                                            HStack {
                                                Image(systemName: "trophy.fill")
                                                    .foregroundColor(.yellow)
                                                
                                                Text(achievement.name)
                                                    .foregroundColor(.white)
                                                
                                                Spacer()
                                                
                                                Text(achievement.unlockDate, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Loading State
                    if viewModel.isLoading {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Loading game stats...")
                                .foregroundColor(.white)
                                .padding(.top)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.refreshStats()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                }
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - View Model

class GameDetailViewModel: ObservableObject {
    @Published var gameStats: GameStats?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private let gameId: String
    
    init(gameId: String) {
        self.gameId = gameId
        loadGameStats()
    }
    
    func loadGameStats() {
        isLoading = true
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            
            // Sample data
            self.gameStats = GameStats(
                recentMatches: 10,
                winRate: 0.6,
                kdRatio: 1.2,
                adr: 85.5,
                achievementCount: 15,
                totalAchievements: 30,
                rareAchievements: 3,
                recentAchievements: [
                    GameAchievement(name: "First Blood", unlockDate: Date().addingTimeInterval(-86400)),
                    GameAchievement(name: "Ace", unlockDate: Date().addingTimeInterval(-172800))
                ]
            )
            self.isLoading = false
        }
    }
    
    func refreshStats() {
        loadGameStats()
    }
}

// MARK: - Models

struct GameStats {
    let recentMatches: Int
    let winRate: Double
    let kdRatio: Double
    let adr: Double
    let achievementCount: Int
    let totalAchievements: Int
    let rareAchievements: Int
    let recentAchievements: [GameAchievement]
}

struct GameAchievement {
    let name: String
    let unlockDate: Date
}

#Preview {
    NavigationView {
        GameDetailView(game: Game(
            appid: 730,
            name: "Counter-Strike 2",
            playtime_2weeks: 20,
            playtime_forever: 1000,
            img_icon_url: "https://example.com/cs2.png",
            img_logo_url: "https://example.com/cs2_logo.png",
            last_played: Int(Date().timeIntervalSince1970)
        ))
    }
} 