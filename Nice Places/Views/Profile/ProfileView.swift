// /Views/Profile/ProfileView.swift

import SwiftUI
import Contacts

struct ProfileView: View {
    @Bindable var profileManager: ProfileManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var mobile: String = ""
    @State private var emergencyContactName: String = "" // NEW
    @State private var emergencyContactMobile: String = "" // NEW
    @State private var showingClearAlert = false
    @State private var hasChanges = false
    @State private var showingContactPicker = false // NEW: Contact picker state
    @State private var showingContactPermission = false // NEW: Permission sheet state
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, mobile, emergencyContactName, emergencyContactMobile // NEW: Added emergency contact fields
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
                        VStack(spacing: 32) {
                            // Personal Information Section
                            VStack(spacing: 24) {
                                // Section Header
                                HStack {
                                    Text("Personal Information")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if isValidPersonalInfo() {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.subheadline)
                                            .foregroundColor(.spotifyGreen)
                                    }
                                }
                                
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
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .emergencyContactName
                                        }
                                        .onChange(of: mobile) { _, _ in
                                            hasChanges = true
                                        }
                                }
                            }
                            
                            // NEW: Emergency Contact Section
                            VStack(spacing: 24) {
                                // Section Header with Contact Picker Button
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Emergency Contact")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("Optional")
                                            .font(.caption)
                                            .foregroundColor(.spotifyTextGray)
                                    }
                                    
                                    Spacer()
                                    
                                    // Select from Contacts Button
                                    Button(action: selectFromContacts) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "person.crop.circle")
                                                .font(.caption)
                                            Text("Select")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(.spotifyGreen)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.spotifyGreen.opacity(0.2))
                                        )
                                    }
                                    
                                    if isValidEmergencyContact() {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.subheadline)
                                            .foregroundColor(.spotifyGreen)
                                    }
                                }
                                
                                // Emergency Contact Name Field
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Emergency Contact Name")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        if !emergencyContactName.isEmpty && !isValidEmergencyContactName(emergencyContactName) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        } else if !emergencyContactName.isEmpty && isValidEmergencyContactName(emergencyContactName) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.spotifyGreen)
                                        }
                                    }
                                    
                                    TextField("Contact person's full name", text: $emergencyContactName)
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
                                                            focusedField == .emergencyContactName ? Color.spotifyGreen : Color.clear,
                                                            lineWidth: 1
                                                        )
                                                )
                                        )
                                        .focused($focusedField, equals: .emergencyContactName)
                                        .textContentType(.name)
                                        .submitLabel(.next)
                                        .onSubmit {
                                            focusedField = .emergencyContactMobile
                                        }
                                        .onChange(of: emergencyContactName) { _, newValue in
                                            print("📞 ProfileView: Emergency contact name changed to: '\(newValue)'")
                                            hasChanges = true
                                        }
                                }
                                
                                // Emergency Contact Mobile Field
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Emergency Contact Mobile")
                                            .font(.headline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        if !emergencyContactMobile.isEmpty && !isValidEmergencyContactMobile(emergencyContactMobile) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        } else if !emergencyContactMobile.isEmpty && isValidEmergencyContactMobile(emergencyContactMobile) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.spotifyGreen)
                                        }
                                    }
                                    
                                    TextField("+1 234 567 8900", text: $emergencyContactMobile)
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
                                                            focusedField == .emergencyContactMobile ? Color.spotifyGreen : Color.clear,
                                                            lineWidth: 1
                                                        )
                                                )
                                        )
                                        .focused($focusedField, equals: .emergencyContactMobile)
                                        .textContentType(.telephoneNumber)
                                        .keyboardType(.phonePad)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            focusedField = nil
                                        }
                                        .onChange(of: emergencyContactMobile) { _, newValue in
                                            print("📞 ProfileView: Emergency contact mobile changed to: '\(newValue)'")
                                            hasChanges = true
                                        }
                                }
                                
                                // Emergency Contact Info
                                VStack(spacing: 8) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        
                                        Text("About Emergency Contact")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        
                                        Spacer()
                                    }
                                    
                                    Text("This contact information may be used in emergency situations when sharing locations or in case of safety concerns. It's optional but recommended for safety.")
                                        .font(.caption)
                                        .foregroundColor(.spotifyTextGray)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                )
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
                                        
                                        // NEW: Emergency contact benefit
                                        if isValidEmergencyContact() {
                                            HStack(spacing: 8) {
                                                Image(systemName: "phone.fill")
                                                    .font(.caption2)
                                                    .foregroundColor(.spotifyGreen)
                                                Text("Emergency contact ready for safety features")
                                                    .font(.caption)
                                                    .foregroundColor(.spotifyTextGray)
                                            }
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
            print("📞 ProfileView: View appeared")
            loadProfileData()
        }
        .onDisappear {
            print("📞 ProfileView: View disappeared")
        }
        .alert("Clear Profile", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clearProfile()
            }
        } message: {
            Text("Are you sure you want to clear your profile? This action cannot be undone.")
        }
        // NEW: Contact picker sheets
        .sheet(isPresented: $showingContactPermission) {
            ContactPermissionSheet(
                onPermissionGranted: {
                    print("📞 ProfileView: Contact permission granted")
                    showingContactPermission = false
                    // Add delay before showing picker
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showingContactPicker = true
                    }
                },
                onDismiss: {
                    print("📞 ProfileView: Contact permission dismissed")
                    showingContactPermission = false
                }
            )
        }
        .sheet(isPresented: $showingContactPicker) {
            ContactPicker(
                onContactSelected: { name, phoneNumber in
                    print("📞 ProfileView: Contact callback received - Name: '\(name)', Phone: '\(phoneNumber)'")
                    
                    // Update the state immediately on main thread
                    self.emergencyContactName = name
                    self.emergencyContactMobile = phoneNumber
                    self.hasChanges = true
                    
                    print("📞 ProfileView: Emergency contact fields updated")
                    print("📞 ProfileView: emergencyContactName = '\(self.emergencyContactName)'")
                    print("📞 ProfileView: emergencyContactMobile = '\(self.emergencyContactMobile)'")
                    
                    // Dismiss the contact picker
                    self.showingContactPicker = false
                },
                onDismiss: {
                    print("📞 ProfileView: Contact picker dismissed without selection")
                    self.showingContactPicker = false
                }
            )
            .interactiveDismissDisabled(false) // Allow swipe to dismiss
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
        print("📞 ProfileView: Loading profile data")
        name = profileManager.userProfile.name
        email = profileManager.userProfile.email
        mobile = profileManager.userProfile.mobile
        emergencyContactName = profileManager.userProfile.emergencyContactName
        emergencyContactMobile = profileManager.userProfile.emergencyContactMobile
        hasChanges = false
        
        print("📞 ProfileView: Loaded emergency contact - Name: '\(emergencyContactName)', Mobile: '\(emergencyContactMobile)'")
    }
    
    // NEW: Contact picker functionality
    private func selectFromContacts() {
        // Dismiss keyboard first to prevent constraint conflicts
        focusedField = nil
        
        let contactsPermission = ContactPermissionHelper.checkContactsPermission()
        
        switch contactsPermission {
        case .authorized:
            // Add small delay to ensure keyboard is dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showingContactPicker = true
            }
        case .notDetermined, .denied, .restricted:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showingContactPermission = true
            }
        @unknown default:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showingContactPermission = true
            }
        }
    }
    
    private func saveProfile() {
        print("📞 ProfileView: Saving profile")
        print("📞 ProfileView: Emergency contact before save - Name: '\(emergencyContactName)', Mobile: '\(emergencyContactMobile)'")
        
        profileManager.updateProfile(
            name: name,
            email: email,
            mobile: mobile,
            emergencyContactName: emergencyContactName,
            emergencyContactMobile: emergencyContactMobile
        )
        hasChanges = false
        
        print("📞 ProfileView: Profile saved successfully")
        print("📞 ProfileView: Emergency contact after save - Name: '\(profileManager.userProfile.emergencyContactName)', Mobile: '\(profileManager.userProfile.emergencyContactMobile)'")
        
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
    
    // NEW: Emergency contact validation methods
    private func isValidEmergencyContactName(_ name: String) -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func isValidEmergencyContactMobile(_ mobile: String) -> Bool {
        let cleaned = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count >= 10 && cleaned.allSatisfy { $0.isNumber || $0 == "+" || $0 == "-" || $0 == " " || $0 == "(" || $0 == ")" }
    }
    
    private func isValidPersonalInfo() -> Bool {
        return isValidName(name) && isValidEmail(email) && isValidMobile(mobile)
    }
    
    private func isValidEmergencyContact() -> Bool {
        return isValidEmergencyContactName(emergencyContactName) && isValidEmergencyContactMobile(emergencyContactMobile)
    }
    
    private func isValidProfile() -> Bool {
        return isValidPersonalInfo() && hasChanges
    }
    
    private func hasValidProfile() -> Bool {
        return isValidProfile()
    }
}

#Preview {
    ProfileView(profileManager: ProfileManager())
        .preferredColorScheme(.dark)
}
