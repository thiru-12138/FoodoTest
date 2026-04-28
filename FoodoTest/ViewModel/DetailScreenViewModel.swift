//
//  DetailScreenViewModel.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import Foundation
import Combine

@MainActor
final class DetailScreenViewModel: ObservableObject {

    @Published private(set) var item: ModelItem
    @Published private(set) var isOffline: Bool

    private let repository: ItemRepositoryProtocol
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()

    init(item: ModelItem,
         repository: ItemRepositoryProtocol,
         networkMonitor: NetworkMonitor) {
        self.item = item
        self.repository = repository
        self.networkMonitor = networkMonitor
        self.isOffline = !networkMonitor.isConnected

        repository.itemsPublisher
            .receive(on: DispatchQueue.main)
            .compactMap { $0.first(where: { $0.id == item.id }) }
            .sink { [weak self] updated in
                self?.item = updated
            }
            .store(in: &cancellables)

        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isOffline = !connected
            }
            .store(in: &cancellables)
    }
}
