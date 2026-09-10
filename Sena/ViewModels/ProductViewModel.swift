//
//  ProductViewModel.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//

import Combine
import Foundation


@MainActor
final class ProductViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private static let connectedDefaultsKey = "isShopeeConnected"

    @Published var keyword: String = ""
    @Published private(set) var products: [Product] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var searchURL: URL?
    @Published private(set) var isShopeeConnected: Bool = UserDefaults.standard.bool(forKey: connectedDefaultsKey)

    let coordinator = WebViewCoordinator()

    let loginCoordinator = WebViewCoordinator()

    func search() {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            loadState = .failed("Keyword tidak boleh kosong.")
            return
        }

        loadState = .loading
        products = []

        if searchURL == nil {
            searchURL = ShopeeExtractor.homeURL
        }

        Task {
            do {
                try await coordinator.waitForPageLoad()

                // Ketik keyword + submit form dari dalam halaman home,
                // meniru user. Ini yang bikin Shopee navigasi ke hasil
                // pencarian dengan cara yang dia harapkan.
                _ = try await coordinator.runExtraction(
                    script: ShopeeExtractor.triggerSearchScript(keyword: trimmed)
                )

                // Setelah submit, halaman hasil butuh waktu render. Coba
                // ekstrak beberapa kali dengan jeda dari sisi Swift.
                var parsed: [Product] = []
                for attempt in 0..<15 {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 detik
                    let json = try await coordinator.runExtraction(script: ShopeeExtractor.searchResultsScript)
                    parsed = try ProductParser.parse(json: json)
                    if !parsed.isEmpty { break }
                    _ = attempt
                }

                products = parsed
                loadState = parsed.isEmpty
                    ? .failed("Tidak ada produk yang berhasil diambil. Mungkin kena verifikasi, atau selector perlu diperbarui.")
                    : .loaded
            } catch {
                loadState = .failed(error.localizedDescription)
            }
        }
    }

    func markShopeeConnected() {
        isShopeeConnected = true
        UserDefaults.standard.set(true, forKey: Self.connectedDefaultsKey)
    }

    func connectToShopee(cookieHeader: String) {
        let cookies = WebViewCoordinator.parseCookieHeader(cookieHeader)
        WebViewCoordinator.injectCookies(cookies) { [weak self] in
            self?.isShopeeConnected = true
            UserDefaults.standard.set(true, forKey: Self.connectedDefaultsKey)
        }
    }

    func disconnectFromShopee() {
        WebViewCoordinator.clearAllWebsiteData { [weak self] in
            self?.isShopeeConnected = false
            UserDefaults.standard.set(false, forKey: Self.connectedDefaultsKey)
        }
    }
}
