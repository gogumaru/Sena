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
/// Loading, JavaScript execution, and error handling are delegated to
/// `WebViewCoordinator`, which is owned by the caller (usually a view
/// model) rather than created internally, so the caller can keep a
/// stable reference to it and call methods on it directly.
struct ShopeeWebView: UIViewRepresentable {
    let url: URL
    let coordinator: WebViewCoordinator

    func makeCoordinator() -> WebViewCoordinator {
        coordinator
    }

    func makeUIView(context: Context) -> WKWebView {
        // let webView = WKWebView()
        let configuration = WKWebViewConfiguration()
        let permissionsPolyfill = WKUserScript(
            source: ShopeeExtractor.permissionsPolyfillScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        configuration.userContentController.addUserScript(permissionsPolyfill)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        
        webView.navigationDelegate = context.coordinator
        context.coordinator.attach(to: webView)
        
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1"
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only load if the URL actually changed, to avoid re-triggering
        // navigation (and losing extraction state) on every SwiftUI
        // view update.
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }
}
