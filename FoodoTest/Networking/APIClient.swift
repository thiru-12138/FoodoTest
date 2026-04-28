//
//  APIClient.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import Foundation

// MARK: - APIClientProtocol
protocol APIClientProtocol {
    func fetchItems() async throws -> [ModelItem]
}

// MARK: - Errors
enum APIError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError(Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL."
        case .httpError(let c): return "Server error (HTTP \(c))."
        case .decodingError(let e): return "Data error: \(e.localizedDescription)"
        case .timeout: return "Request timed out."
        }
    }
}

// MARK: - API Client
final class APIClient: APIClientProtocol {
    private let baseURL = "https://jsonplaceholder.typicode.com/todos"

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchItems() async throws -> [ModelItem] {
        guard let url = URL(string: baseURL) else { throw APIError.invalidURL }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.timeout
        }

        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw APIError.httpError(http.statusCode)
        }

        do {
            let todos = try JSONDecoder().decode([TodoDTO].self, from: data)
            return todos.prefix(20).map { $0.toItem() }
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// MARK: - JSONPlaceholder DTO + Mapper
private struct TodoDTO: Decodable {
    let id: Int
    let title: String
    let completed: Bool

    func toItem() -> ModelItem {
        ModelItem(
            id: "FT\(id)",
            title: title.capitalized,
            status: completed ? .done : .new,
            detail: "Fetched from Json (id: \(id)).",
            updatedAt: Date()
        )
    }
}
