//
//  Persistence.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import CoreData

struct PersistenceController {
    
    static let shared = PersistenceController()
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FoodoTest")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData load failed: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - Background Context Factory
    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }

    // MARK: - Save
    func saveContext(_ context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}
