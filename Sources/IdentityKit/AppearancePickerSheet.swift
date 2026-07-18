//
//  AppearancePickerSheet.swift
//  IdentityKit
//

import SwiftUI

/// A single full-height sheet that edits both color and icon, with a live,
/// color-tinted preview at the top.
///
/// The sheet stacks a hero banner (the preview tile plus a "Color · Icon"
/// summary), a ``ColorGrid``, and an ``IconGrid`` — one step, no nested
/// pickers. Both grids bind to stable id strings, so the sheet is driven by
/// exactly the two values you'd persist:
///
/// ```swift
/// .sheet(isPresented: $showPicker) {
///     AppearancePickerSheet(
///         colors: palette,
///         icons: catalog,
///         selectedColorID: $colorID,
///         selectedIconID: $iconID
///     )
/// }
/// ```
///
/// Pass a ``DefaultIconOption`` to offer an explicit "no specific icon" row
/// above the grid; while it is selected (or the bound id matches no catalog
/// entry) the preview falls back to `fallbackSymbolName`. Inject a custom
/// `previewTile` to render the hero with your app's own icon component; the
/// default is ``DefaultPreviewTile``.
///
/// The sheet presents itself at the `.large` detent so everything is usable
/// immediately — no expand step. Section titles and the Done button are
/// localized by the package (English, German, Spanish, French, Japanese);
/// `title` is a `LocalizedStringKey` resolved against *your* app's catalog.
public struct AppearancePickerSheet<PreviewTile: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.identityMotionEnabled) private var motionEnabled

    private let colors: [PaletteColor]
    private let icons: [IconOption]
    @Binding private var selectedColorID: PaletteColor.ID
    @Binding private var selectedIconID: IconOption.ID
    private let title: LocalizedStringKey
    private let fallbackSymbolName: String
    private let defaultIconOption: DefaultIconOption?
    private let previewTile: (PreviewTileConfiguration) -> PreviewTile

    /// Creates an appearance picker with a custom preview tile.
    ///
    /// - Parameters:
    ///   - colors: The palette to offer.
    ///   - icons: The icon catalog to offer (exclude any "no icon" sentinel;
    ///     model it with `defaultIconOption` instead).
    ///   - selectedColorID: Binding to the selected color's stable id.
    ///   - selectedIconID: Binding to the selected icon's stable id.
    ///   - title: Navigation title, resolved against the host app's strings.
    ///   - fallbackSymbolName: Glyph previewed when the icon selection matches
    ///     no catalog entry.
    ///   - defaultIconOption: Optional explicit "default / no icon" row.
    ///   - previewTile: Renders the hero preview from the resolved selection.
    public init(
        colors: [PaletteColor],
        icons: [IconOption],
        selectedColorID: Binding<PaletteColor.ID>,
        selectedIconID: Binding<IconOption.ID>,
        title: LocalizedStringKey = "Appearance",
        fallbackSymbolName: String = "star.fill",
        defaultIconOption: DefaultIconOption? = nil,
        @ViewBuilder previewTile: @escaping (PreviewTileConfiguration) -> PreviewTile
    ) {
        self.colors = colors
        self.icons = icons
        self._selectedColorID = selectedColorID
        self._selectedIconID = selectedIconID
        self.title = title
        self.fallbackSymbolName = fallbackSymbolName
        self.defaultIconOption = defaultIconOption
        self.previewTile = previewTile
    }

    // MARK: - Selection resolution

    private var selectedColor: PaletteColor? {
        colors.resolved(id: selectedColorID)
    }

    private var color: Color {
        selectedColor?.color ?? .accentColor
    }

    private var selectedIcon: IconOption? {
        icons.option(id: selectedIconID)
    }

    /// A missing/unknown icon falls back to the caller's generic glyph.
    private var symbolName: String {
        selectedIcon?.symbolName ?? fallbackSymbolName
    }

    /// Caption under the hero — the human-readable names of both choices.
    private var summary: String {
        let colorTitle = selectedColor?.title ?? ""
        let iconTitle = selectedIcon?.title
            ?? defaultIconOption?.title
            ?? String(localized: "appearance.icon.default", bundle: #bundle)
        return "\(colorTitle) · \(iconTitle)"
    }

    // MARK: - Body

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hero

                    card(title: Text("appearance.color", bundle: #bundle)) {
                        ColorGrid(colors: colors, selection: $selectedColorID)
                    }

                    card(title: Text("appearance.icon", bundle: #bundle)) {
                        VStack(spacing: 12) {
                            if defaultIconOption != nil {
                                defaultIconButton
                            }
                            IconGrid(icons: icons, selection: $selectedIconID, tint: color)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("done.action", bundle: #bundle)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        // Open full-height so everything is usable immediately — no expand step.
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    /// Live preview on a soft, color-tinted banner, with the choice named below.
    private var hero: some View {
        VStack(spacing: 10) {
            previewTile(
                PreviewTileConfiguration(color: color, symbolName: symbolName, size: 64, glyphSize: 32)
            )
            .identityAnimation(.snappy, value: selectedColorID)
            .identityAnimation(.snappy, value: selectedIconID)

            Text(summary)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .animation(nil, value: selectedColorID)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .identityAnimation(.snappy, value: selectedColorID)
    }

    /// "No icon" → the entity falls back to its generic glyph.
    private var defaultIconButton: some View {
        let isSelected = selectedIcon == nil
        return Button {
            guard let defaultIconOption else { return }
            withAnimation(motionEnabled ? .snappy : nil) { selectedIconID = defaultIconOption.id }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: fallbackSymbolName)
                    .foregroundStyle(isSelected ? color : .secondary)
                if let title = defaultIconOption?.title {
                    Text(title)
                        .foregroundStyle(.primary)
                } else {
                    Text("appearance.icon.default", bundle: #bundle)
                        .foregroundStyle(.primary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? AnyShapeStyle(color.opacity(0.15)) : AnyShapeStyle(Color(.tertiarySystemFill)))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// A grouped card matching the identity card's visual language.
    @ViewBuilder
    private func card<Content: View>(title: Text, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            title
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension AppearancePickerSheet where PreviewTile == DefaultPreviewTile {
    /// Creates an appearance picker using the built-in ``DefaultPreviewTile``.
    ///
    /// See ``init(colors:icons:selectedColorID:selectedIconID:title:fallbackSymbolName:defaultIconOption:previewTile:)``
    /// for parameter details.
    public init(
        colors: [PaletteColor],
        icons: [IconOption],
        selectedColorID: Binding<PaletteColor.ID>,
        selectedIconID: Binding<IconOption.ID>,
        title: LocalizedStringKey = "Appearance",
        fallbackSymbolName: String = "star.fill",
        defaultIconOption: DefaultIconOption? = nil
    ) {
        self.init(
            colors: colors,
            icons: icons,
            selectedColorID: selectedColorID,
            selectedIconID: selectedIconID,
            title: title,
            fallbackSymbolName: fallbackSymbolName,
            defaultIconOption: defaultIconOption,
            previewTile: { DefaultPreviewTile(configuration: $0) }
        )
    }
}

// MARK: - Previews

#Preview("Appearance Picker Sheet") {
    @Previewable @State var colorID = "orange"
    @Previewable @State var iconID = "bolt"

    Color(.systemGroupedBackground)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AppearancePickerSheet(
                colors: PaletteColor.previewPalette,
                icons: IconOption.previewCatalog,
                selectedColorID: $colorID,
                selectedIconID: $iconID
            )
        }
}

#Preview("With Default Icon Row") {
    @Previewable @State var colorID = "purple"
    @Previewable @State var iconID = "none"

    Color(.systemGroupedBackground)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AppearancePickerSheet(
                colors: PaletteColor.previewPalette,
                icons: IconOption.previewCatalog,
                selectedColorID: $colorID,
                selectedIconID: $iconID,
                fallbackSymbolName: "rectangle.3.group.fill",
                defaultIconOption: DefaultIconOption(id: "none")
            )
        }
}
