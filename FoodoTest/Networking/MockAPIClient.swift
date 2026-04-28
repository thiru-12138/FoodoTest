//
//  MockAPIClient.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import Foundation

final class MockAPIClient: APIClientProtocol {

    var stubbedItems: [ModelItem] = ModelItem.mockList
    var shouldThrow: Error?

    func fetchItems() async throws -> [ModelItem] {
        if let error = shouldThrow { throw error }
        return stubbedItems
    }
}

// MARK: - Mock Data Factory
extension ModelItem {
    static let mockList: [ModelItem] = [
        ModelItem(id: "A001",
                  title: "Alpha Task",
                  status: .new,
                  detail: "First sample item.",
                  updatedAt: Date().addingTimeInterval(-3600)),
        ModelItem(id: "B002",
                  title: "Beta Task",
                  status: .inProgress,
                  detail: "Work in progress.",
                  updatedAt: Date().addingTimeInterval(-1800)),
        ModelItem(id: "C003",
                  title: "Gamma Task",
                  status: .done,
                  detail: "Completed successfully.",
                  updatedAt: Date().addingTimeInterval(-900)),
        ModelItem(id: "D004",
                  title: "Delta Task",
                  status: .cancelled,
                  detail: "No longer needed.",
                  updatedAt: Date().addingTimeInterval(-7200)),
    ]
}
