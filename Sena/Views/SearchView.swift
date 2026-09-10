//
//  SearchView.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//


import SwiftUI

/// Keyword input and the button that triggers `ProductViewModel.search()`.
struct SearchView: View {
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        HStack {
            TextField("Cari produk di Shopee...", text: $viewModel.keyword)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit { viewModel.search() }

            Button("Cari") {
                viewModel.search()
            }
            .disabled(viewModel.keyword.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
    }
}

#Preview {
    SearchView(viewModel: ProductViewModel())
}