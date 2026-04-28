//
//  ItemListViewModel.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import Foundation
import Combine
import CoreData

@MainActor
final class ItemListViewModel: ObservableObject {

    // MARK: - UI State
    enum ViewState: Equatable {
        case idle
        case loading
        case success
        case empty
        case error(String)
    }

    // MARK: - Published Properties
    @Published private(set) var viewState: ViewState = .idle
    @Published private(set) var items: [ModelItem] = []
    @Published private(set) var isOffline: Bool = false
    @Published private(set) var lastUpdated: Date?

    // MARK: - Dependencies
    private let repository: ItemRepositoryProtocol
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Live Event Simulation
    private var liveEventTimer: AnyCancellable?
    private var eventQueue: [LiveEvent] = []
    private var eventIndex = 0
    private let eventInterval: TimeInterval = 10

    // MARK: - Init
    init(repository: ItemRepositoryProtocol,
         networkMonitor: NetworkMonitor) {
        self.repository = repository
        self.networkMonitor = networkMonitor

        bindRepository()
        bindNetworkMonitor()
        loadMockEvents()
    }

    // MARK: - Public Actions

    func loadItems() {
        Task { await fetch() }
    }

    func refresh() {
        Task { await fetch() }
    }

    // MARK: - Private Fetch Logic
    private func fetch() async {
        viewState = .loading

        // If offline → load cache only
        guard networkMonitor.isConnected else {
            do {
                let cached = try repository.cachedItems()
                items = cached
                viewState = cached.isEmpty ? .empty : .success
                isOffline = true
            } catch {
                viewState = .error("Could not load cached data.")
            }
            return
        }

        isOffline = false

        do {
            try await repository.fetchAndCache()
            lastUpdated = Date()
            // items updated via itemsPublisher
        } catch {
            // Fall back to cache on error
            let cached = (try? repository.cachedItems()) ?? []
            items = cached
            viewState = .error(
                cached.isEmpty
                    ? "Failed to load. Check your connection and retry."
                    : "Showing cached data. \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Bindings
    private func bindRepository() {
        repository.itemsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newItems in
                guard let self else { return }
                self.items = newItems
                self.viewState = newItems.isEmpty ? .empty : .success
            }
            .store(in: &cancellables)
    }

    private func bindNetworkMonitor() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isOffline = !connected
            }
            .store(in: &cancellables)
    }

    // MARK: - Live Event Stream
    private func loadMockEvents() {
        guard let url = Bundle.main.url(forResource: "mock_events", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        eventQueue = (try? decoder.decode([LiveEvent].self, from: data)) ?? []

        startLiveEventTimer()
    }

    private func startLiveEventTimer() {
        guard !eventQueue.isEmpty else { return }

        liveEventTimer = Timer.publish(every: eventInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.emitNextEvent()
            }
    }

    private func emitNextEvent() {
        guard eventIndex < eventQueue.count else {
            liveEventTimer?.cancel()
            return
        }
        let event = eventQueue[eventIndex]
        eventIndex += 1

        Task {
            try? await repository.applyEvent(event)
        }
    }
    
    func delete(id: String) {
        Task {
            try? await repository.deleteEvent(id: id)
        }
    }
}
