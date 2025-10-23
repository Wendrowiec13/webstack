import SwiftUI

struct HoverButton: View {
    let action: () -> Void
    let icon: String
    let disabled: Bool
    let paddingEdges: EdgeInsets
    let fontSize: CGFloat

    @State private var isHovering = false

    init(
        action: @escaping () -> Void,
        icon: String,
        disabled: Bool,
        padding: CGFloat = 6,
        fontSize: CGFloat = 16
    ) {
        self.action = action
        self.icon = icon
        self.disabled = disabled
        self.paddingEdges = EdgeInsets(top: padding, leading: padding, bottom: padding, trailing: padding)
        self.fontSize = fontSize
    }

    init(
        action: @escaping () -> Void,
        icon: String,
        disabled: Bool,
        top: CGFloat = 6,
        leading: CGFloat = 6,
        bottom: CGFloat = 6,
        trailing: CGFloat = 6,
        fontSize: CGFloat = 16
    ) {
        self.action = action
        self.icon = icon
        self.disabled = disabled
        self.paddingEdges = EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
        self.fontSize = fontSize
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: fontSize))
                .foregroundColor(disabled ? .black.opacity(0.5) : .primary)
                .padding(paddingEdges)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovering && !disabled ? Color.black.opacity(0.08) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
