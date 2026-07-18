//
//  IconGrid.swift
//  IdentityKit
//

import GlassIconKit
import SwiftUI

/// An adaptive grid of SF Symbol tiles with a single selection.
///
/// The grid binds to the **stable id** of the selected ``IconOption``. Only
/// the selected tile renders as a live `GlassIcon` in the given tint — a real
/// preview that honors the Candy Mode / Round Icons preferences — while the
/// rest stay flat neutral tiles, which reads as selectable and keeps the grid
/// down to a single (expensive) Liquid Glass effect.
///
/// ```swift
/// @State private var iconID = "star"
///
/// IconGrid(icons: catalog, selection: $iconID, tint: .orange)
/// ```
///
/// The grid shows exactly the options you pass — filter out any "no icon"
/// sentinel your model uses and represent it with ``DefaultIconOption`` in
/// ``AppearancePickerSheet`` instead. Selection animation and haptics are
/// gated by ``EnvironmentValues/identityAnimationsEnabled`` and
/// ``EnvironmentValues/identityHapticsEnabled``.
public struct IconGrid: View {
    private let icons: [IconOption]
    @Binding private var selection: IconOption.ID
    private let tint: Color

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.identityMotionEnabled) private var motionEnabled
    @Environment(\.identityHapticsEnabled) private var hapticsEnabled

    @AppStorage(IconStyle.roundIconsKey) private var roundIcons = IconStyle.roundIconsDefault

    /// Creates an icon grid.
    ///
    /// - Parameters:
    ///   - icons: The options to offer, in display order.
    ///   - selection: Binding to the selected option's stable id.
    ///   - tint: Color of the selected tile and its selection ring.
    public init(icons: [IconOption], selection: Binding<IconOption.ID>, tint: Color = .blue) {
        self.icons = icons
        self._selection = selection
        self.tint = tint
    }

    // Larger tiles on iPad for better touch targets.
    private var tileSize: CGFloat {
        horizontalSizeClass == .regular ? 52 : 44
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: tileSize, maximum: 60), spacing: 12)]
    }

    /// Circle when "Round Icons" is on, otherwise a rounded square matching
    /// GlassIcon's proportions — so the neutral tiles keep the same silhouette.
    private var tileShape: AnyShape {
        roundIcons
            ? AnyShape(Circle())
            : AnyShape(RoundedRectangle(cornerRadius: tileSize * 0.25, style: .continuous))
    }

    /// Selection ring matching the tile shape, expanded to leave a small gap.
    private var selectionRing: some View {
        let shape = roundIcons
            ? AnyShape(Circle())
            : AnyShape(RoundedRectangle(cornerRadius: tileSize * 0.25 + 4, style: .continuous))
        return shape
            .stroke(tint, lineWidth: 2)
            .padding(-4)
    }

    public var body: some View {
        // No GlassEffectContainer here: it re-renders the glass tile's content
        // in a shared layer, which swallows GlassIcon's glyph overlay. Only the
        // selected tile uses glass, so there's nothing to batch anyway.
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(icons) { icon in
                let isSelected = selection == icon.id

                Button {
                    withAnimation(motionEnabled ? .spring(response: 0.3, dampingFraction: 0.7) : nil) {
                        selection = icon.id
                    }
                } label: {
                    if isSelected {
                        GlassIcon(icon.symbolName, tint: tint, size: tileSize)
                            .overlay { selectionRing }
                    } else {
                        tileShape
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: tileSize, height: tileSize)
                            .overlay {
                                Image(systemName: icon.symbolName)
                                    .font(.system(size: tileSize * GlassIcon.defaultGlyphScale, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(icon.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.vertical, 8)
        .sensoryFeedback(.impact(weight: .light), trigger: selection) { _, _ in hapticsEnabled }
    }
}

// MARK: - Previews

#Preview("Icon Grid") {
    @Previewable @State var selection = "star"

    IconGrid(icons: IconOption.previewCatalog, selection: $selection, tint: .orange)
        .padding()
}

/// A small demo catalog shared by the package previews.
extension IconOption {
    static let previewCatalog: [IconOption] = [
        IconOption(id: "star", symbolName: "star.fill", title: "Star"),
        IconOption(id: "heart", symbolName: "heart.fill", title: "Heart"),
        IconOption(id: "flame", symbolName: "flame.fill", title: "Flame"),
        IconOption(id: "bolt", symbolName: "bolt.fill", title: "Bolt"),
        IconOption(id: "leaf", symbolName: "leaf.fill", title: "Leaf"),
        IconOption(id: "drop", symbolName: "drop.fill", title: "Drop"),
        IconOption(id: "book", symbolName: "book.fill", title: "Book"),
        IconOption(id: "bell", symbolName: "bell.fill", title: "Bell"),
        IconOption(id: "trophy", symbolName: "trophy.fill", title: "Trophy"),
        IconOption(id: "moon", symbolName: "moon.stars.fill", title: "Moon"),
    ]
}
