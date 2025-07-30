//
//  Item.swift
//  Nice Places
//
//  Created by Lasse Durucz on 30/07/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
