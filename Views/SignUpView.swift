import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var steamViewModel: SteamViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var steamId = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showVerificationSent = false
    @State private var navigateToGames = false
    
    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !steamId.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 8
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 50)
                        
                        // Form
                        VStack(spacing: 15) {
                            // Username
                            TextField("Username", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            
                            // Email
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                            
                            // Steam ID
                            TextField("Steam ID", text: $steamId)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                            
                            // Password
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            // Confirm Password
                            SecureField("Confirm Password", text: $confirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            // Password requirements
                            if !password.isEmpty {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Password must:")
                                        .foregroundColor(.gray)
                                    Text("• Be at least 8 characters")
                                        .foregroundColor(password.count >= 8 ? .green : .red)
                                    Text("• Match confirmation")
                                        .foregroundColor(password == confirmPassword ? .green : .red)
                                }
                                .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Sign Up Button
                        Button(action: signUp) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? Color.blue : Color.gray)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.horizontal)
                        
                        // Back to Sign In
                        Button("Already have an account? Sign In") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 30)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Verification Email Sent", isPresented: $showVerificationSent) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please check your email to verify your account.")
            }
            .navigationDestination(isPresented: $navigateToGames) {
                GamesListView()
            }
        }
    }
    
    private func signUp() {
        isLoading = true
        
        Task {
            do {
                try await steamViewModel.signUp(
                    username: username,
                    email: email,
                    steamId: steamId,
                    password: password
                )
                
                await MainActor.run {
                    showVerificationSent = true
                    navigateToGames = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(SteamViewModel())
} 