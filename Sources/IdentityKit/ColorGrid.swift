//
//  ColorGrid.swift
//  IdentityKit
//

import GlassIconKit
import SwiftUI

/// An adaptive grid of color swatches with a single selection.
///
/// The grid binds to the **stable id** of the selected ``PaletteColor`` —
/// the same string you'd persist on a model — and draws a checkmark (in each
/// color's ``PaletteColor/contrastingForeground``) plus a same-color ring
/// around the current choice.
///
/// ```swift
/// @State private var colorID = "blue"
///
/// ColorGrid(colors: palette, selection: $colorID)
/// ```
///
/// Styling follows the shared GlassIconKit preferences: swatches are circles
/// when **Round Icons** is on (otherwise rounded squares matching the icon
/// tiles' proportions), and use a shaded gradient fill unless the shared
/// gradients preference is off. Selection plays a spring animation — gated by
/// ``EnvironmentValues/identityAnimationsEnabled`` and Reduce Motion — and
/// emits light impact feedback, gated by
/// ``EnvironmentValues/identityHapticsEnabled``.
public struct ColorGrid: View {
    private let colors: [PaletteColor]
    @Binding private var selection: PaletteColor.ID

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.identityMotionEnabled) private var motionEnabled
    @Environment(\.identityHapticsEnabled) private var hapticsEnabled

    @AppStorage(IconStyle.roundIconsKey) private var roundIcons = IconStyle.roundIconsDefault
    @AppStorage(VisualEffectStyle.gradientsEnabledKey)
    private var gradientsEnabled = VisualEffectStyle.gradientsEnabledDefault

    /// Creates a color grid.
    ///
    /// - Parameters:
    ///   - colors: The palette to offer, in display order.
    ///   - selection: Binding to the selected entry's stable id.
    public init(colors: [PaletteColor], selection: Binding<PaletteColor.ID>) {
        self.colors = colors
        self._selection = selection
    }

    // Larger swatches on iPad for better touch targets.
    private var swatchSize: CGFloat {
        horizontalSizeClass == .regular ? 52 : 44
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: swatchSize, maximum: 60), spacing: 12)]
    }

    /// Circle when "Round Icons" is on, otherwise a rounded square matching the
    /// icon tiles' proportions — so the swatches preview the actual tile shape.
    private var swatchShape: AnyShape {
        roundIcons
            ? AnyShape(Circle())
            : AnyShape(RoundedRectangle(cornerRadius: swatchSize * 0.25, style: .continuous))
    }

    /// Selection ring matching the swatch shape, expanded to leave a small gap.
    private var selectionRing: some View {
        let shape = roundIcons
            ? AnyShape(Circle())
            : AnyShape(RoundedRectangle(cornerRadius: swatchSize * 0.25 + 4, style: .continuous))
        return shape
            .stroke(lineWidth: 2.5)
            .padding(-4)
    }

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(colors) { color in
                let isSelected = selection == color.id

                Button {
                    withAnimation(motionEnabled ? .spring(response: 0.3, dampingFraction: 0.7) : nil) {
                        selection = color.id
                    }
                } label: {
                    swatchShape
                        .fill(gradientsEnabled ? AnyShapeStyle(color.color.gradient) : AnyShapeStyle(color.color))
                        .frame(width: swatchSize, height: swatchSize)
                        .overlay {
                            // Checkmark in a color that always contrasts the swatch,
                            // so it stays legible on light fills like yellow or mint.
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(color.contrastingForeground)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .overlay {
                            // A ring in the swatch's own color, separated by a small gap.
                            if isSelected {
                                selectionRing
                                    .foregroundStyle(color.color)
                            }
                        }
                        .scaleEffect(isSelected ? 1.04 : 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(color.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 8)
        .sensoryFeedback(.impact(weight: .light), trigger: selection) { _, _ in hapticsEnabled }
    }
}

// MARK: - Previews

#Preview("Color Grid") {
    @Previewable @State var selection = "blue"

    ColorGrid(colors: PaletteColor.previewPalette, selection: $selection)
        .padding()
}

/// A small demo palette shared by the package previews.
extension PaletteColor {
    static let previewPalette: [PaletteColor] = [
        PaletteColor(id: "blue", color: .blue, title: "Blue"),
        PaletteColor(id: "teal", color: .teal, title: "Teal"),
        PaletteColor(id: "green", color: .green, title: "Green"),
        PaletteColor(id: "yellow", color: .yellow, title: "Yellow"),
        PaletteColor(id: "orange", color: .orange, title: "Orange"),
        PaletteColor(id: "red", color: .red, title: "Red"),
        PaletteColor(id: "pink", color: .pink, title: "Pink"),
        PaletteColor(id: "purple", color: .purple, title: "Purple"),
        PaletteColor(id: "indigo", color: .indigo, title: "Indigo"),
        PaletteColor(id: "brown", color: .brown, title: "Brown"),
    ]
}
