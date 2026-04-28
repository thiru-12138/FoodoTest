//
//  FoodoTestApp.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import SwiftUI
import CoreData

@main
struct FoodoTestApp: App {
    private let deps = AppDependencies()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                              deps.persistence.container.viewContext)
                .environmentObject(
                    ListScreenViewModel(
                        repository: deps.repository,
                        networkMonitor: deps.networkMonitor
                    )
                )
                .environmentObject(deps.networkMonitor)
        }
    }
}
