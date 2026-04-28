//
//  OfflineBannerView.swift
//  FoodoTest
//
//  Created by Thirumalai Ganesh G on 28/04/26.
//

import SwiftUI

// MARK: - Offline Banner
struct OfflineBannerView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("You're offline — showing cached data")
                .font(.caption.bold())
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.brown)
    }
}
