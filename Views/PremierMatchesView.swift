import SwiftUI

struct PremierMatchesView: View {
    let matches: [PremierMatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent CS2 Matches")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(matches) { match in
                        MatchCard(match: match)
                            .frame(width: 200)
                    }
                }
                .padding(.horizontal, 5)
            }
        }
    }
}

struct MatchStatView: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    PremierMatchesView(matches: [
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
    ])
} 
