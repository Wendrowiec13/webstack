import SwiftUI

struct TabItemView: View {
    let tab: Tab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false
    @State private var isCloseButtonHovering = false

    var body: some View {
        HStack(spacing: 8) {
            // Favicon or placeholder
            if let favicon = tab.favicon {
                Image(nsImage: favicon)
                    .resizable()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(width: 16, height: 16)
            }

            // Page title
            Text(tab.pageTitle.isEmpty ? "New Tab" : tab.pageTitle)
                .font(.system(size: 14))
                .foregroundColor(isActive ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .lineSpacing(0)
                .frame(height: 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(y: -1)

            // Close button (shown on hover)
            if isHovering {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isCloseButtonHovering ? Color.black.opacity(0.08) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isCloseButtonHovering = hovering
                }
            }
        }
        .padding(.leading, 6)
        .padding(.trailing, 4)
        .frame(height: 34)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isActive
                        ? Color(red: 0.85, green: 0.92, blue: 0.98)
                        : (isHovering ? Color.black.opacity(0.08) : Color.clear)
                )
                .shadow(
                    color: isActive ? Color.black.opacity(0.08) : Color.clear,
                    radius: 3,
                    x: 0,
                    y: 1
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
