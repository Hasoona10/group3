import SwiftUI
import Charts

struct PerformanceAnalysisView: View {
    @EnvironmentObject var steamViewModel: SteamViewModel
    @StateObject private var viewModel: PlayerStatsViewModel
    
    init() {
        // Initialize with a temporary ID, will be updated in onAppear
        _viewModel = StateObject(wrappedValue: PlayerStatsViewModel(userId: ""))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance Metrics
                if let stats = viewModel.playerStats {
                    PerformanceMetricsView(stats: stats)
                }
                
                // Progress Charts
                ProgressChartsView(
                    kdRatioHistory: viewModel.kdRatioHistory,
                    adrHistory: viewModel.adrHistory,
                    utilityEffectivenessHistory: viewModel.utilityEffectivenessHistory
                )
                
                // Team Chemistry
                TeamChemistryView(teammates: viewModel.bestTeammates)
                
                // Weekly Review
                WeeklyReviewView(
                    weeklyStats: viewModel.weeklyStats,
                    improvements: viewModel.weeklyImprovements
                )
            }
            .padding()
        }
        .navigationTitle("Performance Analysis")
        .onAppear {
            if let userId = steamViewModel.currentUser?.id {
                viewModel.updateUserId(userId)
            }
        }
    }
}

// MARK: - Performance Metrics View
struct PerformanceMetricsView: View {
    let stats: CS2PlayerStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Performance Metrics")
                .font(.title2)
                .bold()
            
            HStack {
                MetricCard(title: "K/D Ratio", value: String(format: "%.2f", stats.kdRatio))
                MetricCard(title: "ADR", value: String(format: "%.1f", stats.adr))
                MetricCard(title: "Utility Effectiveness", value: String(format: "%.1f%%", stats.utilityEffectiveness * 100))
            }
            
            HStack {
                MetricCard(title: "Headshot %", value: String(format: "%.1f%%", stats.headshotPercentage * 100))
                MetricCard(title: "Win Rate", value: String(format: "%.1f%%", stats.winRate * 100))
                MetricCard(title: "Economy Efficiency", value: String(format: "%.1f%%", calculateEconomyEfficiency(stats) * 100))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    private func calculateEconomyEfficiency(_ stats: CS2PlayerStats) -> Double {
        // Calculate economy efficiency as money earned / money spent
        return stats.moneySpent > 0 ? Double(stats.moneyEarned) / Double(stats.moneySpent) : 0
    }
}

// MARK: - Progress Charts View
struct ProgressChartsView: View {
    let kdRatioHistory: [Double]
    let adrHistory: [Double]
    let utilityEffectivenessHistory: [Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Progress Tracking")
                .font(.title2)
                .bold()
            
            Chart {
                ForEach(Array(zip(kdRatioHistory.indices, kdRatioHistory)), id: \.0) { index, value in
                    LineMark(
                        x: .value("Match", index),
                        y: .value("K/D Ratio", value)
                    )
                }
            }
            .frame(height: 200)
            
            Chart {
                ForEach(Array(zip(adrHistory.indices, adrHistory)), id: \.0) { index, value in
                    LineMark(
                        x: .value("Match", index),
                        y: .value("ADR", value)
                    )
                }
            }
            .frame(height: 200)
            
            Chart {
                ForEach(Array(zip(utilityEffectivenessHistory.indices, utilityEffectivenessHistory)), id: \.0) { index, value in
                    LineMark(
                        x: .value("Match", index),
                        y: .value("Utility Effectiveness", value)
                    )
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

// MARK: - Team Chemistry View
struct TeamChemistryView: View {
    let teammates: [(steamId: String, stats: TeammateStats)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Team Chemistry")
                .font(.title2)
                .bold()
            
            ForEach(teammates, id: \.steamId) { teammate in
                TeammateRow(teammate: teammate.stats, steamId: teammate.steamId)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

// MARK: - Weekly Review View
struct WeeklyReviewView: View {
    let weeklyStats: CS2PlayerStats?
    let improvements: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Weekly Review")
                .font(.title2)
                .bold()
            
            if let stats = weeklyStats {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Matches Played: \(stats.matchesPlayed)")
                    Text("Win Rate: \(String(format: "%.1f%%", stats.winRate * 100))")
                    Text("Average K/D: \(String(format: "%.2f", stats.kdRatio))")
                }
            }
            
            if !improvements.isEmpty {
                Text("Areas for Improvement:")
                    .font(.headline)
                    .padding(.top)
                
                ForEach(improvements, id: \.self) { improvement in
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(.blue)
                        Text(improvement)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

// MARK: - Supporting Views
struct MetricCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct TeammateRow: View {
    let teammate: TeammateStats
    let steamId: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Steam ID: \(steamId)")
                    .font(.headline)
                Text("Matches Together: \(teammate.matchesPlayedTogether)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Win Rate: \(String(format: "%.1f%%", teammate.winRateTogether * 100))")
                Text("Synergy: \(String(format: "%.1f%%", teammate.synergyScore * 100))")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    NavigationView {
        PerformanceAnalysisView()
            .environmentObject(SteamViewModel())
    }
} 