//
//  ContentView.swift
//   PlayMate
//
//  Created by csuftitan on 3/23/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var steamViewModel = SteamViewModel()
    @State private var searchText = ""
    @State private var showCS2Stats = false
    @State private var showPremierMatches = false
    
    var body: some View {
        NavigationView {
            if !steamViewModel.isAuthenticated {
                SignInView()
                    .environmentObject(steamViewModel)
            } else {
                GamesListView()
                    .environmentObject(steamViewModel)
            }
        }
    }
}

struct ProfileHeader: View {
    let profile: SteamProfile
    
    var body: some View {
        VStack(spacing: 10) {
            AsyncImage(url: URL(string: profile.avatarfull)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            Text(profile.personaname)
                .font(.title2)
                .fontWeight(.bold)
            
            if let realName = profile.realname {
                Text(realName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Link("View Steam Profile", destination: URL(string: profile.profileurl)!)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

struct SteamStatusBarView: View {
    let steamStatus: SteamViewModel.SteamStatus
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(steamStatus.color.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .blur(radius: 4)
                
                Circle()
                    .fill(steamStatus.color)
                    .frame(width: 8, height: 8)
            }
            
            Text(steamStatus.description)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppColors.glassBackground)
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct SearchSectionView: View {
    @Binding var searchText: String
    @ObservedObject var viewModel: SteamViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField("", text: $searchText)
                        .placeholder(when: searchText.isEmpty) {
                            Text("Enter Steam ID or username")
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit {
                            Task {
                                await viewModel.fetchProfile(username: searchText)
                            }
                        }
                }
                .padding()
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.glassBackground)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button(action: {
                    Task {
                        await viewModel.fetchProfile(username: searchText)
                    }
                }) {
                    Text("Search")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.accentBlue)
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            }
                        )
                        .shadow(color: AppColors.accentBlue.opacity(0.5), radius: 8, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            if !viewModel.recentSearches.isEmpty {
                RecentSearchesView(viewModel: viewModel, searchText: $searchText)
            }
        }
        .padding(.horizontal)
    }
}

struct RecentSearchesView: View {
    @ObservedObject var viewModel: SteamViewModel
    @Binding var searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Searches")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: {
                    viewModel.clearRecentSearches()
                }) {
                    Text("Clear")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.recentSearches, id: \.self) { steamId in
                        Button(action: {
                            searchText = steamId
                            Task {
                                await viewModel.fetchProfile(username: steamId)
                            }
                        }) {
                            Text(steamId)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(AppColors.glassBackground)
                                )
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .opacity(isAnimating ? 0.3 : 1)
                .animation(.easeInOut(duration: 0.5).repeatForever().delay(0), value: isAnimating)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .opacity(isAnimating ? 0.3 : 1)
                .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.2), value: isAnimating)
            
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .opacity(isAnimating ? 0.3 : 1)
                .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.4), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// Error View
struct ErrorView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .foregroundColor(.red)
                .font(.system(size: 14, weight: .medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
        .padding(.horizontal)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
