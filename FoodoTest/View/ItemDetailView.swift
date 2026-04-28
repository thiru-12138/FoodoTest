//
//  ItemDetailView.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import SwiftUI

struct ItemDetailView: View {
    @ObservedObject var viewModel: ItemDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.isOffline { OfflineBannerView() }

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.item.title)
                        .font(.title2.bold())

                    StatusBadgeView(status: viewModel.item.status)
                }

                Divider()

                // Detail body
                Text(viewModel.item.detail)
                    .font(.body)
                    .foregroundStyle(.primary)

                Divider()

                // Metadata
                metadataRow(label: "ID",
                            value: viewModel.item.id)
                metadataRow(label: "Updated",
                            value: viewModel.item.updatedAt.formatted(.dateTime.day().month().year().hour().minute()))
            }
            .padding()
        }
        .navigationTitle("Foodo Item Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
