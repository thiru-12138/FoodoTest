//
//  ModelItem.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import Foundation

// MARK: - Status Enum
enum ItemStatus: String, Codable, CaseIterable {
    case new = "new"
    case inProgress = "in_progress"
    case done = "done"
    case cancelled = "cancelled"

    var displayName: String {
        switch self {
        case .new: return "New"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        case .cancelled: return "Cancelled"
        }
    }

    var color: String {
        switch self {
        case .new: return "blue"
        case .inProgress: return "orange"
        case .done: return "green"
        case .cancelled: return "gray"
        }
    }
}

// MARK: - Domain Model
struct ModelItem: Identifiable, Equatable, Codable {
    let id: String
    var title: String
    var status: ItemStatus
    var detail: String
    var updatedAt: Date

    // MARK: Codable
    enum CodingKeys: String, CodingKey {
        case id, title, status, detail, updatedAt
    }

    init(id: String, title: String, status: ItemStatus, detail: String, updatedAt: Date) {
        self.id = id
        self.title = title
        self.status = status
        self.detail = detail
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        status = try c.decode(ItemStatus.self, forKey: .status)
        detail = try c.decode(String.self, forKey: .detail)

        let dateStr = try c.decode(String.self, forKey: .updatedAt)
        guard let date = ISO8601DateFormatter().date(from: dateStr) else {
            throw DecodingError.dataCorruptedError(
                forKey: .updatedAt, in: c,
                debugDescription: "Invalid ISO8601 date: \(dateStr)")
        }
        updatedAt = date
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(status, forKey: .status)
        try c.encode(detail, forKey: .detail)
        try c.encode(ISO8601DateFormatter().string(from: updatedAt), forKey: .updatedAt)
    }
}

// MARK: - Core Data Mapping
extension ModelItem {
    init?(entity: ItemEntity) {
        guard
            let id = entity.id,
            let title = entity.title,
            let statusRaw = entity.status,
            let status = ItemStatus(rawValue: statusRaw),
            let detail = entity.detail,
            let updatedAt = entity.updatedAt
        else { return nil }

        self.id = id
        self.title = title
        self.status = status
        self.detail = detail
        self.updatedAt = updatedAt
    }

    func apply(to entity: ItemEntity) {
        entity.id = id
        entity.title = title
        entity.status = status.rawValue
        entity.detail = detail
        entity.updatedAt = updatedAt
        entity.cachedAt  = Date()
    }
}
