import AppKit
import SwiftUI

enum WindowControlType {
    case close, minimize, zoom
}

struct WindowControls: View {
    @Binding var isHovered: Bool
    let isFullscreen: Bool

    var body: some View {
        if !isFullscreen {
            HStack(spacing: 8) {
                WindowControlButton(type: .close, isHovered: $isHovered)
                WindowControlButton(type: .minimize, isHovered: $isHovered)
                WindowControlButton(type: .zoom, isHovered: $isHovered)
            }
        } else {
            EmptyView()
        }
    }
}

struct WindowControlButton: View {
    let type: WindowControlType
    @Binding var isHovered: Bool
    @State private var isPressed = false
    @State private var isLocalHovered = false

    private var buttonSize: CGFloat { 12 }

    private var assetBaseName: String {
        switch type {
        case .close: return "close"
        case .minimize: return "minimize"
        case .zoom: return "maximize"
        }
    }

    var body: some View {
        let imageName = (isHovered || isLocalHovered) ? "\(assetBaseName)-hover" : "\(assetBaseName)-normal"
        Group {
            if let nsImage = NSImage(named: imageName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: buttonSize, height: buttonSize)
                    .brightness(isPressed ? -0.2 : 0)
            } else {
                Circle()
                    .fill(Color.red)
                    .frame(width: buttonSize, height: buttonSize)
            }
        }
        .contentShape(Circle())
        .onHover { hovering in
            isLocalHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                    performAction()
                }
        )
    }

    private func performAction() {
        guard let window = NSApp.keyWindow else { return }
        switch type {
        case .close:
            window.performClose(nil)
        case .minimize:
            window.miniaturize(nil)
        case .zoom:
            window.zoom(nil)
        }
    }
}

// Placeholder button for when not hovering
struct PlaceholderWindowButton: View {
    var body: some View {
        Circle()
            .fill(Color(red: 0.85, green: 0.92, blue: 0.98))
            .frame(width: 12, height: 12)
    }
}
