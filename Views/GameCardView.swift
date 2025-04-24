import SwiftUI

struct GameCardView: View {
    let game: Game
    @State private var isPressed = false
    @EnvironmentObject var viewModel: SteamViewModel
    @State private var showCS2Stats = false
    
    private var hasWarning: Bool {
        viewModel.playtimeWarnings.contains { $0.gameName == game.name }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Game Icon
            AsyncImage(url: URL(string: "https://media.steampowered.com/steamcommunity/public/images/apps/\(game.appid)/\(game.img_icon_url).jpg")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.gray)
                    )
            }
            
            // Game Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(game.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if hasWarning {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                    }
                }
                
                // Playtime Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        Text(formatPlaytime(minutes: game.playtime_forever))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    if let recentPlaytime = game.playtime_2weeks {
                        Text("\(formatPlaytime(minutes: recentPlaytime)) past 2 weeks")
                            .font(.system(size: 12))
                            .foregroundColor(hasWarning ? .orange : .gray)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(hasWarning ? Color.orange.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            if game.name.lowercased().contains("counter-strike 2") {
                withAnimation {
                    isPressed = true
                    Task {
                        await viewModel.fetchCS2Stats(steamId: viewModel.lastSearchedId)
                        await viewModel.fetchPremierMatches(steamId: viewModel.lastSearchedId)
                        showCS2Stats = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
            } else {
                withAnimation {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCS2Stats) {
            CS2CombinedView(game: game, viewModel: viewModel)
        }
    }
    
    private func formatPlaytime(minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
} 