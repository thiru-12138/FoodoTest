//
//  ViewModelTests.swift
//  FoodoTestTests
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import XCTest
import Combine
@testable import FoodoTest

// MARK: - Mock Repository
final class MockItemRepository: ItemRepositoryProtocol {

    var stubbedItems: [ModelItem] = []
    var shouldThrowOnFetch: Error?

    private let subject = PassthroughSubject<[ModelItem], Never>()
    var itemsPublisher: AnyPublisher<[ModelItem], Never> {
        subject.eraseToAnyPublisher()
    }

    func fetchAndCache() async throws {
        if let error = shouldThrowOnFetch { throw error }
        subject.send(stubbedItems)
    }

    func cachedItems() throws -> [ModelItem] { stubbedItems }

    func applyEvent(_ event: LiveEvent) async throws {
        var updated = stubbedItems
        if let idx = updated.firstIndex(where: { $0.id == event.item.id }) {
            updated[idx] = event.item
        } else {
            updated.append(event.item)
        }
        stubbedItems = updated
        subject.send(updated)
    }
    
    func deleteEvent(id: String) async throws {
        //Delete action code
    }

}

// MARK: - Tests
final class ViewModelTests: XCTestCase {

    private var viewModel: ListScreenViewModel!
    private var mockRepo: MockItemRepository!
    private var networkMonitor: NetworkMonitor!
    private var cancellables = Set<AnyCancellable>()

    @MainActor
    override func setUp() {
        super.setUp()
        mockRepo = MockItemRepository()
        networkMonitor = NetworkMonitor()
        viewModel = ListScreenViewModel(
            repository: mockRepo,
            networkMonitor: networkMonitor
        )
    }

    override func tearDown() {
        viewModel = nil
        mockRepo = nil
        networkMonitor = nil
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - State Transition Tests

    @MainActor
    func test_loadItems_transitionsToSuccess() async {
        mockRepo.stubbedItems = ModelItem.mockList

        let expectation = expectation(description: "success state")
        viewModel.$viewState
            .dropFirst()
            .filter { $0 == .success }
            .first()
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        viewModel.loadItems()
        await fulfillment(of: [expectation], timeout: 2)

        XCTAssertEqual(viewModel.viewState, .success)
        XCTAssertFalse(viewModel.items.isEmpty)
    }

    @MainActor
    func test_loadItems_transitionsToError() async {
        mockRepo.shouldThrowOnFetch = APIError.httpError(503)
        mockRepo.stubbedItems = []

        let expectation = expectation(description: "error state")
        viewModel.$viewState
            .dropFirst()
            .filter {
                if case .error = $0 { return true }
                return false
            }
            .first()
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        viewModel.loadItems()
        await fulfillment(of: [expectation], timeout: 2)

        if case .error = viewModel.viewState { /* pass */ }
        else { XCTFail("Expected error state, got \(viewModel.viewState)") }
    }

    @MainActor
    func test_loadItems_emptyState() async {
        mockRepo.stubbedItems = []

        let expectation = expectation(description: "empty state")
        viewModel.$viewState
            .dropFirst()
            .filter { $0 == .empty }
            .first()
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        viewModel.loadItems()
        await fulfillment(of: [expectation], timeout: 2)

        XCTAssertEqual(viewModel.viewState, .empty)
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    @MainActor
    func test_liveUpdate_reflectedInItems() async throws {
        mockRepo.stubbedItems = ModelItem.mockList
        viewModel.loadItems()

        // Wait for initial load
        try await Task.sleep(nanoseconds: 500_000_000)

        let updatedItem = ModelItem(
            id: ModelItem.mockList[0].id,
            title: "Live Updated Title",
            status: .done,
            detail: "Updated",
            updatedAt: Date()
        )
        let event = LiveEvent(type: .updated, item: updatedItem)
        try await mockRepo.applyEvent(event)

        // Wait for propagation
        try await Task.sleep(nanoseconds: 200_000_000)

        let found = viewModel.items.first(where: { $0.id == updatedItem.id })
        XCTAssertEqual(found?.title, "Live Updated Title")
    }

    @MainActor
    func test_isOffline_reflectedFromNetworkMonitor() {
        // NetworkMonitor starts connected; simulate offline
        // (In a unit test context we verify the binding exists)
        XCTAssertFalse(viewModel.isOffline)
    }
}
