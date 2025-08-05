// /Models/UserProfile.swift

import Foundation

struct UserProfile: Codable, Equatable {
    var name: String
    var email: String
    var mobile: String
    var emergencyContactName: String
    var emergencyContactMobile: String
    var showEmergencyButton: Bool // NEW: Toggle for showing emergency button on main screen
    var isSetup: Bool
    let createdDate: Date
    var lastUpdated: Date
    
    init(name: String = "", email: String = "", mobile: String = "", emergencyContactName: String = "", emergencyContactMobile: String = "", showEmergencyButton: Bool = true) {
        self.name = name
        self.email = email
        self.mobile = mobile
        self.emergencyContactName = emergencyContactName
        self.emergencyContactMobile = emergencyContactMobile
        self.showEmergencyButton = showEmergencyButton
        self.isSetup = !name.isEmpty
        self.createdDate = Date()
        self.lastUpdated = Date()
    }
    
    // Helper computed properties
    var hasValidName: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    var hasValidMobile: Bool {
        let cleaned = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count >= 10 && cleaned.allSatisfy { $0.isNumber || $0 == "+" || $0 == "-" || $0 == " " || $0 == "(" || $0 == ")" }
    }
    
    // Emergency contact validation
    var hasValidEmergencyContactName: Bool {
        return !emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasValidEmergencyContactMobile: Bool {
        let cleaned = emergencyContactMobile.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count >= 10 && cleaned.allSatisfy { $0.isNumber || $0 == "+" || $0 == "-" || $0 == " " || $0 == "(" || $0 == ")" }
    }
    
    var hasEmergencyContact: Bool {
        return hasValidEmergencyContactName && hasValidEmergencyContactMobile
    }
    
    // NEW: Check if emergency button should be shown (has contact AND toggle is enabled)
    var shouldShowEmergencyButton: Bool {
        return hasEmergencyContact && showEmergencyButton
    }
    
    var isComplete: Bool {
        return hasValidName && hasValidEmail && hasValidMobile
    }
    
    var isCompleteWithEmergencyContact: Bool {
        return isComplete && hasEmergencyContact
    }
    
    var displayName: String {
        return hasValidName ? name : "User"
    }
    
    // Update profile data - UPDATED to include showEmergencyButton parameter
    mutating func update(name: String, email: String, mobile: String, emergencyContactName: String = "", emergencyContactMobile: String = "", showEmergencyButton: Bool = true) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.mobile = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        self.emergencyContactName = emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.emergencyContactMobile = emergencyContactMobile.trimmingCharacters(in: .whitespacesAndNewlines)
        self.showEmergencyButton = showEmergencyButton
        self.isSetup = hasValidName
        self.lastUpdated = Date()
    }
    
    // NEW: Update just the emergency button toggle
    mutating func updateEmergencyButtonVisibility(_ show: Bool) {
        self.showEmergencyButton = show
        self.lastUpdated = Date()
    }
}
