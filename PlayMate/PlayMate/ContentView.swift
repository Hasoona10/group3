//
//  ContentView.swift
//   PlayMate
//
//  Created by csuftitan on 3/23/25.
//

import SwiftUI

// Color definitions
let accentBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
let glassBackground = Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.8)

struct ContentView: View {
    @StateObject private var viewModel = SteamViewModel()
    @State private var searchText = ""
    @State private var selectedGame: Game?
    @State private var showingRecentSearches = false
    @Environment(\.colorScheme) var colorScheme
    
    // Custom colors
    private let gradientStart = Color(red: 0.07, green: 0.09, blue: 0.15)
    private let gradientEnd = Color(red: 0.12, green: 0.15, blue: 0.23)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [gradientStart, gradientEnd]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Steam Status Bar with refined glass effect
                    HStack(spacing: 12) {
                        // Status indicator with pulse animation
                        ZStack {
                            Circle()
                                .fill(viewModel.steamStatus.color.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .blur(radius: 4)
                            
                            Circle()
                                .fill(viewModel.steamStatus.color)
                                .frame(width: 8, height: 8)
                        }
                        
                        Text(viewModel.steamStatus.description)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(glassBackground)
                            
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    Text("Enter Your Steam ID")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    
                    // Enhanced Search Section with recent searches
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
                                        .fill(glassBackground)
                                    
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
                                                .fill(accentBlue)
                                            
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        }
                                    )
                                    .shadow(color: accentBlue.opacity(0.5), radius: 8, y: 4)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        
                        if !viewModel.recentSearches.isEmpty {
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
                                                            .fill(glassBackground)
                                                    )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        LoadingView()
                    }
                    
                    if let error = viewModel.error {
                        ErrorView(message: error)
                    }
                    
                    // Games List with improved scrolling
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.recentGames) { game in
                                if game.name == "Counter-Strike 2" {
                                    GameCardView(game: game, viewModel: viewModel)
                                        .onTapGesture {
                                            Task {
                                                await viewModel.fetchPremierMatches(steamId: viewModel.lastSearchedId)
                                            }
                                        }
                                        .sheet(isPresented: $viewModel.isPremierMatchesViewPresented) {
                                            PremierMatchesView(viewModel: viewModel)
                                        }
                                } else {
                                    GameCardView(game: game, viewModel: viewModel)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.recentGames)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.isHighlightViewPresented) {
                if let highlight = viewModel.selectedHighlight {
                    CS2HighlightView(highlight: highlight)
                }
            }
            .sheet(isPresented: $viewModel.isCS2StatsViewPresented) {
                if let game = viewModel.recentGames.first(where: { $0.name.lowercased().contains("counter-strike 2") }) {
                    CS2StatsView(viewModel: viewModel)
                }
            }
        }
        .onAppear {
            viewModel.requestNotificationPermission()
            if !viewModel.lastSearchedId.isEmpty {
                searchText = viewModel.lastSearchedId
                Task {
                    await viewModel.fetchProfile(username: viewModel.lastSearchedId)
                }
            }
        }
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

struct CS2HighlightView: View {
    let highlight: CS2Highlight
    @Environment(\.dismiss) private var dismiss
    @State private var isAnimating = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("CS2 Highlights")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            
            // Highlight Content
            if highlight.id == "sample" || highlight.id == "error" {
                // Placeholder Animation
                VStack(spacing: 20) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 60))
                        .foregroundColor(accentBlue)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 2)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    Text(highlight.description)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Animated Loading Dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(accentBlue)
                                .frame(width: 8, height: 8)
                                .opacity(isAnimating ? 1 : 0.3)
                                .animation(
                                    Animation.easeInOut(duration: 0.6)
                                        .repeatForever()
                                        .delay(0.2 * Double(index)),
                                    value: isAnimating
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(accentBlue.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                // Actual Highlight Content
                if let thumbnailUrl = highlight.thumbnailUrl {
                    AsyncImage(url: URL(string: thumbnailUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 200)
                            .overlay(ProgressView())
                    }
                }
            }
            
            // Highlight Details
            VStack(alignment: .leading, spacing: 8) {
                Text(highlight.description)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Label("Round \(highlight.roundNumber)", systemImage: "number")
                    Spacer()
                    Label(dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(highlight.timestamp))), systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                Button(action: {
                    // Save highlight
                }) {
                    Label("Save Highlight", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(accentBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                if let videoUrl = highlight.videoUrl {
                    Link(destination: URL(string: videoUrl)!) {
                        Label("Watch Video", systemImage: "play.circle")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(glassBackground)
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            }
        )
        .padding()
        .onAppear {
            isAnimating = true
        }
    }
}

struct GameCardView: View {
    let game: Game
    @State private var isPressed = false
    @ObservedObject var viewModel: SteamViewModel
    
    private var hasWarning: Bool {
        viewModel.playtimeWarnings.contains { $0.gameName == game.name }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Game Icon with enhanced shadow
            AsyncImage(url: URL(string: "https://media.steampowered.com/steamcommunity/public/images/apps/\(game.appid)/\(game.img_icon_url).jpg")) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.1), radius: 4)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(game.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if hasWarning {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 14))
                    }
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(formatPlaytime(minutes: game.playtime_forever))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    if let recentPlaytime = game.playtime_2weeks {
                        Text("(\(formatPlaytime(minutes: recentPlaytime)) past 2 weeks)")
                            .font(.system(size: 12))
                            .foregroundColor(hasWarning ? .orange : .gray)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding()
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(hasWarning ? Color.orange.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
            }
            .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            if game.name.lowercased().contains("counter-strike 2") {
                Task {
                    await viewModel.fetchPremierMatches(steamId: viewModel.lastSearchedId)
                    viewModel.isPremierMatchesViewPresented = true
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
    }
    
    private func formatPlaytime(minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m"
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Helper view extension for placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    ContentView()
}
