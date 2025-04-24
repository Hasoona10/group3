import SwiftUI

struct CS2CombinedView: View {
    @Environment(\.dismiss) private var dismiss
    let game: Game
    @ObservedObject var viewModel: SteamViewModel
    @State private var selectedTab = 0
    
    private let gradientStart = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let gradientEnd = Color(red: 0.12, green: 0.15, blue: 0.23)
    
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
                
                VStack(spacing: 0) {
                    // Tab selector
                    HStack(spacing: 0) {
                        TabButton(title: "Overview", isSelected: selectedTab == 0) {
                            withAnimation {
                                selectedTab = 0
                            }
                        }
                        
                        TabButton(title: "Stats", isSelected: selectedTab == 1) {
                            withAnimation {
                                selectedTab = 1
                            }
                        }
                        
                        TabButton(title: "Matches", isSelected: selectedTab == 2) {
                            withAnimation {
                                selectedTab = 2
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        // Overview Tab
                        ScrollView {
                            VStack(spacing: 24) {
                                // Quick Stats
                                StatCard(title: "Quick Overview") {
                                    VStack(spacing: 16) {
                                        StatRow(
                                            title: "Recent Playtime",
                                            value: formatPlaytime(minutes: viewModel.cs2Stats?.recentPlaytime ?? 0),
                                            icon: "clock.fill",
                                            color: .blue
                                        )
                                        
                                        let recentMatches = viewModel.premierMatches.prefix(5)
                                        let wins = recentMatches.filter { $0.result == "Victory" }.count
                                        let losses = recentMatches.count - wins
                                        StatRow(
                                            title: "Recent W/L",
                                            value: "\(wins)W - \(losses)L",
                                            icon: "chart.line.uptrend.xyaxis",
                                            color: .green
                                        )
                                        
                                        if let lastMatch = viewModel.premierMatches.first {
                                            StatRow(
                                                title: "Last Match K/D/A",
                                                value: "\(lastMatch.kills)/\(lastMatch.deaths)/\(lastMatch.assists)",
                                                icon: "target",
                                                color: .red
                                            )
                                        }
                                    }
                                }
                                
                                // Achievement Progress
                                StatCard(title: "Achievements") {
                                    VStack(spacing: 16) {
                                        let achievementCount = viewModel.cs2Stats?.achievementCount ?? 0
                                        let totalAchievements = viewModel.cs2Stats?.totalAchievements ?? 0
                                        let percentage = totalAchievements > 0 ? 
                                            Double(achievementCount) / Double(totalAchievements) * 100 : 0
                                        
                                        StatRow(
                                            title: "Progress",
                                            value: "\(achievementCount)/\(totalAchievements)",
                                            icon: "trophy.fill",
                                            color: .yellow
                                        )
                                        
                                        // Progress Bar
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.white.opacity(0.1))
                                                    .frame(height: 8)
                                                
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.yellow)
                                                    .frame(width: geometry.size.width * CGFloat(percentage / 100), height: 8)
                                            }
                                        }
                                        .frame(height: 8)
                                        
                                        Text("\(Int(percentage))% Complete")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                        }
                        .tag(0)
                        
                        // Detailed Stats Tab
                        ScrollView {
                            VStack(spacing: 24) {
                                // Combat Stats
                                StatCard(title: "Combat Performance") {
                                    VStack(spacing: 16) {
                                        if let lastMatch = viewModel.premierMatches.first {
                                            StatRow(
                                                title: "K/D Ratio",
                                                value: String(format: "%.2f", Double(lastMatch.kills) / Double(max(1, lastMatch.deaths))),
                                                icon: "scope",
                                                color: .red
                                            )
                                            
                                            StatRow(
                                                title: "Headshot %",
                                                value: "\(Int(Double(lastMatch.headshots) / Double(max(1, lastMatch.kills)) * 100))%",
                                                icon: "target",
                                                color: .orange
                                            )
                                            
                                            StatRow(
                                                title: "Average Damage",
                                                value: "\(lastMatch.damage)",
                                                icon: "flame.fill",
                                                color: .red
                                            )
                                        }
                                    }
                                }
                                
                                // Playtime Stats
                                StatCard(title: "Playtime") {
                                    VStack(spacing: 16) {
                                        StatRow(
                                            title: "Total Hours",
                                            value: formatPlaytime(minutes: viewModel.cs2Stats?.totalPlaytime ?? 0),
                                            icon: "clock.fill",
                                            color: .blue
                                        )
                                        
                                        StatRow(
                                            title: "Recent (2 weeks)",
                                            value: formatPlaytime(minutes: viewModel.cs2Stats?.recentPlaytime ?? 0),
                                            icon: "clock",
                                            color: .green
                                        )
                                        
                                        StatRow(
                                            title: "Last Session",
                                            value: formatDate(timestamp: viewModel.cs2Stats?.lastPlayed ?? 0),
                                            icon: "calendar",
                                            color: .purple
                                        )
                                    }
                                }
                            }
                            .padding()
                        }
                        .tag(1)
                        
                        // Matches Tab
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(viewModel.premierMatches) { match in
                                    MatchCard(match: match)
                                        .transition(.opacity.combined(with: .slide))
                                }
                                
                                if viewModel.premierMatches.isEmpty {
                                    VStack(spacing: 12) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        
                                        Text("No recent matches found")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                        
                                        Text("Play some matches to see your stats here")
                                            .font(.subheadline)
                                            .foregroundColor(.gray.opacity(0.8))
                                    }
                                    .padding(.top, 40)
                                }
                            }
                            .padding()
                        }
                        .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("CS2 Stats & Matches")
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
}

#Preview {
    CS2CombinedView(game: Game(appid: 730, name: "Counter-Strike 2", playtime_2weeks: 0, playtime_forever: 0, img_icon_url: "", img_logo_url: nil, last_played: nil), viewModel: SteamViewModel())
} 