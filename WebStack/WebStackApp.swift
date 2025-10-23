import SwiftUI
import AppKit

struct ResizeCursor: NSViewRepresentable {
    func makeNSView(context: Context) -> CursorView {
        return CursorView()
    }

    func updateNSView(_ nsView: CursorView, context: Context) {}

    class CursorView: NSView {
        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .resizeLeftRight)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Configure window appearance
        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden

                // Hide native window buttons since we're using custom ones
                window.standardWindowButton(.closeButton)?.isHidden = true
                window.standardWindowButton(.miniaturizeButton)?.isHidden = true
                window.standardWindowButton(.zoomButton)?.isHidden = true
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct WebStackApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var model = WebViewModel()
    @State private var webView: WebView
    @State private var isSidebarVisible: Bool = true
    @State private var sidebarWidth: CGFloat = 255
    @State private var isHoveringButtons: Bool = false
    @FocusState private var isUrlFieldFocused: Bool

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
                        // Top bar with sidebar toggle and navigation
                        HStack(spacing: 4) {
                            // Window control buttons - show placeholders or custom controls based on hover
                            ZStack {
                                // Placeholder buttons (shown when not hovering)
                                if !isHoveringButtons {
                                    HStack(spacing: 8) {
                                        PlaceholderWindowButton()
                                        PlaceholderWindowButton()
                                        PlaceholderWindowButton()
                                    }
                                }

                                // Custom window controls (shown when hovering)
                                WindowControls(isHovered: $isHoveringButtons, isFullscreen: false)
                                    .opacity(isHoveringButtons ? 1 : 0)
                            }
                            .onHover { hovering in
                                isHoveringButtons = hovering
                            }

                            // Sidebar toggle button
                            HoverButton(
                                action: {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        isSidebarVisible.toggle()
                                    }
                                },
                                icon: "sidebar.left",
                                disabled: false,
                                top: 8,
                                leading: 6,
                                bottom: 8,
                                trailing: 6,
                                fontSize: 15
                            )

                            Spacer()

                            // Navigation buttons
                            HoverButton(
                                action: { webView.goBack() },
                                icon: "arrow.left",
                                disabled: !model.canGoBack,
                                top: 8,
                                leading: 6,
                                bottom: 8,
                                trailing: 6,
                                fontSize: 16
                            )

                            HoverButton(
                                action: { webView.goForward() },
                                icon: "arrow.right",
                                disabled: !model.canGoForward,
                                top: 8,
                                leading: 6,
                                bottom: 8,
                                trailing: 6,
                                fontSize: 16
                            )

                            HoverButton(
                                action: { model.isLoading ? webView.stopLoading() : webView.reload() },
                                icon: model.isLoading ? "xmark.circle" : "arrow.clockwise",
                                disabled: false,
                                top: 6,
                                leading: 8,
                                bottom: 6,
                                trailing: 8,
                                fontSize: 16
                            )
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .padding(.leading, 8)
                        .padding(.trailing, 4)
                        .background(Color(red: 0.9, green: 0.95, blue: 1.0))

                        // URL input with search icon
                        VStack(spacing: 12) {
                            TextField("Enter URL", text: $model.urlString)
                            .textFieldStyle(.plain)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                isUrlFieldFocused
                                    ? Color(red: 0.98, green: 0.98, blue: 1.0)
                                    : Color(red: 0.85, green: 0.92, blue: 0.98)
                            )
                            .cornerRadius(8)
                            .focused($isUrlFieldFocused)
                            .animation(.easeInOut(duration: 0.2), value: isUrlFieldFocused)
                            .onSubmit {
                                webView.load(model.urlString)
                                isUrlFieldFocused = false
                            }

                            if model.isLoading {
                                ProgressView(value: model.progress)
                            }
                        }
                        .padding(6)

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isUrlFieldFocused = false
                    }
                    .padding(.leading, 6)
                    .padding(.trailing, 6)
                    .frame(width: sidebarWidth)
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
                    .overlay(
                        ZStack {
                            ResizeCursor()
                            Rectangle()
                                .fill(Color.clear)
                        }
                        .frame(width: 8)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let newWidth = sidebarWidth + value.translation.width
                                    sidebarWidth = min(max(newWidth, 200), 400)
                                }
                        ),
                        alignment: .trailing
                    )
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
                .contentShape(Rectangle())
                .onTapGesture {
                    isUrlFieldFocused = false
                }
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
