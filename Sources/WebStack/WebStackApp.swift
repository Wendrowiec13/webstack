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
                let customToolbar = NSToolbar()
                // window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.toolbar = customToolbar
                // Keep native buttons visible and functional
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
    @State private var sidebarWidth: CGFloat = 255
    @State private var isHoveringButtons: Bool = false
    @FocusState private var isUrlFieldFocused: Bool

    init() {
        let m = WebViewModel()
        _webView = State(initialValue: WebView(model: m))
        _model = StateObject(wrappedValue: m)
    }

    func updateWindowButtons(visible: Bool, hovering: Bool = false) {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                // Only show buttons if sidebar is visible AND hovering
                let shouldShow = visible && hovering

                if let closeButton = window.standardWindowButton(.closeButton),
                   let miniaturizeButton = window.standardWindowButton(.miniaturizeButton),
                   let zoomButton = window.standardWindowButton(.zoomButton) {
                    // if shouldShow {
                    //     // Position buttons to respect sidebar padding (6pt top + 8pt vertical padding)
                    //     let verticalOffset: CGFloat = 6 // 6
                    //     let horizontalOffset: CGFloat = 14.0 // 6 + 8

                    //     // Calculate positions with padding
                    //     closeButton.frame.origin = CGPoint(x: horizontalOffset, y: verticalOffset)
                    //     miniaturizeButton.frame.origin = CGPoint(x: horizontalOffset + 20, y: verticalOffset)
                    //     zoomButton.frame.origin = CGPoint(x: horizontalOffset + 40, y: verticalOffset)
                    // }

                    // Set visibility
                    closeButton.isHidden = !shouldShow
                    miniaturizeButton.isHidden = !shouldShow
                    zoomButton.isHidden = !shouldShow

                    // Force redraw to show button icons
                    if shouldShow {
                        closeButton.needsDisplay = true
                        miniaturizeButton.needsDisplay = true
                        zoomButton.needsDisplay = true
                    }
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            HStack(spacing: 0) {
                // Sidebar
                if isSidebarVisible {
                    VStack(spacing: 0) {
                        // Top bar with sidebar toggle and navigation
                        HStack(spacing: 8) {
                            // Space for native macOS window buttons
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(red: 0.85, green: 0.92, blue: 0.98))
                                    .frame(width: 12, height: 12)
                                Circle()
                                    .fill(Color(red: 0.85, green: 0.92, blue: 0.98))
                                    .frame(width: 12, height: 12)
                                Circle()
                                    .fill(Color(red: 0.85, green: 0.92, blue: 0.98))
                                    .frame(width: 12, height: 12)
                            }
                            .onHover { hovering in
                                isHoveringButtons = hovering
                                updateWindowButtons(visible: isSidebarVisible, hovering: hovering)
                            }

                            // Sidebar toggle button
                            Button {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    isSidebarVisible.toggle()
                                }
                                updateWindowButtons(visible: isSidebarVisible, hovering: isHoveringButtons)
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
                    .padding(.top, 6)
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
                // Set initial button visibility (hidden until hover)
                updateWindowButtons(visible: isSidebarVisible, hovering: false)

                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "s" {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSidebarVisible.toggle()
                        }
                        updateWindowButtons(visible: isSidebarVisible, hovering: isHoveringButtons)
                        return nil
                    }
                    return event
                }
            }
            .onChange(of: isSidebarVisible) { newValue in
                updateWindowButtons(visible: newValue, hovering: isHoveringButtons)
            }
        }
        .windowStyle(.hiddenTitleBar)
    }
}
