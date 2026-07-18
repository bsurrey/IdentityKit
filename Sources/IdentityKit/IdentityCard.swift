//
//  IdentityCard.swift
//  IdentityKit
//
//  A reusable "identity" card for editing an entity's name, icon, and color in
//  one place. A live icon preview sits beside a clearly editable name field,
//  followed by a single "Appearance" row that opens one combined color + icon
//  picker (`AppearancePickerSheet`). Keeping appearance behind one row keeps the
//  card compact while the picker stays full-height and usable in a single step.
//

import GlassIconKit
import SwiftUI

/// The "enter a name, pick a color, pick an icon" unit: a compact card with a
/// live icon preview, a name field, and a disclosure row into an
/// ``AppearancePickerSheet``.
///
/// The card binds to three values — the entity's name and the stable ids of
/// its color and icon — exactly what a typical model persists:
///
/// ```swift
/// @State private var name = ""
/// @State private var colorID = "blue"
/// @State private var iconID = "star"
///
/// IdentityCard(
///     name: $name,
///     selectedColorID: $colorID,
///     selectedIconID: $iconID,
///     colors: palette,
///     icons: catalog
/// )
/// ```
///
/// Tapping the preview or the appearance row opens the combined picker; the
/// row's trailing summary mirrors the two current choices live. Pass
/// `nameError` to surface validation feedback under the field, and
/// `onNameEdit` to be told the user started typing (e.g. to begin validating).
///
/// The preview tile defaults to ``DefaultPreviewTile`` (GlassIconKit-styled);
/// inject a `previewTile` closure to render your app's own icon component
/// from the resolved ``PreviewTileConfiguration``. The same tile builder is
/// reused by the picker's hero, at its larger metrics.
///
/// The card mutates only its bindings — no hidden persistence. To track
/// "recently used" colors or icons, observe the bindings from outside (e.g.
/// with `onChange`).
public struct IdentityCard<PreviewTile: View>: View {
    @Binding private var name: String
    @Binding private var selectedColorID: PaletteColor.ID
    @Binding private var selectedIconID: IconOption.ID

    private let colors: [PaletteColor]
    private let icons: [IconOption]
    private let nameError: String?
    private let onNameEdit: () -> Void
    private let namePlaceholder: LocalizedStringKey
    private let appearanceTitle: LocalizedStringKey
    private let fallbackSymbolName: String
    private let defaultIconOption: DefaultIconOption?
    private let previewTile: (PreviewTileConfiguration) -> PreviewTile

    @FocusState private var isNameFocused: Bool
    @State private var showAppearancePicker = false

    @AppStorage(IconStyle.roundIconsKey) private var roundIcons = IconStyle.roundIconsDefault
    @AppStorage(VisualEffectStyle.gradientsEnabledKey)
    private var gradientsEnabled = VisualEffectStyle.gradientsEnabledDefault

    /// Creates an identity card with a custom preview tile.
    ///
    /// - Parameters:
    ///   - name: Binding to the entity's name.
    ///   - selectedColorID: Binding to the selected color's stable id.
    ///   - selectedIconID: Binding to the selected icon's stable id.
    ///   - colors: The palette offered by the picker.
    ///   - icons: The icon catalog offered by the picker (exclude any
    ///     "no icon" sentinel; model it with `defaultIconOption` instead).
    ///   - nameError: Validation message shown under the name field, or `nil`.
    ///   - onNameEdit: Called whenever the user edits the name.
    ///   - namePlaceholder: Placeholder for the name field, resolved against
    ///     the host app's strings.
    ///   - appearanceTitle: Title for the appearance row, its accessibility
    ///     label, and the picker sheet.
    ///   - fallbackSymbolName: Glyph previewed when the icon selection matches
    ///     no catalog entry.
    ///   - defaultIconOption: Optional explicit "default / no icon" row in the
    ///     picker.
    ///   - previewTile: Renders the live preview from the resolved selection.
    public init(
        name: Binding<String>,
        selectedColorID: Binding<PaletteColor.ID>,
        selectedIconID: Binding<IconOption.ID>,
        colors: [PaletteColor],
        icons: [IconOption],
        nameError: String? = nil,
        onNameEdit: @escaping () -> Void = {},
        namePlaceholder: LocalizedStringKey = "Name",
        appearanceTitle: LocalizedStringKey = "Appearance",
        fallbackSymbolName: String = "star.fill",
        defaultIconOption: DefaultIconOption? = nil,
        @ViewBuilder previewTile: @escaping (PreviewTileConfiguration) -> PreviewTile
    ) {
        self._name = name
        self._selectedColorID = selectedColorID
        self._selectedIconID = selectedIconID
        self.colors = colors
        self.icons = icons
        self.nameError = nameError
        self.onNameEdit = onNameEdit
        self.namePlaceholder = namePlaceholder
        self.appearanceTitle = appearanceTitle
        self.fallbackSymbolName = fallbackSymbolName
        self.defaultIconOption = defaultIconOption
        self.previewTile = previewTile
    }

    // MARK: - Selection resolution

    private var color: Color {
        colors.resolved(id: selectedColorID)?.color ?? .accentColor
    }

    /// A missing/unknown icon falls back to the caller's generic glyph.
    private var symbolName: String {
        icons.option(id: selectedIconID)?.symbolName ?? fallbackSymbolName
    }

    /// Circle when "Round Icons" is on, otherwise a rounded square — the summary
    /// swatch previews the same tile shape the entity's icon will use.
    private var swatchShape: AnyShape {
        roundIcons
            ? AnyShape(Circle())
            : AnyShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.bottom, 16)

            Divider()

