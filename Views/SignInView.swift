import SwiftUI

// Remove duplicate color definitions
// private let darkBackground = Color(red: 0.07, green: 0.09, blue: 0.15)
// private let accentBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
// private let glassBackground = Color(red: 0.1, green: 0.1, blue: 0.2).opacity(0.8)

struct UserAvatarButton: View {
    let user: User
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                AsyncImage(url: URL(string: user.avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 2))
                
                Text(user.username)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 80)
        }
    }
}

struct SignInView: View {
    @EnvironmentObject var steamViewModel: SteamViewModel
    @State private var steamId: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToGames = false
    @State private var showSignUp = false
    @State private var showSteamIdInput = false
    @State private var newSteamId: String = ""
    
    // Break down the background elements into separate views
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.2, blue: 0.3)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private var ambientGlow: some View {
        ZStack {
            // CT Side Glow
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: -150, y: -100)
            
            // T Side Glow
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 300, height: 300)
                .blur(radius: 50)
                .offset(x: 150, y: 100)
        }
    }
    
    private var weaponOutlines: some View {
        ZStack {
            // M4A4 (CT Side)
            Path { path in
                path.move(to: CGPoint(x: 50, y: 200))
                path.addLine(to: CGPoint(x: 150, y: 200))
                path.addLine(to: CGPoint(x: 150, y: 220))
                path.addLine(to: CGPoint(x: 50, y: 220))
                path.closeSubpath()
            }
            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            .offset(x: -100, y: 0)
            
            // AK-47 (T Side)
            Path { path in
                path.move(to: CGPoint(x: 50, y: 200))
                path.addLine(to: CGPoint(x: 150, y: 200))
                path.addLine(to: CGPoint(x: 150, y: 220))
                path.addLine(to: CGPoint(x: 50, y: 220))
                path.closeSubpath()
            }
            .stroke(Color.orange.opacity(0.3), lineWidth: 2)
            .offset(x: 100, y: 0)
        }
    }
    
    private var bulletTraces: some View {
        ZStack {
            ForEach(0..<5) { i in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: CGFloat(i * 50)))
                    path.addLine(to: CGPoint(x: 400, y: CGFloat(i * 50 + 20)))
                }
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .offset(x: CGFloat(i * 20), y: 0)
            }
        }
    }
    
    private var siteMarkers: some View {
        ZStack {
            Text("A")
                .foregroundColor(.white.opacity(0.3))
                .font(.title)
                .offset(x: -150, y: -100)
            
            Text("B")
                .foregroundColor(.white.opacity(0.3))
                .font(.title)
                .offset(x: 150, y: 100)
        }
    }
    
    private var crosshair: some View {
        Circle()
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
            .frame(width: 20, height: 20)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.2, blue: 0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Decorative elements
                ambientGlow
                weaponOutlines
                bulletTraces
                siteMarkers
                crosshair
                
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 10)
                    
                    // Logo and Title Section
                    VStack(spacing: 15) {
                        Text("PLAYMATE")
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundColor(.white)
                            .tracking(5)
                            .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        Text("CS2 GAME COMPANION")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.blue)
                            .tracking(4)
                            .shadow(color: Color.blue.opacity(0.5), radius: 5, x: 0, y: 0)
                    }
                    .padding(.top, -50)
                    
                    Spacer()
                        .frame(height: 120)
                    
                    // Previous Users Section
                    if !steamViewModel.users.isEmpty {
                        VStack(alignment: .center, spacing: 15) {
                            Text("Previous Users")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(steamViewModel.users, id: \.id) { user in
                                        UserAvatarButton(user: user) {
                                            Task {
                                                do {
                                                    steamViewModel.steamId = user.steamId
                                                    try await steamViewModel.authenticateWithSteam()
                                                    navigateToGames = true
                                                } catch {
                                                    errorMessage = error.localizedDescription
                                                    showError = true
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Continue with Steam button
                    Button(action: {
                        Task {
                            do {
                                try await steamViewModel.authenticateWithSteam()
                                navigateToGames = true
                            } catch {
                                if let steamError = error as? SteamError {
                                    errorMessage = steamError.errorDescription ?? "An error occurred"
                                } else {
                                    errorMessage = error.localizedDescription
                                }
                                showError = true
                            }
                        }
                    }) {
                        HStack {
                            if steamViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "steam.logo")
                                    .font(.title2)
                                Text(steamViewModel.users.first?.username != nil ? "Continue with \(steamViewModel.users.first!.username)" : "Continue with Steam")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                    }
                    .disabled(steamViewModel.isLoading)
                    
                    // Sign in with different account button
                    Button(action: {
                        showSteamIdInput = true
                    }) {
                        Text("Sign in with different account")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 5)
                    .sheet(isPresented: $showSteamIdInput) {
                        VStack(spacing: 20) {
                            Text("Enter Steam ID")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            TextField("Steam ID", text: $newSteamId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                            
                            Button(action: {
                                Task {
                                    do {
                                        steamViewModel.steamId = newSteamId
                                        try await steamViewModel.authenticateWithSteam()
                                        showSteamIdInput = false
                                        navigateToGames = true
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showError = true
                                    }
                                }
                            }) {
                                Text("Sign In")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            
                            Button(action: {
                                showSteamIdInput = false
                            }) {
                                Text("Cancel")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(Color(red: 0.1, green: 0.1, blue: 0.2))
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 40)
                
                // Loading overlay
                if steamViewModel.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Connecting to Steam...")
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationDestination(isPresented: $navigateToGames) {
                GamesListView()
            }
            .onAppear {
                // Check if user is already authenticated
                if steamViewModel.isAuthenticated {
                    navigateToGames = true
                }
            }
            .onChange(of: steamViewModel.isAuthenticated) { oldValue, newValue in
                if newValue {
                    navigateToGames = true
                }
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(SteamViewModel())
} 
