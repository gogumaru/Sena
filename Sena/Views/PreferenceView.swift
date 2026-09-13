//
//  PreferenceView.swift
//  Sena
//
//  Created by Benedikta Anin on 11/09/26.
//

import SwiftUI

struct PreferenceView: View {
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                CartListView(viewModel: viewModel)
            }
            .navigationTitle("Preferensi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.fetchCart()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.cartLoadState == .loading)
                }
            }
        }
    }
}
