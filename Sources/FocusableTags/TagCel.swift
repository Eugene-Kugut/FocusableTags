// TagCell.swift
import SwiftUI

struct TagCell<Label: View>: View {
    let label: () -> Label

    let isSelected: Bool
    let isFocused: Bool

    let selectedBackground: Color
    let focusedBackground: Color
    let hoveredBackground: Color

    let focusedOverlay: Color
    let focusedOverlayLineWidth: CGFloat
    let selectedOverlayColor: Color
    let overlayColor: Color
    let overlayLineWidth: CGFloat
    let contentInsets: NSEdgeInsets
    let cornerRadius: CGFloat
    let onClick: () -> Void

    @State private var isHovered = false

    var body: some View {
        label()
            .opacity(isFocused && isSelected ? 0.95 : 1)
            .lineLimit(1)
            .padding(.top, contentInsets.top)
            .padding(.bottom, contentInsets.bottom)
            .padding(.leading, contentInsets.left)
            .padding(.trailing, contentInsets.right)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isFocused ? focusedBackground : .clear)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isHovered ? hoveredBackground : .clear)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isSelected ? selectedBackground : .clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isFocused ? focusedOverlay : (isSelected ? selectedOverlayColor : overlayColor),
                        lineWidth: isFocused ? focusedOverlayLineWidth : overlayLineWidth
                    )
            }
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .onTapGesture {
                onClick()
            }
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
    }
}
