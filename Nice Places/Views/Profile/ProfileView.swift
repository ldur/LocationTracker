// /Views/Profile/ProfileView.swift

import SwiftUI

struct ProfileView: View {
    @Bindable var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var mobile: String = ""
    @State private var showingClearAlert = false
    @State private var hasChanges = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, mobile
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Spotify background
                LinearGradient(
                    colors: [Color.spotifyDarkGray, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header Section
                        VStack(spacing: 16) {
                            // Profile Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.spotifyGreen, Color.spotifyGreen.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                if profileManager.userProfile.hasValidName {
                                    Text(String(profileManager.userProfile.name.prefix(1)).uppercased())
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.black)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.black)
                                }
                            }
                            
                            VStack(spacing: 8) {
                                Text("Your Profile")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                if profileManager.isProfileSetup() {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.spotifyGreen)
                                        
                                        Text("Profile Active")
                                            .font(.subheadline)
                                            .foregroundColor(.spotifyGreen)
                                    }
                                } else {
                                    Text("Complete your profile to personalize sharing")
                                        .font(.subheadline)
                                        .foregroundColor(.spotifyTextGray)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Form Section
                        VStack(spacing: 24) {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Full Name")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("*")
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                    
                                    if !name.isEmpty && !isValidName(name) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    } else if !name.isEmpty && isValidName(name) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.spotifyGreen)
                                    }
                                }
                                
                                TextField("Your full name", text: $name)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.spotifyLightGray)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        focusedField == .name ? Color.spotifyGreen : Color.clear,
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                                    .focused($focusedField, equals: .name)
                                    .textContentType(.name)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .email
                                    }
                                    .onChange(of: name) { _, _ in
                                        hasChanges = true
                                    }
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Email Address")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("*")
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                    
                                    if !email.isEmpty && !isValidEmail(email) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    } else if !email.isEmpty && isValidEmail(email) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.spotifyGreen)
                                    }
                                }
                                
                                TextField("your.email@example.com", text: $email)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.spotifyLightGray)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        focusedField == .email ? Color.spotifyGreen : Color.clear,
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                                    .focused($focusedField, equals: .email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .submitLabel(.next)
                                    .onSubmit {
                                        focusedField = .mobile
                                    }
                                    .onChange(of: email) { _, _ in
                                        hasChanges = true
                                    }
                            }
                            
                            // Mobile Field
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Mobile Number")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text("*")
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                    
                                    if !mobile.isEmpty && !isValidMobile(mobile) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    } else if !mobile.isEmpty && isValidMobile(mobile) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.spotifyGreen)
                                    }
                                }
                                
                                TextField("+1 234 567 8900", text: $mobile)
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.spotifyLightGray)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        focusedField == .mobile ? Color.spotifyGreen : Color.clear,
                                                        lineWidth: 1
                                                    )
                                            )
                                    )
                                    .focused($focusedField, equals: .mobile)
                                    .textContentType(.telephoneNumber)
                                    .keyboardType(.phonePad)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        focusedField = nil
                                    }
                                    .onChange(of: mobile) { _, _ in
                                        hasChanges = true
                                    }
                            }
                            
                            // Profile Status Card
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Profile Status")
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if isValidProfile() {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.spotifyGreen)
                                            Text("Complete")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.spotifyGreen)
                                        }
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                            Text("Incomplete")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Benefits of completing your profile:")
                                        .font(.caption)
                                        .foregroundColor(.spotifyTextGray)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "location.fill.viewfinder")
                                                .font(.caption2)
                                                .foregroundColor(.spotifyGreen)
                                            Text("Personalized location sharing messages")
                                                .font(.caption)
                                                .foregroundColor(.spotifyTextGray)
                                        }
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: "person.2.fill")
                                                .font(.caption2)
                                                .foregroundColor(.spotifyGreen)
                                            Text("Better identification when sharing locations")
                                                .font(.caption)
                                                .foregroundColor(.spotifyTextGray)
                                        }
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: "envelope.fill")
                                                .font(.caption2)
                                                .foregroundColor(.spotifyGreen)
                                            Text("Contact information for emergency sharing")
                                                .font(.caption)
                                                .foregroundColor(.spotifyTextGray)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.spotifyMediumGray.opacity(0.6))
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                            Text("Back")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: saveProfile) {
                            Label("Save Profile", systemImage: "checkmark")
                        }
                        .disabled(!hasValidProfile())
                        
                        if profileManager.isProfileSetup() {
                            Button(role: .destructive, action: {
                                showingClearAlert = true
                            }) {
                                Label("Clear Profile", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(.thinMaterial, for: .navigationBar)
        }
        .onAppear {
            loadProfileData()
        }
        .alert("Clear Profile", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearProfile()
            }
        } message: {
            Text("Are you sure you want to clear your profile? This action cannot be undone.")
        }
        
        // Floating Save Button
        .overlay(
            VStack {
                Spacer()
                
                if hasChanges && hasValidProfile() {
                    Button(action: saveProfile) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            
                            Text("Save Profile")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.spotifyGreen)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                }
            }
        )
    }
    
    // MARK: - Helper Functions
    private func loadProfileData() {
        name = profileManager.userProfile.name
        email = profileManager.userProfile.email
        mobile = profileManager.userProfile.mobile
        hasChanges = false
    }
    
    private func saveProfile() {
        profileManager.updateProfile(name: name, email: email, mobile: mobile)
        hasChanges = false
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func clearProfile() {
        profileManager.clearProfile()
        loadProfileData()
        hasChanges = false
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func isValidName(_ name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    private func isValidMobile(_ mobile: String) -> Bool {
        let cleaned = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count >= 10 && cleaned.allSatisfy { $0.isNumber || $0 == "+" || $0 == "-" || $0 == " " || $0 == "(" || $0 == ")" }
    }
    
    private func isValidProfile() -> Bool {
        return isValidName(name) && isValidEmail(email) && isValidMobile(mobile)
    }
    
    private func hasValidProfile() -> Bool {
        return isValidProfile() && hasChanges
    }
}

#Preview {
    ProfileView(profileManager: ProfileManager())
        .preferredColorScheme(.dark)
}
