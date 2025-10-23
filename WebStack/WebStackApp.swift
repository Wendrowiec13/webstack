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
    @State private var isSidebarVisible: Bool = true
    @State private var sidebarWidth: CGFloat = 255
    @State private var isHoveringButtons: Bool = false
    @FocusState private var isUrlFieldFocused: Bool
    @FocusState private var isDummyFocused: Bool

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Hidden focusable element to prevent URL field from auto-focusing
                TextField("", text: .constant(""))
                    .focused($isDummyFocused)
                    .frame(width: 0, height: 0)
                    .opacity(0)

                // Hidden button for keyboard shortcuts
                Button("Copy URL", action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(model.urlString, forType: .string)
                })
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .frame(width: 0, height: 0)
                .opacity(0)

                Button("New Tab", action: {
                    model.createNewTab()
                    isUrlFieldFocused = true
                })
                .keyboardShortcut("t", modifiers: .command)
                .frame(width: 0, height: 0)
                .opacity(0)

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
                                action: {
                                    if let activeTab = model.tabs.first(where: { $0.id == model.activeTabId }) {
                                        activeTab.webView.goBack()
                                    }
                                },
                                icon: "arrow.left",
                                disabled: !model.canGoBack,
                                top: 8,
                                leading: 6,
                                bottom: 8,
                                trailing: 6,
                                fontSize: 16
                            )

                            HoverButton(
                                action: {
                                    if let activeTab = model.tabs.first(where: { $0.id == model.activeTabId }) {
                                        activeTab.webView.goForward()
                                    }
                                },
                                icon: "arrow.right",
                                disabled: !model.canGoForward,
                                top: 8,
                                leading: 6,
                                bottom: 8,
                                trailing: 6,
                                fontSize: 16
                            )

                            HoverButton(
                                action: {
                                    if let activeTab = model.tabs.first(where: { $0.id == model.activeTabId }) {
                                        if model.isLoading {
                                            activeTab.webView.stopLoading()
                                        } else {
                                            activeTab.webView.reload()
                                        }
                                    }
                                },
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
                            .focusEffectDisabled()
                            .animation(.easeInOut(duration: 0.2), value: isUrlFieldFocused)
                            .onSubmit {
                                if let activeTab = model.tabs.first(where: { $0.id == model.activeTabId }) {
                                    guard var comps = URLComponents(string: model.urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else { return }
                                    if comps.scheme == nil { comps.scheme = "https" }
                                    guard let url = comps.url else { return }
                                    activeTab.webView.load(URLRequest(url: url))
                                }
                                isUrlFieldFocused = false
                            }

                            if model.isLoading {
                                ProgressView(value: model.progress)
                            }
                        }
                        .padding(6)

                        // Tabs section
                        ScrollView {
                            VStack(spacing: 4) {
                                ForEach(model.tabs) { tab in
                                    TabItemView(
                                        tab: tab,
                                        isActive: tab.id == model.activeTabId,
                                        onSelect: {
                                            model.switchToTab(id: tab.id)
                                        },
                                        onClose: {
                                            model.closeTab(id: tab.id)
                                        }
                                    )
                                }

                                // New Tab button
                                NewTabButton {
                                    model.createNewTab()
                                    isUrlFieldFocused = true
                                }
                                .padding(.top, 4)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                        }

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

                    WebView(model: model)
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
                    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

                    // Cmd+S to toggle sidebar
                    if flags == .command && event.charactersIgnoringModifiers == "s" {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isSidebarVisible.toggle()
                        }
                        return nil
                    }

                    return event
                }
            }
            }
            .onAppear {
                // Focus dummy field on startup to prevent URL field from auto-focusing
                isDummyFocused = true
            }
        }
        .windowStyle(.hiddenTitleBar)
    }
}
