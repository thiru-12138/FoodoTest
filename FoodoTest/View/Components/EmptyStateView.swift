//
//  EmptyStateView.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import SwiftUI

// MARK: - Empty State
struct EmptyStateView: View {
    let icon:    String
    let title:   String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title).font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Error Banner
struct ErrorBannerView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text(message)
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(2)
            Spacer()
            Button("Retry", action: retry)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.25))
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color.red.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
