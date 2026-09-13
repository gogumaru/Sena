//
//  WebViewCoordinator.swift
//  Sena
//
//  Created by Benedikta Anin on 07/09/26.
//


import WebKit

/// Bridges a `WKWebView`'s navigation events into async/await, and runs
/// arbitrary JavaScript (from `ShopeeExtractor`) once a page has finished
/// loading.
///
/// Owned by `ProductViewModel` (not by `ShopeeWebView`), so the view
/// model can call `waitForPageLoad()` / `runExtraction(script:)` directly
/// without needing a reference to the underlying `WKWebView`.
@MainActor
final class WebViewCoordinator: NSObject, WKNavigationDelegate {

    enum CoordinatorError: LocalizedError {
        case webViewNotAttached
        case navigationFailed(Error)
        case javaScriptReturnedNoResult
        case javaScriptException(String)

        var errorDescription: String? {
            switch self {
            case .webViewNotAttached:
                return "WebView belum siap dipakai"
            case .navigationFailed(let error):
                return "Gagal memuat halaman: \(error.localizedDescription)"
            case .javaScriptReturnedNoResult:
                return "JavaScript tidak mengembalikan hasil yang valid"
            case .javaScriptException(let message):
                return "JavaScript error: \(message)"
            }
        }
    }



    private weak var webView: WKWebView?
    private var loadContinuation: CheckedContinuation<Void, Error>?
    private var isCurrentlyLoaded = false

    func attach(to webView: WKWebView) {
        self.webView = webView
    }

    func navigate(to url: URL) async throws {
        guard let webView else {
            throw CoordinatorError.webViewNotAttached
        }
        isCurrentlyLoaded = false
        webView.load(URLRequest(url: url))
        try await waitForPageLoad()
    }
    
    func waitForPageLoad() async throws {
        if isCurrentlyLoaded {
            return
        }
        try await withCheckedThrowingContinuation { continuation in
            self.loadContinuation = continuation
        }
    }

    /// Runs the extractor JavaScript on the currently loaded page and
    /// returns the raw JSON string it produces.
    func runExtraction(script: String) async throws -> String {
        guard let webView else {
            throw CoordinatorError.webViewNotAttached
        }

//        let result = try await webView.evaluateJavaScript(script)
//        let result = try await webView.callAsyncJavaScript(script, contentWorld: .page)
//        guard let json = result as? String else {
//            throw CoordinatorError.javaScriptReturnedNoResult
//        }
//        return json

        do {
            let result = try await webView.callAsyncJavaScript(script, contentWorld: .page)
            guard let json = result as? String else {
                throw CoordinatorError.javaScriptReturnedNoResult
            }
            return json
        } catch let error as CoordinatorError {
            throw error
        } catch {
            let nsError = error as NSError
            if let message = nsError.userInfo["WKJavaScriptExceptionMessage"] as? String, !message.isEmpty {
                throw CoordinatorError.javaScriptException(message)
            }
            throw error
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isCurrentlyLoaded = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isCurrentlyLoaded = true
        loadContinuation?.resume()
        loadContinuation = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadContinuation?.resume(throwing: CoordinatorError.navigationFailed(error))
        loadContinuation = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        loadContinuation?.resume(throwing: CoordinatorError.navigationFailed(error))
        loadContinuation = nil
    }
}

extension WebViewCoordinator {
    /// Wipes all persisted Shopee website data (cookies, local storage,
    /// cache) so the next load starts from a completely clean session,
    /// as if Shopee had never been opened on this device before. Useful
    /// for testing whether a login wall only shows up after repeated
    /// automated-looking requests, versus on a genuinely fresh session.
    static func clearAllWebsiteData(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: Date(timeIntervalSince1970: 0),
            completionHandler: completion
        )
    }

    /// Parses a raw "Cookie:" request header string, the kind you copy
        /// straight out of Web Inspector's Network tab, into individual
        /// name/value pairs. Format: "name1=value1; name2=value2; ...".
        static func parseCookieHeader(_ header: String) -> [(name: String, value: String)] {
            header
                .split(separator: ";")
                .compactMap { pair -> (name: String, value: String)? in
                    let parts = pair.split(separator: "=", maxSplits: 1)
                    guard parts.count == 2 else { return nil }
                    let name = parts[0].trimmingCharacters(in: .whitespaces)
                    let value = parts[1].trimmingCharacters(in: .whitespaces)
                    return (name, value)
                }
        }

    /// Manually injects cookies (typically copied from an already
        /// logged-in Safari session's Network tab) into our own WKWebView's
        /// cookie store. This is the workaround for the broken in-app
        /// verification flow: Safari can log in fine, our WKWebView can't,
        /// so instead of logging in inside our WKWebView at all, we hand it
        /// Safari's already-authenticated session cookies directly.
        static func injectCookies(
            _ cookies: [(name: String, value: String)],
            domain: String = ".shopee.co.id",
            completion: @escaping () -> Void
        ) {
            let store = WKWebsiteDataStore.default().httpCookieStore
            let group = DispatchGroup()
            let expiry = Date().addingTimeInterval(60 * 60 * 24 * 30) //expiry 30 hari

            for cookie in cookies {
                guard let httpCookie = HTTPCookie(properties: [
                    .name: cookie.name,
                    .value: cookie.value,
                    .domain: domain,
                    .path: "/",
                    .secure: true,
                    .expires: expiry,
                ]) else { continue }

                group.enter()
                store.setCookie(httpCookie) {
                    group.leave()
                }
            }

            group.notify(queue: .main, execute: completion)
        }
}
