import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct WebStackApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var model = WebViewModel()
    @State private var webView: WebView

    init() {
        let m = WebViewModel()
        _webView = State(initialValue: WebView(model: m))
        _model = StateObject(wrappedValue: m)
    }

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button { webView.goBack() } label: { Image(systemName: "chevron.left") }
                        .disabled(!model.canGoBack)

                    Button { webView.goForward() } label: { Image(systemName: "chevron.right") }
                        .disabled(!model.canGoForward)

                    TextField("Enter URL", text: $model.urlString, onCommit: { webView.load(model.urlString) })
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)

                    Button {
                        model.isLoading ? webView.stopLoading() : webView.reload()
                    } label: {
                        Image(systemName: model.isLoading ? "xmark.circle" : "arrow.clockwise")
                    }
                }
                .padding(8)
                .background(.bar)

                if model.isLoading {
                    ProgressView(value: model.progress)
                        .padding(.horizontal, 8)
                }

                webView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(model.pageTitle.isEmpty ? "WebStack" : model.pageTitle)
        }
        .windowStyle(.titleBar)
    }
}
