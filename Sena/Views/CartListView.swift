//
//  CartListView.swift
//  Sena
//
//  Created by Benedikta Anin on 11/09/26.
//


import SwiftUI

struct CartListView: View {
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        VStack(spacing: 8) {
//            Button("Ambil Keranjang") {
//                viewModel.fetchCart()
//            }
//            .buttonStyle(.bordered)

            switch viewModel.cartLoadState {
            case .idle:
                EmptyView()
            case .loading:
                ProgressView("Mengambil keranjang...")
            case .failed(let message):
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .loaded:
                ForEach(viewModel.cartItems) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title).font(.subheadline).lineLimit(2)
                        if let variant = item.variant {
                            Text(variant).font(.caption).foregroundStyle(.secondary)
                        }
                        HStack {
                            if let price = item.price {
                                Text(price, format: .currency(code: "IDR")).bold()
                            } else {
                                Text("Tidak tersedia").foregroundStyle(.red)
                            }
                            if let quantity = item.quantity {
                                Text("x\(quantity)").foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 4)
                    Divider()
                }
            }
        }
        .padding()
    }
}
