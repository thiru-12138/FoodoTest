//
//  ListScreenView.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import SwiftUI

struct ListScreenView: View {

    @EnvironmentObject private var viewModel: ListScreenViewModel

    var body: some View {
        ZStack {
            listContent
                .navigationTitle("Foodo Items")
                .toolbar { refreshToolbar }
                .refreshable { viewModel.refresh() }

            overlayContent
        }
        .safeAreaInset(edge: .top) {
            if viewModel.isOffline { OfflineBannerView() }
        }
    }

    // MARK: - List / State Views
    @ViewBuilder
    private var listContent: some View {
        switch viewModel.viewState {
        case .idle, .loading:
            loadingView

        case .success, .error:
            if viewModel.items.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No Items",
                    message: "Pull down to refresh."
                )
            } else {
                List(viewModel.items) { item in
                    NavigationLink(destination: listDetail(for: item)) {
                        ListRowView(item: item)
                            .swipeActions(content: {
                                Button("Delete", role: .destructive, action: {
                                    viewModel.delete(id: item.id)
                                })
                            })
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                }
                .listStyle(.plain)
                .animation(.easeInOut, value: viewModel.items)
            }

        case .empty:
            EmptyStateView(
                icon: "tray",
                title: "No Items Yet",
                message: "No data available."
            )
        }
    }

    @ViewBuilder
    private var overlayContent: some View {
        if case .error(let msg) = viewModel.viewState {
            VStack {
                Spacer()
                ErrorBannerView(message: msg) {
                    viewModel.refresh()
                }
                .padding()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers
    private func listDetail(for item: ModelItem) -> some View {
        DetailScreenView(
            viewModel: DetailScreenViewModel(
                item: item,
                repository: AppDependencies().repository,
                networkMonitor: .shared
            )
        )
    }

    private var refreshToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button { viewModel.refresh() } label: {
                Text("Refresh")
            }
        }
    }
}
