import SwiftUI
import WebKit
import Combine

final class WebViewModel: ObservableObject {
    @Published var urlString: String = "https://apple.com"
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var progress: Double = 0.0
    @Published var pageTitle: String = ""
}

struct WebView: NSViewRepresentable {
    @ObservedObject var model: WebViewModel
    let webView = WKWebView(frame: .zero, configuration: {
        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = true
        return config
    }())

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.canGoBack), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.canGoForward), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)

        load(model.urlString)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}

    func load(_ string: String) {
        guard var comps = URLComponents(string: string.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        if comps.scheme == nil { comps.scheme = "https" }
        guard let url = comps.url else { return }
        webView.load(URLRequest(url: url))
    }

    func goBack() { webView.goBack() }
    func goForward() { webView.goForward() }
    func reload() { webView.reload() }
    func stopLoading() { webView.stopLoading() }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebView
        private var cancellables = Set<AnyCancellable>()

        init(_ parent: WebView) {
            self.parent = parent
            super.init()
            parent.model.$urlString
                .removeDuplicates()
                .sink { _ in }
                .store(in: &cancellables)
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            guard let webView = object as? WKWebView else { return }
            switch keyPath {
            case "estimatedProgress": parent.model.progress = webView.estimatedProgress
            case "canGoBack":        parent.model.canGoBack = webView.canGoBack
            case "canGoForward":     parent.model.canGoForward = webView.canGoForward
            case "isLoading":        parent.model.isLoading = webView.isLoading
            case "title":            parent.model.pageTitle = webView.title ?? ""
            default: break
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            if let url = webView.url { parent.model.urlString = url.absoluteString }
        }
    }
}
