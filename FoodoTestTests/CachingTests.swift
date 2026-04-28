//
//  CachingTests.swift
//  FoodoTestTests
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import XCTest
import CoreData
@testable import FoodoTest

@MainActor
final class CachingTests: XCTestCase {

    private var persistence: PersistenceController!
    private var repository: ItemRepository!
    private var mockClient: MockAPIClient!

    override func setUp() {
        super.setUp()
        persistence = PersistenceController(inMemory: true)
        mockClient = MockAPIClient()
        repository = ItemRepository(
            apiClient: mockClient,
            persistence: persistence,
            networkMonitor: NetworkMonitor()
        )
    }

    // MARK: - TTL Cache Invalidation

    func test_isCacheStale_returnsTrueWhenEmpty() throws {
        XCTAssertTrue(try repository.isCacheStale())
    }

    func test_isCacheStale_returnsFalseAfterFresh() async throws {
        mockClient.stubbedItems = ModelItem.mockList
        try await repository.fetchAndCache()
        XCTAssertFalse(try repository.isCacheStale())
    }

    // MARK: - Upsert / Deduplication

    func test_fetchTwice_doesNotDuplicateItems() async throws {
        mockClient.stubbedItems = ModelItem.mockList
        try await repository.fetchAndCache()
        try await repository.fetchAndCache()

        let cached = try repository.cachedItems()
        let ids = cached.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Duplicate IDs found after double fetch")
        XCTAssertEqual(cached.count, ModelItem.mockList.count)
    }

    func test_cachePreservesAllFields() async throws {
        let item = ModelItem(
            id: "FULL1",
            title: "Full Item",
            status: .inProgress,
            detail: "All fields present",
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        mockClient.stubbedItems = [item]
        try await repository.fetchAndCache()

        let cached = try repository.cachedItems()
        let found  = try XCTUnwrap(cached.first)
        XCTAssertEqual(found.id,     item.id)
        XCTAssertEqual(found.title,  item.title)
        XCTAssertEqual(found.status, item.status)
        XCTAssertEqual(found.detail, item.detail)
        XCTAssertEqual(found.updatedAt.timeIntervalSince1970,
                       item.updatedAt.timeIntervalSince1970,
                       accuracy: 1.0)
    }

    // MARK: - Offline Fallback

    func test_offlineMode_returnsCachedDataWhenNetworkUnavailable() async throws {
        // Seed cache while "online"
        mockClient.stubbedItems = ModelItem.mockList
        try await repository.fetchAndCache()

        // Simulate offline: new repository with broken API
        let offlineClient = MockAPIClient()
        offlineClient.shouldThrow = APIError.timeout
        let offlineRepo = ItemRepository(
            apiClient: offlineClient,
            persistence: persistence,     // same in-memory store
            networkMonitor: NetworkMonitor()
        )

        // Despite API failure, cache should still be readable
        let cached = try offlineRepo.cachedItems()
        XCTAssertFalse(cached.isEmpty)
        XCTAssertEqual(cached.count, ModelItem.mockList.count)
    }
}
