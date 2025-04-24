import SwiftUI

// Color definitions
private let gradientStart = Color(red: 0.07, green: 0.09, blue: 0.15)
private let gradientEnd = Color(red: 0.12, green: 0.15, blue: 0.23)

struct CS2StatsView: View {
    let game: Game
    @ObservedObject var viewModel: SteamViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    private func formatPlaytime(minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
    
    private func formatDate(timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [gradientStart, gradientEnd]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Playtime Stats
                        StatCard(title: "Playtime") {
                            VStack(spacing: 16) {
                                StatRow(
                                    title: "Total Playtime",
                                    value: formatPlaytime(minutes: viewModel.cs2Stats?.totalPlaytime ?? 0),
                                    icon: "clock.fill",
                                    color: .blue
                                )
                                
                                StatRow(
                                    title: "Recent Playtime (2 weeks)",
                                    value: formatPlaytime(minutes: viewModel.cs2Stats?.recentPlaytime ?? 0),
                                    icon: "clock",
                                    color: .green
                                )
                                
                                StatRow(
                                    title: "Last Played",
                                    value: formatDate(timestamp: viewModel.cs2Stats?.lastPlayed ?? 0),
                                    icon: "calendar",
                                    color: .purple
                                )
                            }
                        }
                        
                        // Achievement Stats
                        StatCard(title: "Achievements") {
                            VStack(spacing: 16) {
                                let achievementCount = viewModel.cs2Stats?.achievementCount ?? 0
                                let totalAchievements = viewModel.cs2Stats?.totalAchievements ?? 0
                                let percentage = totalAchievements > 0 ? 
                                    Double(achievementCount) / Double(totalAchievements) * 100 : 0
                                
                                StatRow(
                                    title: "Completed",
                                    value: "\(achievementCount)/\(totalAchievements)",
                                    icon: "trophy.fill",
                                    color: .yellow
                                )
                                
                                StatRow(
                                    title: "Completion Rate",
                                    value: String(format: "%.1f%%", percentage),
                                    icon: "chart.bar.fill",
                                    color: .orange
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("CS2 Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    let mockGame = Game(
        appid: 730,
        name: "Counter-Strike 2",
        playtime_2weeks: 60,
        playtime_forever: 120,
        img_icon_url: "",
        img_logo_url: "",
        last_played: Int(Date().timeIntervalSince1970)
    )
    CS2StatsView(game: mockGame, viewModel: SteamViewModel())
} 