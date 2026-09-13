//
//  ShopeeWebView.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//


import SwiftUI
import WebKit

/// Wraps a `WKWebView` so it can be used inside SwiftUI.
///
/// Navigasi dikendaliin sepenuhnya lewat `WebViewCoordinator.navigate(to:)`,
/// bukan lewat parameter `url` yang di-diff di sini. Versi lama yang
/// nerima `url` balapan sama alur async coordinator-nya sendiri.
struct ShopeeWebView: UIViewRepresentable {
    let coordinator: WebViewCoordinator

    func makeCoordinator() -> WebViewCoordinator {
        coordinator
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let permissionsPolyfill = WKUserScript(
            source: ShopeeExtractor.permissionsPolyfillScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        configuration.userContentController.addUserScript(permissionsPolyfill)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"
        context.coordinator.attach(to: webView)

        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Sengaja kosong, navigasi diurus WebViewCoordinator.navigate(to:).
    }
}
