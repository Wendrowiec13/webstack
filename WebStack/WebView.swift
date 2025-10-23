import SwiftUI
import WebKit
import Combine

struct Tab: Identifiable {
    let id: UUID
    var urlString: String
    var pageTitle: String
    var favicon: NSImage?
    let webView: WKWebView

    init(urlString: String = "") {
        self.id = UUID()
        self.urlString = urlString
        self.pageTitle = ""
        self.favicon = nil

        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = true
        self.webView = WKWebView(frame: .zero, configuration: config)
    }
}

final class WebViewModel: ObservableObject {
    @Published var tabs: [Tab] = []
    @Published var activeTabId: UUID?

    // Properties for the active tab
    @Published var urlString: String = "https://apple.com"
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    @Published var progress: Double = 0.0
    @Published var pageTitle: String = ""

    init() {
        createNewTab()
    }

    func createNewTab(urlString: String = "") {
        let newTab = Tab(urlString: urlString.isEmpty ? "" : urlString)
        tabs.append(newTab)
        switchToTab(id: newTab.id)
    }

    func closeTab(id: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs.remove(at: index)

        // If we closed the active tab, switch to another tab
        if activeTabId == id {
            if !tabs.isEmpty {
                let newActiveId = index < tabs.count ? tabs[index].id : tabs[index - 1].id
                switchToTab(id: newActiveId)
            } else {
                // No tabs left, create a new one
                createNewTab()
            }
        }
    }

    func switchToTab(id: UUID) {
        guard let tab = tabs.first(where: { $0.id == id }) else { return }
        activeTabId = id
        urlString = tab.urlString
        pageTitle = tab.pageTitle

        // Update navigation state from the tab's webview
        canGoBack = tab.webView.canGoBack
        canGoForward = tab.webView.canGoForward
        isLoading = tab.webView.isLoading
        progress = tab.webView.estimatedProgress
    }

    func updateActiveTab(urlString: String? = nil, pageTitle: String? = nil, favicon: NSImage? = nil) {
        guard let activeTabId = activeTabId,
              let index = tabs.firstIndex(where: { $0.id == activeTabId }) else { return }

        if let urlString = urlString {
            tabs[index].urlString = urlString
            self.urlString = urlString
        }
        if let pageTitle = pageTitle {
            tabs[index].pageTitle = pageTitle
            self.pageTitle = pageTitle
        }
        if let favicon = favicon {
            tabs[index].favicon = favicon
        }
    }
}

struct WebView: NSViewRepresentable {
    @ObservedObject var model: WebViewModel

    var webView: WKWebView? {
        guard let activeTabId = model.activeTabId,
              let tab = model.tabs.first(where: { $0.id == activeTabId }) else {
            return nil
        }
        return tab.webView
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        updateWebView(in: containerView, context: context)
        return containerView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        updateWebView(in: nsView, context: context)
    }

    private func updateWebView(in containerView: NSView, context: Context) {
        // Remove all existing subviews
        containerView.subviews.forEach { $0.removeFromSuperview() }

        guard let webView = webView else { return }

        // Setup webView if needed
        if webView.navigationDelegate == nil {
            webView.navigationDelegate = context.coordinator
            webView.uiDelegate = context.coordinator
            webView.allowsBackForwardNavigationGestures = true

            webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
            webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.canGoBack), options: .new, context: nil)
            webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.canGoForward), options: .new, context: nil)
            webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
            webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)

            if webView.url == nil && !model.urlString.isEmpty {
                load(model.urlString, in: webView)
            }
        }

        // Add webView to container
        webView.frame = containerView.bounds
        webView.autoresizingMask = [.width, .height]
        containerView.addSubview(webView)
    }

    func load(_ string: String, in webView: WKWebView? = nil) {
        guard let targetWebView = webView ?? self.webView else { return }
        guard var comps = URLComponents(string: string.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
        if comps.scheme == nil { comps.scheme = "https" }
        guard let url = comps.url else { return }
        targetWebView.load(URLRequest(url: url))
    }

    func goBack() { webView?.goBack() }
    func goForward() { webView?.goForward() }
    func reload() { webView?.reload() }
    func stopLoading() { webView?.stopLoading() }

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
            guard let webView = object as? WKWebView,
                  webView == parent.webView else { return }

            switch keyPath {
            case "estimatedProgress": parent.model.progress = webView.estimatedProgress
            case "canGoBack":        parent.model.canGoBack = webView.canGoBack
            case "canGoForward":     parent.model.canGoForward = webView.canGoForward
            case "isLoading":        parent.model.isLoading = webView.isLoading
            case "title":
                let title = webView.title ?? ""
                parent.model.pageTitle = title
                parent.model.updateActiveTab(pageTitle: title)
            default: break
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard webView == parent.webView else { return }
            if let url = webView.url {
                let urlString = url.absoluteString
                parent.model.urlString = urlString
                parent.model.updateActiveTab(urlString: urlString)
            }

            // Load favicon
            loadFavicon(for: webView)
        }

        private func loadFavicon(for webView: WKWebView) {
            guard let url = webView.url else { return }

            let faviconURL = url.scheme! + "://" + url.host! + "/favicon.ico"

            URLSession.shared.dataTask(with: URL(string: faviconURL)!) { data, response, error in
                guard let data = data, error == nil, let image = NSImage(data: data) else { return }

                DispatchQueue.main.async {
                    self.parent.model.updateActiveTab(favicon: image)
                }
            }.resume()
        }
    }
}
