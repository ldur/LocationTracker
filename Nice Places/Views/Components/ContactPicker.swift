// /Views/Components/ContactPicker.swift

import SwiftUI
import ContactsUI
import Contacts

struct ContactPicker: UIViewControllerRepresentable {
    let onContactSelected: (String, String) -> Void // (name, phoneNumber)
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        
        // Only show contacts that have phone numbers
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        
        // Only display name and phone number properties
        picker.displayedPropertyKeys = [
            CNContactGivenNameKey,
            CNContactFamilyNameKey,
            CNContactPhoneNumbersKey
        ]
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPicker
        private var hasCompleted = false // Prevent multiple callbacks
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            guard !hasCompleted else {
                print("📞 ContactPicker: Already completed, ignoring duplicate callback")
                return
            }
            
            hasCompleted = true
            print("📞 ContactPicker: Contact selected")
            
            // Extract contact name
            let contactName = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
            print("📞 ContactPicker: Name extracted: '\(contactName)'")
            
            // Extract phone number (prefer mobile, fallback to first available)
            var phoneNumber = ""
            
            // Look for mobile numbers first
            let mobileNumbers = contact.phoneNumbers.filter { phoneNumberValue in
                let label = phoneNumberValue.label ?? ""
                return label.contains("mobile") || label.contains("cell") || label.contains("iPhone")
            }
            
            if let mobilePhone = mobileNumbers.first {
                phoneNumber = mobilePhone.value.stringValue
                print("📞 ContactPicker: Using mobile number: '\(phoneNumber)'")
            } else if let firstPhone = contact.phoneNumbers.first {
                // Fallback to first available phone number
                phoneNumber = firstPhone.value.stringValue
                print("📞 ContactPicker: Using first available number: '\(phoneNumber)'")
            }
            
            // Clean up phone number format
            phoneNumber = cleanPhoneNumber(phoneNumber)
            print("📞 ContactPicker: Cleaned phone number: '\(phoneNumber)'")
            
            // Store the callback data
            let finalName = contactName
            let finalPhone = phoneNumber
            
            // Let the picker dismiss naturally first, then call our callback
            // This prevents the CFMessagePort error by not competing with system dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("📞 ContactPicker: Executing delayed callback with name: '\(finalName)', phone: '\(finalPhone)'")
                self.parent.onContactSelected(finalName, finalPhone)
            }
        }
        
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            guard !hasCompleted else { return }
            hasCompleted = true
            
            print("📞 ContactPicker: User cancelled contact selection")
            
            // Small delay to prevent conflicts with system dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.parent.onDismiss()
            }
        }
        
        private func cleanPhoneNumber(_ phoneNumber: String) -> String {
            // Remove common formatting characters but keep + for international numbers
            var cleaned = phoneNumber.replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: " ", with: "")
            
            // If it starts with +1 and has 11 digits total, it's a US number
            if cleaned.hasPrefix("+1") && cleaned.count == 12 {
                return cleaned
            }
            // If it's a 10-digit US number without country code, add +1
            else if cleaned.count == 10 && cleaned.allSatisfy({ $0.isNumber }) {
                return "+1" + cleaned
            }
            // Otherwise return as-is (international numbers, etc.)
            else {
                return phoneNumber // Return original with formatting if we can't clean it safely
            }
        }
    }
}

// MARK: - Contact Permission Helper
struct ContactPermissionHelper {
    static func checkContactsPermission() -> CNAuthorizationStatus {
        return CNContactStore.authorizationStatus(for: .contacts)
    }
    
    static func requestContactsPermission() async -> Bool {
        let store = CNContactStore()
        
        do {
            let granted = try await store.requestAccess(for: .contacts)
            return granted
        } catch {
            print("📞 ContactPermissionHelper: Error requesting permission: \(error)")
            return false
        }
    }
    
    static func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Contact Permission Alert
struct ContactPermissionSheet: View {
    let onPermissionGranted: () -> Void
    let onDismiss: () -> Void
    
    @State private var permissionStatus: CNAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.spotifyDarkGray, Color.black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.spotifyGreen)
                    
                    Text("Contacts Access Needed")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("To select an emergency contact from your address book, we need access to your contacts.")
                        .font(.body)
                        .foregroundColor(.spotifyTextGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 16) {
                        if permissionStatus == .denied {
                            Button(action: ContactPermissionHelper.openSettings) {
                                Text("Open Settings")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 28)
                                            .fill(Color.spotifyGreen)
                                    )
                            }
                            .padding(.horizontal, 24)
                        } else {
                            Button(action: requestContactsPermission) {
                                Text("Allow Contacts Access")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 28)
                                            .fill(Color.spotifyGreen)
                                    )
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        Button("Not Now") {
                            onDismiss()
                        }
                        .font(.subheadline)
                        .foregroundColor(.spotifyTextGray)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            permissionStatus = ContactPermissionHelper.checkContactsPermission()
        }
    }
    
    private func requestContactsPermission() {
        Task {
            let granted = await ContactPermissionHelper.requestContactsPermission()
            await MainActor.run {
                if granted {
                    onPermissionGranted()
                } else {
                    permissionStatus = .denied
                }
            }
        }
    }
}

#Preview {
    ContactPermissionSheet(
        onPermissionGranted: {},
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
