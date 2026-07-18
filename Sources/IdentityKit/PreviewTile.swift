//
//  PreviewTile.swift
//  IdentityKit
//
//  The customization point for the live preview tile shown in the card header
//  and the picker's hero banner, plus the GlassIconKit-based default.
//

import GlassIconKit
import SwiftUI

/// The resolved appearance handed to a custom preview tile.
///
/// ``IdentityCard`` and ``AppearancePickerSheet`` build one of these whenever
/// they render their live preview: the currently selected color, the symbol
/// to draw (already resolved — an unknown or "default" icon selection has
/// been replaced by the caller's `fallbackSymbolName`), and the tile metrics
/// for the spot being rendered (the card header uses a smaller tile than the
/// picker's hero banner).
///
/// A custom tile should honor `size`/`glyphSize` so both spots keep their
/// proportions:
///
/// ```swift
/// IdentityCard(...) { configuration in
///     MyIconTile(
///         color: configuration.color,
///         symbol: configuration.symbolName,
///         side: configuration.size,
///         glyphPointSize: configuration.glyphSize
///     )
/// }
/// ```
public struct PreviewTileConfiguration: Hashable, Sendable {
    /// The selected palette color.
    public let color: Color

    /// The SF Symbol to draw — already resolved to the fallback glyph when no
    /// specific icon is selected.
    public let symbolName: String

    /// Side length of the square tile, in points.
    public let size: CGFloat

    /// Point size for the glyph.
    public let glyphSize: CGFloat
}

/// The built-in preview tile: a ``GlassIcon`` in the selected color with a
/// soft, color-matched drop shadow.
///
/// Used automatically when you don't inject a custom tile, so standalone
/// adopters get a finished look with zero extra code. It inherits every
/// GlassIconKit styling preference — Candy Mode, Round Icons, gradients —
/// and drops its decorative shadow when the shared
/// `VisualEffectStyle.shadowsEnabledKey` preference is off.
public struct DefaultPreviewTile: View {
    private let configuration: PreviewTileConfiguration

    @AppStorage(VisualEffectStyle.shadowsEnabledKey)
    private var shadowsEnabled = VisualEffectStyle.shadowsEnabledDefault

    /// Creates the default tile for a resolved preview configuration.
    public init(configuration: PreviewTileConfiguration) {
        self.configuration = configuration
    }

    public var body: some View {
        GlassIcon(
            configuration.symbolName,
            tint: configuration.color,
            size: configuration.size,
            glyphScale: configuration.size > 0 ? configuration.glyphSize / configuration.size : 0,
            gradient: true
        )
        .shadow(
            color: shadowsEnabled ? configuration.color.opacity(0.25) : .clear,
            radius: 6,
            x: 0,
            y: 3
        )
    }
}