            appearanceRow
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .sheet(isPresented: $showAppearancePicker) {
            AppearancePickerSheet(
                colors: colors,
                icons: icons,
                selectedColorID: $selectedColorID,
                selectedIconID: $selectedIconID,
                title: appearanceTitle,
                fallbackSymbolName: fallbackSymbolName,
                defaultIconOption: defaultIconOption,
                previewTile: previewTile
            )
        }
    }

    // MARK: - Header (preview + name)

    private var header: some View {
        HStack(spacing: 14) {
            // Tapping the preview is a natural shortcut into the appearance picker.
            Button {
                showAppearancePicker = true
            } label: {
                previewTile(
                    PreviewTileConfiguration(color: color, symbolName: symbolName, size: 56, glyphSize: 26)
                )
                .identityAnimation(.snappy, value: selectedColorID)
                .identityAnimation(.snappy, value: selectedIconID)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(appearanceTitle))

            VStack(alignment: .leading, spacing: 6) {
                // A visible filled field makes it obvious this is editable — a
                // borderless title alone reads as static text.
                TextField(namePlaceholder, text: $name)
                    .font(.title3.weight(.semibold))
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .onChange(of: name) { onNameEdit() }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if let nameError {
                    Text(nameError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.leading, 4)
                }
            }
        }
    }

    // MARK: - Appearance row

    /// A native-style disclosure row (no nested fill) separated from the header by
    /// a hairline. Its trailing summary mirrors the two current choices live, so
    /// the row reads as both a label and a value.
    private var appearanceRow: some View {
        Button { showAppearancePicker = true } label: {
            HStack(spacing: 12) {
                Text(appearanceTitle)
                    .foregroundStyle(.primary)

                Spacer(minLength: 12)

                HStack(spacing: 6) {
                    // Swatch shape mirrors the "Round Icons" preference, like the tiles.
                    swatchShape
                        .fill(gradientsEnabled ? AnyShapeStyle(color.gradient) : AnyShapeStyle(color))
                        .frame(width: 20, height: 20)

                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.tertiary)

                    Image(systemName: symbolName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(color)
                }
                .identityAnimation(.snappy, value: selectedColorID)
                .identityAnimation(.snappy, value: selectedIconID)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(appearanceTitle))
    }
}

extension IdentityCard where PreviewTile == DefaultPreviewTile {
    /// Creates an identity card using the built-in ``DefaultPreviewTile``.
    ///
    /// See ``init(name:selectedColorID:selectedIconID:colors:icons:nameError:onNameEdit:namePlaceholder:appearanceTitle:fallbackSymbolName:defaultIconOption:previewTile:)``
    /// for parameter details.
    public init(
        name: Binding<String>,
        selectedColorID: Binding<PaletteColor.ID>,
        selectedIconID: Binding<IconOption.ID>,
        colors: [PaletteColor],
        icons: [IconOption],
        nameError: String? = nil,
        onNameEdit: @escaping () -> Void = {},
        namePlaceholder: LocalizedStringKey = "Name",
        appearanceTitle: LocalizedStringKey = "Appearance",
        fallbackSymbolName: String = "star.fill",
        defaultIconOption: DefaultIconOption? = nil
    ) {
        self.init(
            name: name,
            selectedColorID: selectedColorID,
            selectedIconID: selectedIconID,
            colors: colors,
            icons: icons,
            nameError: nameError,
            onNameEdit: onNameEdit,
            namePlaceholder: namePlaceholder,
            appearanceTitle: appearanceTitle,
            fallbackSymbolName: fallbackSymbolName,
            defaultIconOption: defaultIconOption,
            previewTile: { DefaultPreviewTile(configuration: $0) }
        )
    }
}

// MARK: - Previews

#Preview("Identity Card") {
    @Previewable @State var name = "Health & Fitness"
    @Previewable @State var colorID = "orange"
    @Previewable @State var iconID = "heart"

    ScrollView {
        IdentityCard(
            name: $name,
            selectedColorID: $colorID,
            selectedIconID: $iconID,
            colors: PaletteColor.previewPalette,
            icons: IconOption.previewCatalog
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Empty + Error + Default Icon") {
    @Previewable @State var name = ""
    @Previewable @State var colorID = "blue"
    @Previewable @State var iconID = "none"

    ScrollView {
        IdentityCard(
            name: $name,
            selectedColorID: $colorID,
            selectedIconID: $iconID,
            colors: PaletteColor.previewPalette,
            icons: IconOption.previewCatalog,
            nameError: "Give it a name",
            fallbackSymbolName: "rectangle.3.group.fill",
            defaultIconOption: DefaultIconOption(id: "none")
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Custom Preview Tile") {
    @Previewable @State var name = "Reading"
    @Previewable @State var colorID = "indigo"
    @Previewable @State var iconID = "book"

    ScrollView {
        IdentityCard(
            name: $name,
            selectedColorID: $colorID,
            selectedIconID: $iconID,
            colors: PaletteColor.previewPalette,
            icons: IconOption.previewCatalog
        ) { configuration in
            // Any view works here — this one trades the glass tile for a plain circle.
            Circle()
                .fill(configuration.color.gradient)
                .frame(width: configuration.size, height: configuration.size)
                .overlay {
                    Image(systemName: configuration.symbolName)
                        .font(.system(size: configuration.glyphSize, weight: .semibold))
                        .foregroundStyle(.white)
                }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Dark") {
    @Previewable @State var name = "Game Night"
    @Previewable @State var colorID = "purple"
    @Previewable @State var iconID = "trophy"

    ScrollView {
        IdentityCard(
            name: $name,
            selectedColorID: $colorID,
            selectedIconID: $iconID,
            colors: PaletteColor.previewPalette,
            icons: IconOption.previewCatalog
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
