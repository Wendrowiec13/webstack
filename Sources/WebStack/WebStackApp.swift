import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Hide the native window buttons
        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
            }
        }
    }
}

@main
struct WebStackApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var model = WebViewModel()
    @State private var webView: WebView
    @State private var isSidebarVisible: Bool = true

    init() {
        let m = WebViewModel()
        _webView = State(initialValue: WebView(model: m))
        _model = StateObject(wrappedValue: m)
    }

    var body: some Scene {
        WindowGroup {
            HStack(spacing: 0) {
                // Sidebar
                if isSidebarVisible {
                    VStack(spacing: 0) {
                        // Top bar with macOS buttons, sidebar toggle, and navigation
                        HStack(spacing: 8) {
                            // macOS window buttons (placeholder spacing)
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.red.opacity(0.8))
                                    .frame(width: 12, height: 12)
                                Circle()
                                    .fill(Color.yellow.opacity(0.8))
                                    .frame(width: 12, height: 12)
                                Circle()
                                    .fill(Color.green.opacity(0.8))
                                    .frame(width: 12, height: 12)
                            }

                            // Sidebar toggle button
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isSidebarVisible.toggle()
                                }
                            } label: {
                                Image(systemName: "sidebar.left")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            // Navigation buttons
                            Button { webView.goBack() } label: {
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                            .disabled(!model.canGoBack)

                            Button { webView.goForward() } label: {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                            .disabled(!model.canGoForward)

                            Button {
                                model.isLoading ? webView.stopLoading() : webView.reload()
                            } label: {
                                Image(systemName: model.isLoading ? "xmark.circle" : "arrow.clockwise")
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(8)
                        .background(Color(red: 0.9, green: 0.95, blue: 1.0))

                        // URL input with search icon
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))

                                TextField("Enter URL", text: $model.urlString, onCommit: {
                                    webView.load(model.urlString)
                                })
                                .textFieldStyle(.plain)
                                .disableAutocorrection(true)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)

                            if model.isLoading {
                                ProgressView(value: model.progress)
                            }
                        }
                        .padding(12)

                        Spacer()
                    }
                    .frame(width: 250)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.9, green: 0.95, blue: 1.0),
                                Color.white
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .transition(.move(edge: .leading))
                }

                // Main content area
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.9, green: 0.95, blue: 1.0),
                            Color.white
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    webView
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 0)
                        .padding(.vertical, 10)
                        .padding(.trailing, 10)
                        .padding(.leading, isSidebarVisible ? 0 : 10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
            .onAppear {
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "s" {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSidebarVisible.toggle()
                        }
                        return nil
                    }
                    return event
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
    }
}
