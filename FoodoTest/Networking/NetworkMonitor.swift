//
//  NetworkMonitor.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import Network
import Combine


// MARK: - NetworkMonitor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
                self?.isConnected = path.status == .satisfied
                print("network:", self?.isConnected ?? false)
            })
        }
        monitor.start(queue: queue)
    }

    deinit { monitor.cancel() }
}
