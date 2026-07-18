//
//  PaletteColor.swift
//  IdentityKit
//

import SwiftUI

/// One selectable color in an identity palette.
///
/// IdentityKit never assumes anything about your app's color catalog — you
/// describe each entry with a `PaletteColor` and hand the kit an array. The
/// grids and pickers bind to the **stable `id` string**, which is what you'd
/// store on a model (`colorKey`-style), so renaming a display title or
/// re-tuning a `Color` never invalidates persisted data.
///
/// ```swift
/// let palette: [PaletteColor] = [
///     PaletteColor(id: "blue", color: .blue, title: "Blue"),
///     PaletteColor(id: "flame", color: Color(red: 1, green: 0.3, blue: 0), title: "Flame"),
/// ]
/// ```
///
/// `contrastingForeground` is the color used for content drawn *on top of* the
/// swatch — most visibly the selection checkmark. Omit it and the kit picks
/// black or white per appearance from the swatch's perceived luminance, so a
/// checkmark stays legible on light fills like yellow or mint. Pass your own
/// when your palette has hand-tuned contrast colors.
public struct PaletteColor: Identifiable, Hashable, Sendable {
    /// Stable identifier — the value written to the selection binding and the
    /// natural thing to persist.
    public let id: String

    /// The swatch fill.
    public let color: Color

    /// Human-readable, display-ready (already localized) name. Used for the
    /// picker's summary line and accessibility labels.
    public let title: String

    /// Color for content layered directly over ``color`` (e.g. the selection
    /// checkmark) — black or white by default, chosen per appearance.
    public let contrastingForeground: Color

    /// Creates a palette entry.
    ///
    /// - Parameters:
    ///   - id: Stable identifier, safe to persist.
    ///   - color: The swatch fill.
    ///   - title: Localized display name.
    ///   - contrastingForeground: Content color drawn over the swatch. `nil`
    ///     (the default) derives black or white from the swatch's perceived
    ///     luminance, resolved per light/dark appearance.
    public init(
        id: String,
        color: Color,
        title: String,
        contrastingForeground: Color? = nil
    ) {
        self.id = id
        self.color = color
        self.title = title
        self.contrastingForeground = contrastingForeground ?? color.contrastingMonochrome
    }
}

extension RandomAccessCollection where Element == PaletteColor {
    /// The entry matching `id`, falling back to the first entry — mirrors the
    /// forgiving "unknown key renders the default color" behavior expected
    /// from persisted keys that may outlive a palette revision.
    func resolved(id: String) -> PaletteColor? {
        first { $0.id == id } ?? first
    }
}
