//
//  ContentView.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var viewModel: ListScreenViewModel

    var body: some View {
        NavigationStack {
            ListScreenView()
        }
        .onAppear {
            viewModel.loadItems()
            guard let path = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
            print("path:=> ", path)
        }
    }
}
