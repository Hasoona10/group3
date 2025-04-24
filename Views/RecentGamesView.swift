import SwiftUI

struct RecentGamesView: View {
    let games: [Game]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Games")
                .font(.title2)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(games) { game in
                        GameCard(game: game)
                    }
                }
                .padding(.horizontal, 5)
            }
        }
    }
}

struct GameCard: View {
    let game: Game
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Game Icon
            AsyncImage(url: URL(string: "https://media.steampowered.com/steamcommunity/public/images/apps/\(game.appid)/\(game.img_icon_url).jpg")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: 160, height: 160)
            .cornerRadius(12)
            
            // Game Name
            Text(game.name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            
            // Playtime
            VStack(alignment: .leading, spacing: 4) {
                Text("Total: \(formatPlaytime(game.playtime_forever))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if let recent = game.playtime_2weeks {
                    Text("Recent: \(formatPlaytime(recent))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: 160)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func formatPlaytime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
}

#Preview {
    RecentGamesView(games: [
        Game(appid: 730, name: "Counter-Strike 2", playtime_2weeks: 120, playtime_forever: 1000, img_icon_url: "icon", img_logo_url: nil, last_played: nil),
        Game(appid: 570, name: "Dota 2", playtime_2weeks: 60, playtime_forever: 2000, img_icon_url: "icon", img_logo_url: nil, last_played: nil)
    ])
} 