//
//  StatusBadgeView.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import SwiftUI

// MARK: - Status Badge
struct StatusBadgeView: View {
    let status: ItemStatus

    private var color: Color {
        switch status {
        case .new:        return .blue
        case .inProgress: return .orange
        case .done:       return .green
        case .cancelled:  return .gray
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
