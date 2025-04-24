import SwiftUI
import Charts

struct PlayerStatsView: View {
    @StateObject private var viewModel: PlayerStatsViewModel
    @State private var selectedTab = 0
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: PlayerStatsViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack {
                headerView
                
                tiltWarningView
                
                tabPickerView
                
                tabContentView
            }
            
            loadingOverlay
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.2, blue: 0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("CS2 Stats")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                viewModel.refreshStats()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding()
    }
    
    // MARK: - Tilt Warning
    
    private var tiltWarningView: some View {
        Group {
            if viewModel.isTilted && viewModel.shouldTakeBreak {
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Tilt Detected")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.dismissTiltWarning()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    Text(viewModel.tiltReason ?? "Your recent performance suggests you might be tilted")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Consider taking a short break to reset")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color(red: 0.2, green: 0.2, blue: 0.3))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Tab Picker
    
    private var tabPickerView: some View {
        Picker("Stats View", selection: $selectedTab) {
            Text("Progress").tag(0)
            Text("Team").tag(1)
            Text("Weekly").tag(2)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
    }
    
    // MARK: - Tab Content
    
    private var tabContentView: some View {
        TabView(selection: $selectedTab) {
            progressTabView
                .tag(0)
            
            teamTabView
                .tag(1)
            
            weeklyTabView
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    
    // MARK: - Progress Tab
    
    private var progressTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                kdRatioChartView
                adrChartView
                utilityEffectivenessChartView
            }
            .padding()
        }
    }
    
    private var kdRatioChartView: some View {
        StatCard(title: "K/D Ratio Trend") {
            VStack(alignment: .leading, spacing: 10) {
                Text(String(format: "%.2f", viewModel.playerStats?.kdRatio ?? 0))
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Chart {
                    ForEach(Array(zip(viewModel.kdRatioHistory.indices, viewModel.kdRatioHistory)), id: \.0) { index, value in
                        LineMark(
                            x: .value("Match", index + 1),
                            y: .value("K/D", value)
                        )
                        .foregroundStyle(Color.blue)
                    }
                }
                .frame(height: 200)
            }
        }
    }
    
    private var adrChartView: some View {
        StatCard(title: "Average Damage per Round") {
            VStack(alignment: .leading, spacing: 10) {
                Text(String(format: "%.1f", viewModel.playerStats?.adr ?? 0))
                    .font(.headline)
                    .foregroundColor(.green)
                
                Chart {
                    ForEach(Array(zip(viewModel.adrHistory.indices, viewModel.adrHistory)), id: \.0) { index, value in
                        LineMark(
                            x: .value("Match", index + 1),
                            y: .value("ADR", value)
                        )
                        .foregroundStyle(Color.green)
                    }
                }
                .frame(height: 200)
            }
        }
    }
    
    private var utilityEffectivenessChartView: some View {
        StatCard(title: "Utility Effectiveness") {
            VStack(alignment: .leading, spacing: 10) {
                Text(String(format: "%.1f%%", (viewModel.playerStats?.utilityEffectiveness ?? 0) * 100))
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Chart {
                    ForEach(Array(zip(viewModel.utilityEffectivenessHistory.indices, viewModel.utilityEffectivenessHistory)), id: \.0) { index, value in
                        LineMark(
                            x: .value("Match", index + 1),
                            y: .value("Effectiveness", value)
                        )
                        .foregroundStyle(Color.orange)
                    }
                }
                .frame(height: 200)
            }
        }
    }
    
    // MARK: - Team Tab
    
    private var teamTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                bestTeammatesView
                
                if let stats = viewModel.playerStats {
                    teamChemistryStatsView(stats: stats)
                }
            }
        }
    }
    
    private var bestTeammatesView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Best Teammates")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(viewModel.bestTeammates, id: \.steamId) { teammate in
                TeammateCard(steamId: teammate.steamId, stats: teammate.stats)
            }
        }
        .padding()
    }
    
    private func teamChemistryStatsView(stats: CS2PlayerStats) -> some View {
        StatCard(title: "Team Play") {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(stats.matchesPlayed) matches")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                StatRow(title: "Win Rate with Team", value: String(format: "%.1f%%", stats.winRate * 100), icon: "chart.bar.fill", color: .green)
                StatRow(title: "Average K/D with Team", value: String(format: "%.2f", stats.kdRatio), icon: "target", color: .blue)
                StatRow(title: "Team Synergy Score", value: String(format: "%.1f", viewModel.bestTeammates.first?.stats.synergyScore ?? 0), icon: "person.2.fill", color: .orange)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Weekly Tab
    
    private var weeklyTabView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let stats = viewModel.weeklyStats {
                    weeklyOverviewView(stats: stats)
                }
                
                improvementSuggestionsView
            }
        }
    }
    
    private func weeklyOverviewView(stats: CS2PlayerStats) -> some View {
        StatCard(title: "Weekly Overview") {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(stats.matchesPlayed) matches")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                StatRow(title: "Win Rate", value: String(format: "%.1f%%", stats.winRate * 100), icon: "chart.bar.fill", color: .green)
                StatRow(title: "K/D Ratio", value: String(format: "%.2f", stats.kdRatio), icon: "target", color: .blue)
                StatRow(title: "ADR", value: String(format: "%.1f", stats.adr), icon: "flame.fill", color: .orange)
                StatRow(title: "Headshot %", value: String(format: "%.1f%%", stats.headshotPercentage * 100), icon: "scope", color: .red)
            }
        }
        .padding(.horizontal)
    }
    
    private var improvementSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Areas for Improvement")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ForEach(viewModel.weeklyImprovements, id: \.self) { improvement in
                HStack {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.green)
                    
                    Text(improvement)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                .background(Color(red: 0.2, green: 0.2, blue: 0.3))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Loading stats...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
            }
        }
    }
}

// MARK: - Supporting Views

struct TeammateCard: View {
    let steamId: String
    let stats: TeammateStats
    
    var body: some View {
        HStack {
            // Teammate Avatar (placeholder)
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(steamId.prefix(1)))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Steam ID: \(steamId)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                HStack {
                    Text("\(stats.matchesPlayedTogether) matches")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(Int(stats.winRateTogether * 100))% win rate")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 5) {
                Text("Synergy")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(String(format: "%.1f", stats.synergyScore))
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(red: 0.2, green: 0.2, blue: 0.3))
        .cornerRadius(10)
    }
}

#Preview {
    PlayerStatsView(userId: "sample_user_id")
} 