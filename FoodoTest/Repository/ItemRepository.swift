//
//  ItemRepository.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import CoreData
import Combine
import Foundation

// MARK: - Protocol
protocol ItemRepositoryProtocol {
    var itemsPublisher: AnyPublisher<[ModelItem], Never> { get }
    func fetchAndCache() async throws
    func cachedItems() throws -> [ModelItem]
    func applyEvent(_ event: LiveEvent) async throws
    func deleteEvent(id: String) async throws
}

// MARK: - Item Repository
final class ItemRepository: ItemRepositoryProtocol {

    // MARK: Dependencies
    private let apiClient: APIClientProtocol
    private let persistence: PersistenceController
    private let networkMonitor: NetworkMonitor

    // MARK: Cache TTL — 5 minutes
    private let cacheTTL: TimeInterval = 5 * 60

    // MARK: Items subject — emits sorted snapshots to ViewModels
    private let itemsSubject = CurrentValueSubject<[ModelItem], Never>([])
    var itemsPublisher: AnyPublisher<[ModelItem], Never> {
        itemsSubject.eraseToAnyPublisher()
    }

    // MARK: Init
    init(apiClient: APIClientProtocol, persistence: PersistenceController, networkMonitor: NetworkMonitor) {
        self.apiClient = apiClient
        self.persistence = persistence
        self.networkMonitor = networkMonitor
    }

    // MARK: - Fetch + Persist
    func fetchAndCache() async throws {
        let remote = try await apiClient.fetchItems()
        let ctx = persistence.newBackgroundContext()

        try await ctx.perform {
            for item in remote {
                let entity = self.findOrCreate(id: item.id, in: ctx)
                if let existing = entity.updatedAt, item.updatedAt > existing {
                    item.apply(to: entity)
                } else if entity.updatedAt == nil {
                    item.apply(to: entity)
                }
            }
            try self.persistence.saveContext(ctx)
        }

        let updated = try cachedItems()
        await MainActor.run { itemsSubject.send(updated) }
    }

    // MARK: - Read from Cache
    func cachedItems() throws -> [ModelItem] {
        let ctx = persistence.container.viewContext
        let request = ItemEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

        let entities = try ctx.fetch(request)
        return entities.compactMap { ModelItem(entity: $0) }
    }

    // MARK: - Cache Validity Check (TTL)
    func isCacheStale() throws -> Bool {
        let ctx = persistence.container.viewContext
        let request = ItemEntity.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "cachedAt", ascending: false)]

        guard let first = try ctx.fetch(request).first,
              let cachedAt = first.cachedAt else { return true }

        return Date().timeIntervalSince(cachedAt) > cacheTTL
    }

    // MARK: - Apply Live Event
    func applyEvent(_ event: LiveEvent) async throws {
        let ctx = persistence.newBackgroundContext()

        try await ctx.perform {
            switch event.type {
            case .created, .updated, .cancelled:
                let entity = self.findOrCreate(id: event.item.id, in: ctx)
                if let existing = entity.updatedAt {
                    guard event.item.updatedAt > existing else { return }
                }
                event.item.apply(to: entity)

            case .deleted:
                let request = ItemEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@", event.item.id)
                if let entity = try ctx.fetch(request).first {
                    ctx.delete(entity)
                }
            }
            try self.persistence.saveContext(ctx)
        }

        let updated = try cachedItems()
        await MainActor.run { itemsSubject.send(updated) }
    }

    // MARK: - Upsert Helper
    private func findOrCreate(id: String, in ctx: NSManagedObjectContext) -> ItemEntity {
        let request = ItemEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        if let existing = try? ctx.fetch(request).first {
            return existing
        }
        let entity = ItemEntity(context: ctx)
        entity.id = id
        return entity
    }
    
    // MARK: - Delete Event
    func deleteEvent(id: String) async throws {
        let ctx = persistence.newBackgroundContext()
        
        try await ctx.perform {
            let request = ItemEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            if let entity = try ctx.fetch(request).first {
                ctx.delete(entity)
            }
            
            try self.persistence.saveContext(ctx)
        }
        
        let updated = try cachedItems()
        await MainActor.run { itemsSubject.send(updated) }
    }
}
