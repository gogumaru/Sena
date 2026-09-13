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
    private static let cartPreferenceKey = "shopeeCartPreference"

    @Published var keyword: String = ""
    @Published private(set) var products: [Product] = []
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var isShopeeConnected: Bool = UserDefaults.standard.bool(forKey: connectedDefaultsKey)
    @Published private(set) var cartItems: [CartItem]
    @Published private(set) var cartLoadState: LoadState

    let coordinator = WebViewCoordinator()
    let loginCoordinator = WebViewCoordinator()

    /// Cegah search dan fetchCart jalan bersamaan, dua-duanya berbagi
    /// WebView yang sama (`coordinator`), kalau dibiarin bareng bakal
    /// rebutan navigasi satu sama lain.
    private var isBusy = false

    /// Muat snapshot keranjang terakhir yang tersimpan begitu ViewModel
    /// dibikin, jadi tab Preferensi langsung nampilin data lama tanpa
    /// perlu pencet "Ambil Keranjang" tiap buka app. Tombolnya jadi
    /// refresh, bukan syarat wajib.
    init() {
        let saved = Self.loadSavedCartPreference()
        cartItems = saved
        cartLoadState = saved.isEmpty ? .idle : .loaded
    }

    static func loadSavedCartPreference() -> [CartItem] {
        guard let data = UserDefaults.standard.data(forKey: cartPreferenceKey),
              let items = try? JSONDecoder().decode([CartItem].self, from: data) else {
            return []
        }
        return items
    }

    func search() {
        guard !isBusy else {
            loadState = .failed("Masih memproses permintaan lain, tunggu sebentar lalu coba lagi.")
            return
        }

        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            loadState = .failed("Keyword tidak boleh kosong.")
            return
        }

        loadState = .loading
        products = []

        Task {
            isBusy = true
            defer { isBusy = false }

            do {
                try await coordinator.navigate(to: ShopeeExtractor.homeURL)

                // Search box-nya bisa aja belum sempat kerender pas
                // halaman "selesai load". Coba beberapa kali sampai
                // beneran ke-submit, jangan lanjut ke ekstraksi kalau
                // ini diam-diam gagal.
                var searchTriggered = false
                for attempt in 0..<10 {
                    let result = try await coordinator.runExtraction(
                        script: ShopeeExtractor.triggerSearchScript(keyword: trimmed)
                    )
                    if result == "submitted" {
                        searchTriggered = true
                        break
                    }
                    if attempt < 9 {
                        try await Task.sleep(nanoseconds: 500_000_000)
                    }
                }

                guard searchTriggered else {
                    loadState = .failed("Enggak nemu kotak pencarian di halaman Shopee. Coba lagi.")
                    return
                }

                // Setelah submit, halaman hasil butuh waktu render.
                var parsed: [Product] = []
                for _ in 0..<15 {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let json = try await coordinator.runExtraction(script: ShopeeExtractor.searchResultsScript)
                    parsed = try ProductParser.parse(json: json)
                    if !parsed.isEmpty { break }
                }

                products = parsed
                loadState = parsed.isEmpty
                    ? .failed("Tidak ada produk yang berhasil diambil. Cek koneksi ke Shopee, atau selector mungkin perlu diperbarui.")
                    : .loaded
            } catch {
                loadState = .failed(error.localizedDescription)
            }
        }
    }

    func fetchCart() {
        guard !isBusy else {
            cartLoadState = .failed("Masih memproses permintaan lain, tunggu sebentar lalu coba lagi.")
            return
        }

        cartLoadState = .loading

        Task {
            isBusy = true
            defer { isBusy = false }

            do {
                try await coordinator.navigate(to: ShopeeExtractor.homeURL)

                let clickResult = try await coordinator.runExtraction(script: ShopeeExtractor.clickCartIconScript)
                guard clickResult == "clicked" else {
                    cartLoadState = .failed("Enggak nemu ikon keranjang di halaman Shopee. Coba lagi.")
                    return
                }

                var parsed: [CartItem] = []
                for _ in 0..<15 {
                    try await Task.sleep(nanoseconds: 500_000_000)
                    let json = try await coordinator.runExtraction(script: ShopeeExtractor.cartItemsScript)
                    parsed = try CartItemParser.parse(json: json)
                    if !parsed.isEmpty { break }
                }

                cartItems = parsed
                cartLoadState = parsed.isEmpty
                    ? .failed("Keranjang kosong, atau gagal diambil (cek document.URL, mungkin kena verifikasi).")
                    : .loaded

                if let data = try? JSONEncoder().encode(parsed) {
                    UserDefaults.standard.set(data, forKey: Self.cartPreferenceKey)
                }
            } catch {
                cartLoadState = .failed(error.localizedDescription)
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
