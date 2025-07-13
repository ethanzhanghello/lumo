import SwiftUI

struct CreateAccountView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @Binding var navigationPath: NavigationPath
    
    @State private var fullName = ""
    @State private var confirmPassword = ""
    @State private var saveLoginInfo = true
    @State private var agreedToTerms = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Logo Image (above Welcome to Lumo)
                ZStack {
                    Image("Lumologotest") // Ensure the image asset is available in your project
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 150) // Adjust size as necessary
                        .shadow(color: Color.cyan.opacity(0.7), radius: 16) // Shadow effect
                        .padding(.bottom, 8)
                }
                .frame(width: 200, height: 90)

                // Header with "Welcome to Lumo"
                VStack {
                    Text("Welcome to")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Lumo as an image
                    Image("lumo") // Ensure this image asset is available in your project
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 50) // Adjusted size for "Lumo"
                }
                
                // Form section with white outlines and white text
                VStack(spacing: 20) {
                    TextField("Full name", text: $fullName) // Full name text field
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1)
                        )
                    
                    TextField("Email", text: $authViewModel.email)
                                            .padding()
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(8)
                                            .foregroundColor(.white)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                    
                    SecureField("Password", text: $authViewModel.password) // Password field
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1)
                        )
                    
                    SecureField("Confirm Password", text: $confirmPassword) // Confirm Password field
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                
                // Custom toggle buttons for "Save login info" and "Agree to Terms"
                VStack(spacing: 0) {
                    Toggle(isOn: $saveLoginInfo) {
                        Text("Save login info on this device")
                            .foregroundColor(.white)
                    }
                    .padding(.top, 10)
                    
                    Toggle(isOn: $agreedToTerms) {
                        Text("I agree to Terms & Privacy")
                            .foregroundColor(.white)
                    }
                    .padding(.top, 10)
                }
                .padding(.top, 10)
                
                // "Create an Account" button
                Button(action: {
                    Task {
                        await createAccount()
                    }
                }) {
                    Text("Create an Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#00F0C0"))
                        .foregroundColor(.black)
                        .font(.headline)
                        .cornerRadius(8)
                }
                .padding(.top, 12)
                
                // Show error if signup fails
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                
                // Link to "Already have an account?"
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.white)
                    Button("Login") {
                        // Navigate to login
                        navigationPath.append("Login")
                    }
                    .foregroundColor(Color(hex: "#00F0C0"))
                }
                .padding(.top, 16)
                
                
                // Extra spacing to ensure proper layout
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func createAccount() async {
        // Validate form
        guard !fullName.isEmpty else {
            authViewModel.errorMessage = "Please enter your full name"
            return
        }
        
        guard !authViewModel.email.isEmpty else {
            authViewModel.errorMessage = "Please enter your email"
            return
        }
        
        guard !authViewModel.password.isEmpty else {
            authViewModel.errorMessage = "Please enter a password"
            return
        }
        
        guard authViewModel.password == confirmPassword else {
            authViewModel.errorMessage = "Passwords do not match"
            return
        }
        
        guard agreedToTerms else {
            authViewModel.errorMessage = "Please agree to Terms & Privacy"
            return
        }
        
        // Attempt to sign up
        await authViewModel.signUp()
        
        // If successful, save profile and navigate to login
        if authViewModel.errorMessage == nil {
            await authViewModel.saveProfile(fullName: fullName)
            // Clear the navigation stack and go to login
            navigationPath.removeLast()
            navigationPath.append("Login")
        }
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView(navigationPath: .constant(NavigationPath()))
            .previewDevice("iPhone 12") // Choose your preferred device for previewing
            .preferredColorScheme(.dark) // Use dark mode for the preview
    }
}
