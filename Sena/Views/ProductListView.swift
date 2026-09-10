//
//  ProductListView.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//


import SwiftUI

/// Renders `ProductViewModel`'s current state: a loading indicator, an
/// error message, or the list of extracted products.
struct ProductListView: View {
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        switch viewModel.loadState {
        case .idle:
            ContentUnavailableView(
                "Belum ada pencarian",
                systemImage: "magnifyingglass",
                description: Text("Masukkan kata kunci lalu tekan Cari.")
            )
//        case .readyToExtract:
//            ContentUnavailableView(
//                "Siap diekstrak",
//                systemImage: "checkmark.circle",
//                description: Text("Masukkan kata kunci lalu tekan Cari.")
//            )
        case .loading:
            ProgressView("Mengambil data dari Shopee...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView(
                "Gagal mengambil data",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .loaded:
            List(viewModel.products) { product in
                NavigationLink {
                    ProductDetailView(product: product)
                } label: {
                    ProductRow(product: product)
                }
            }
            .listStyle(.plain)
        }
    }
}

/// A single row in the product list.
private struct ProductRow: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.title)
                .font(.body)
                .lineLimit(2)

            HStack(spacing: 8) {
                if let price = product.price {
                    Text(price, format: .currency(code: "IDR"))
                        .font(.subheadline)
                        .bold()
                }
                if let rating = product.rating {
                    Label(String(format: "%.1f", rating), systemImage: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                if let soldCount = product.soldCount {
                    Text("\(soldCount)+ terjual")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let seller = product.seller {
                Text(seller)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ProductListView(viewModel: ProductViewModel())
}
