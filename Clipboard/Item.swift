//
//  Item.swift
//  Clipboard
//
//  Created by 鲁成龙 on 6.05.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var content: String
    
    init(timestamp: Date, content: String) {
        self.timestamp = timestamp
        self.content = content
    }
}
