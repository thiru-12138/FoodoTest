//
//  AppDependencies.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import Foundation

final class AppDependencies {
    let persistence: PersistenceController
    let networkMonitor: NetworkMonitor
    let apiClient: APIClientProtocol
    let repository: ItemRepositoryProtocol

    init(useMocks: Bool = false) {
        persistence = .shared
        networkMonitor = .shared
        apiClient = useMocks ? MockAPIClient() : APIClient()
        repository = ItemRepository(
            apiClient: apiClient,
            persistence: persistence,
            networkMonitor: networkMonitor
        )
    }
}
