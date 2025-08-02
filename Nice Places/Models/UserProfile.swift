// /Models/UserProfile.swift

import Foundation

struct UserProfile: Codable, Equatable {
    var name: String
    var email: String
    var mobile: String
    var isSetup: Bool
    let createdDate: Date
    var lastUpdated: Date
    
    init(name: String = "", email: String = "", mobile: String = "") {
        self.name = name
        self.email = email
        self.mobile = mobile
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
    
    var isComplete: Bool {
        return hasValidName && hasValidEmail && hasValidMobile
    }
    
    var displayName: String {
        return hasValidName ? name : "User"
    }
    
    // Update profile data
    mutating func update(name: String, email: String, mobile: String) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.mobile = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isSetup = hasValidName
        self.lastUpdated = Date()
    }
}
