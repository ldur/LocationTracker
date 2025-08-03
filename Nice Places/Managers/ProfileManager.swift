// /Managers/ProfileManager.swift

import Foundation
import SwiftUI

@Observable
class ProfileManager {
    private let userDefaults = UserDefaults.standard
    private let userProfileKey = "UserProfile"
    
    var userProfile: UserProfile
    
    init() {
        self.userProfile = UserProfile()
        loadUserProfile()
    }
    
    // MARK: - Profile Management
    func updateProfile(name: String, email: String, mobile: String, emergencyContactName: String = "", emergencyContactMobile: String = "") {
        userProfile.update(name: name, email: email, mobile: mobile, emergencyContactName: emergencyContactName, emergencyContactMobile: emergencyContactMobile)
        saveProfile()
    }
    
    func clearProfile() {
        userProfile = UserProfile()
        saveProfile()
    }
    
    // MARK: - Persistence
    private func saveProfile() {
        if let encoded = try? JSONEncoder().encode(userProfile) {
            userDefaults.set(encoded, forKey: userProfileKey)
        }
    }
    
    private func loadUserProfile() {
        if let data = userDefaults.data(forKey: userProfileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = decoded
        }
    }
    
    // MARK: - Utility Methods
    func getDisplayName() -> String {
        return userProfile.displayName
    }
    
    func getShareName() -> String {
        // Return the user's name if available, otherwise extract from device
        if userProfile.hasValidName {
            return userProfile.name
        } else {
            return extractUserNameFromDevice()
        }
    }
    
    private func extractUserNameFromDevice() -> String {
        let deviceName = UIDevice.current.name
        let commonSuffixes = ["'s iPhone", "'s iPad", "'s iPod", " iPhone", " iPad", " iPod"]
        var name = deviceName
        
        for suffix in commonSuffixes {
            if name.hasSuffix(suffix) {
                name = String(name.dropLast(suffix.count))
                break
            }
        }
        
        if name.isEmpty || name.lowercased().contains("iphone") || name.lowercased().contains("ipad") {
            return "Someone"
        }
        
        return name
    }
    
    func isProfileComplete() -> Bool {
        return userProfile.isComplete
    }
    
    func isProfileSetup() -> Bool {
        return userProfile.isSetup
    }
    
    // NEW: Emergency contact methods
    func hasEmergencyContact() -> Bool {
        return userProfile.hasEmergencyContact
    }
    
    func getEmergencyContactName() -> String {
        return userProfile.emergencyContactName
    }
    
    func getEmergencyContactMobile() -> String {
        return userProfile.emergencyContactMobile
    }
    
    func isCompleteWithEmergencyContact() -> Bool {
        return userProfile.isCompleteWithEmergencyContact
    }
}
