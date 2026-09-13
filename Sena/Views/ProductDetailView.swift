//
//  ProductDetailView.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//


import SwiftUI

/// Detail screen for a single product. For this stage, "detail" just
/// means opening the product's real Shopee page in an in-app web view,
/// per the experiment doc's "Tahap 7 - Menguji halaman detail" step.
/// Extracting extra structured detail (variants, full spec) is not part
/// of this stage.
struct ProductDetailView: View {
    let product: Product
    @State private var detailCoordinator = WebViewCoordinator()

    var body: some View {
        ShopeeWebView(coordinator: detailCoordinator)
            .navigationTitle(product.title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                guard let url = URL(string: product.url) else { return }
                try? await detailCoordinator.navigate(to: url)
            }
    }
}

#Preview {
    ProductDetailView(
        product: Product(
            id: "preview",
            title: "Contoh produk",
            price: 150_000,
            rating: 4.8,
            soldCount: 1200,
            seller: "Toko Contoh",
            url: "https://shopee.co.id",
            imageURL: nil
        )
    )
}
