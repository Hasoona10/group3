import SwiftUI

struct PremierMatchesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SteamViewModel
    
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.premierMatches) { match in
                            MatchCard(match: match)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Premier Matches")
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

struct MatchCard: View {
    let match: PremierMatch
    
    private var resultColor: Color {
        match.result == "Victory" ? .green : .red
    }
    
    private var formattedDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(match.timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with map and result
            HStack {
                Text(match.map)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(match.result)
                    .font(.headline)
                    .foregroundColor(resultColor)
            }
            
            // Score
            Text(match.score)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            // Stats
            HStack(spacing: 20) {
                StatView(value: match.kills, label: "K", color: .green)
                StatView(value: match.deaths, label: "D", color: .red)
                StatView(value: match.assists, label: "A", color: .blue)
                StatView(value: match.headshots, label: "HS", color: .yellow)
                StatView(value: match.damage, label: "DMG", color: .purple)
            }
            
            // Footer with date and MVP
            HStack {
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                if match.mvp {
                    Text("MVP")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(resultColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct StatView: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    PremierMatchesView(viewModel: SteamViewModel())
} 