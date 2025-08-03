// /Models/UserProfile.swift

import Foundation

struct UserProfile: Codable, Equatable {
    var name: String
    var email: String
    var mobile: String
    var emergencyContactName: String // NEW: Emergency contact name
    var emergencyContactMobile: String // NEW: Emergency contact mobile
    var isSetup: Bool
    let createdDate: Date
    var lastUpdated: Date
    
    init(name: String = "", email: String = "", mobile: String = "", emergencyContactName: String = "", emergencyContactMobile: String = "") {
        self.name = name
        self.email = email
        self.mobile = mobile
        self.emergencyContactName = emergencyContactName
        self.emergencyContactMobile = emergencyContactMobile
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
    
    // NEW: Emergency contact validation
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
    
    var isComplete: Bool {
        return hasValidName && hasValidEmail && hasValidMobile
    }
    
    // NEW: Check if profile is complete including emergency contact
    var isCompleteWithEmergencyContact: Bool {
        return isComplete && hasEmergencyContact
    }
    
    var displayName: String {
        return hasValidName ? name : "User"
    }
    
    // Update profile data
    mutating func update(name: String, email: String, mobile: String, emergencyContactName: String = "", emergencyContactMobile: String = "") {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.mobile = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        self.emergencyContactName = emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.emergencyContactMobile = emergencyContactMobile.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isSetup = hasValidName
        self.lastUpdated = Date()
    }
}
