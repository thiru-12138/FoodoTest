//
//  RepositoryTests.swift
//  FoodoTestTests
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import XCTest
import CoreData
@testable import FoodoTest

@MainActor
final class RepositoryTests: XCTestCase {

    private var repository: ItemRepository!
    private var mockClient: MockAPIClient!
    private var persistence: PersistenceController!
    private var networkMonitor: NetworkMonitor!

    override func setUp() {
        super.setUp()
        mockClient = MockAPIClient()
        persistence = PersistenceController(inMemory: true)
        networkMonitor = NetworkMonitor()
        repository = ItemRepository(
            apiClient: mockClient,
            persistence: persistence,
            networkMonitor: networkMonitor
        )
    }

    override func tearDown() {
        repository = nil
        mockClient = nil
        persistence = nil
        networkMonitor = nil
        super.tearDown()
    }

    // MARK: - Parsing Tests

    func test_fetchAndCache_parsesItemsSuccessfully() async throws {
        mockClient.stubbedItems = ModelItem.mockList
        try await repository.fetchAndCache()

        let cached = try repository.cachedItems()
        XCTAssertEqual(cached.count, ModelItem.mockList.count)
    }

    func test_fetchAndCache_throwsOnAPIError() async {
        mockClient.shouldThrow = APIError.httpError(500)

        do {
            try await repository.fetchAndCache()
            XCTFail("Expected error to be thrown")
        } catch APIError.httpError(let code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func test_fetchAndCache_throwsOnDecodingError() async {
        let decodingError = DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "bad JSON"))
        mockClient.shouldThrow = APIError.decodingError(decodingError)

        do {
            try await repository.fetchAndCache()
            XCTFail("Expected decoding error")
        } catch APIError.decodingError {
            // pass
        } catch {
            XCTFail("Wrong error: \(error)")
        }
    }

    // MARK: - Caching Tests

    func test_cachedItems_returnsPreviouslyFetchedItems() async throws {
        mockClient.stubbedItems = [
            ModelItem(id: "X1", title: "Test", status: .new,
                 detail: "d", updatedAt: Date())
        ]
        try await repository.fetchAndCache()
        let cached = try repository.cachedItems()
        XCTAssertEqual(cached.first?.id, "X1")
    }

    func test_cachedItems_returnsEmptyWhenNoCacheExists() throws {
        let cached = try repository.cachedItems()
        XCTAssertTrue(cached.isEmpty)
    }

    func test_fetchAndCache_survivesAppRestart() async throws {
        // Simulate restart by recreating repository with same persistence store
        mockClient.stubbedItems = ModelItem.mockList
        try await repository.fetchAndCache()

        let newRepository = ItemRepository(
            apiClient: MockAPIClient(),
            persistence: persistence,   // same in-memory store
            networkMonitor: networkMonitor
        )
        let cached = try newRepository.cachedItems()
        XCTAssertFalse(cached.isEmpty)
    }

    // MARK: - Merge / Update Tests

    func test_applyEvent_updatesExistingItem() async throws {
        // Seed initial data
        mockClient.stubbedItems = ModelItem.mockList
        try await repository.fetchAndCache()

        let updatedItem = ModelItem(
            id: "A001",
            title: "Alpha Task — UPDATED",
            status: .done,
            detail: "Updated via event",
            updatedAt: Date()
        )
        let event = LiveEvent(type: .updated, item: updatedItem)
        try await repository.applyEvent(event)

        let cached = try repository.cachedItems()
        let found = cached.first(where: { $0.id == "A001" })
        XCTAssertEqual(found?.title, "Alpha Task — UPDATED")
        XCTAssertEqual(found?.status, .done)
    }

    func test_applyEvent_createsNewItem() async throws {
        let newItem = ModelItem(
            id: "NEW1", title: "Brand New", status: .new,
            detail: "Fresh", updatedAt: Date()
        )
        try await repository.applyEvent(LiveEvent(type: .created, item: newItem))

        let cached = try repository.cachedItems()
        XCTAssertTrue(cached.contains(where: { $0.id == "NEW1" }))
    }

    func test_applyEvent_deletesItem() async throws {
        mockClient.stubbedItems = ModelItem.mockList
        try await repository.fetchAndCache()

        let toDelete = ModelItem.mockList[0]
        try await repository.applyEvent(LiveEvent(type: .deleted, item: toDelete))

        let cached = try repository.cachedItems()
        XCTAssertFalse(cached.contains(where: { $0.id == toDelete.id }))
    }

    func test_mergeStrategy_doesNotDowngradeNewerItem() async throws {
        // Store a recent item
        let recent = ModelItem(id: "M1", title: "Recent", status: .done,
                          detail: "d", updatedAt: Date())
        try await repository.applyEvent(LiveEvent(type: .created, item: recent))

        // Try applying an older event for same ID
        let older = ModelItem(id: "M1", title: "Old Title", status: .new,
                         detail: "old", updatedAt: Date().addingTimeInterval(-9999))
        try await repository.applyEvent(LiveEvent(type: .updated, item: older))

        let cached = try repository.cachedItems()
        let found  = cached.first(where: { $0.id == "M1" })
        XCTAssertEqual(found?.title, "Recent")   // not overwritten
        XCTAssertEqual(found?.status, .done)
    }
}
