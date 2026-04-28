//
//  LiveEvent.swift
//  TestApp
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import Foundation
import SwiftUI

// MARK: - Live Event
struct LiveEvent: Codable {
    let type: EventType
    let item: ModelItem
}

enum EventType: String, Codable {
    case created = "created"
    case updated = "updated"
    case cancelled = "cancelled"
    case deleted = "deleted"
}
