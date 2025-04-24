import SwiftUI

struct GamesListView: View {
    @EnvironmentObject private var steamViewModel: SteamViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGame: Game?
    @State private var showGameDetails = false
    @State private var showPlayerStats = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.06, green: 0.06, blue: 0.12),
                        Color(red: 0.02, green: 0.02, blue: 0.04)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        profileSection
                        serverStatusBanner
                        gamesList
                    }
                    .padding(.top, 16)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Your Games")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    if let profile = steamViewModel.steamProfile {
                        await steamViewModel.fetchRecentGames(steamId: profile.steamid)
                    }
                }
            }
            .sheet(isPresented: $showGameDetails) {
                if let game = selectedGame {
                    GameDetailView(game: game)
                }
            }
            .sheet(isPresented: $showPlayerStats) {
                if let userId = steamViewModel.currentUser?.id {
                    PlayerStatsView(userId: userId)
                }
            }
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        Group {
            if let profile = steamViewModel.steamProfile {
                HStack(spacing: 15) {
                    // Profile Image
                    profileImage(url: profile.avatarfull)
                    
                    // Profile Info
                    profileInfo(profile: profile)
                    
                    Spacer()
                    
                    // Sign Out Button
                    signOutButton
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func profileImage(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.gray.opacity(0.3)
        }
        .frame(width: 60, height: 60)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
        )
    }
    
    private func profileInfo(profile: SteamProfile) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(profile.personaname)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let realName = profile.realname {
                Text(realName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var signOutButton: some View {
        Button(action: {
            steamViewModel.signOut()
            // Navigate back to SignInView
            dismiss()
        }) {
            Text("Sign Out")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red.opacity(0.8))
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                )
        }
    }
    
    // MARK: - Server Status Banner
    private var serverStatusBanner: some View {
        HStack(spacing: 12) {
            // Status Icon
            Circle()
                .fill(steamViewModel.steamStatus.color)
                .frame(width: 8, height: 8)
            
            // Status Text
            Text(steamViewModel.steamStatus.description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            if steamViewModel.steamStatus == .online {
                // Player Count (only show when servers are online)
                Text("1.2M Players")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.15))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Games List
    private var gamesList: some View {
        VStack(alignment: .leading, spacing: 24) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(steamViewModel.recentGames) { game in
                    GameCardView(game: game)
                        .environmentObject(steamViewModel)
                        .onTapGesture {
                            selectedGame = game
                            showGameDetails = true
                            if game.name == "Counter-Strike 2" {
                                Task {
                                    await steamViewModel.fetchCS2Stats(steamId: steamViewModel.steamProfile?.steamid ?? "")
                                }
                            }
                        }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
    }
}

#Preview {
    NavigationView {
        GamesListView()
            .environmentObject(SteamViewModel())
    }
} 