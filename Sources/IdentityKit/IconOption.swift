//
//  IconOption.swift
//  IdentityKit
//

import SwiftUI

/// One selectable icon in an identity icon catalog.
///
/// Like ``PaletteColor``, this decouples the kit from your app's icon enum:
/// each option pairs a **stable `id` string** (what the selection binding
/// stores) with the SF Symbol to draw and a localized display title.
///
/// ```swift
/// let icons: [IconOption] = [
///     IconOption(id: "star", symbolName: "star.fill", title: "Star"),
///     IconOption(id: "heart", symbolName: "heart.fill", title: "Heart"),
/// ]
/// ```
public struct IconOption: Identifiable, Hashable, Sendable {
    /// Stable identifier — the value written to the selection binding and the
    /// natural thing to persist.
    public let id: String

    /// SF Symbol name rendered in grids and previews.
    public let symbolName: String

    /// Human-readable, display-ready (already localized) name. Used for the
    /// picker's summary line and accessibility labels.
    public let title: String

    /// Creates an icon option.
    ///
    /// - Parameters:
    ///   - id: Stable identifier, safe to persist.
    ///   - symbolName: The SF Symbol to draw.
    ///   - title: Localized display name.
    public init(id: String, symbolName: String, title: String) {
        self.id = id
        self.symbolName = symbolName
        self.title = title
    }
}

/// An explicit "no specific icon" row offered above the icon grid.
///
/// Some entities fall back to a generic glyph when the user hasn't picked an
/// icon (a board, a folder, a tag). Pass a `DefaultIconOption` to
/// ``AppearancePickerSheet`` (or ``IdentityCard``) to surface that state as a
/// first-class choice: selecting the row writes ``id`` to the icon binding,
/// and the row renders the component's `fallbackSymbolName` glyph.
///
/// The selection counts as "default" whenever the bound icon id matches **no
/// entry** in the icon catalog — so stale or unknown persisted ids degrade to
/// the default state instead of a broken one.
public struct DefaultIconOption: Hashable, Sendable {
    /// The value written to the icon selection binding when the row is chosen
    /// (e.g. `"none"`).
    public let id: String

    /// Localized display title for the row. `nil` (the default) uses the
    /// kit's own localized "Default".
    public let title: String?

    /// Creates a default-icon row description.
    ///
    /// - Parameters:
    ///   - id: The selection value representing "no specific icon".
    ///   - title: Localized row title; `nil` uses the kit's built-in one.
    public init(id: String, title: String? = nil) {
        self.id = id
        self.title = title
    }
}

extension RandomAccessCollection where Element == IconOption {
    /// The entry matching `id`, or `nil` when the id is unknown — unknown ids
    /// intentionally resolve to no option so callers can fall back to their
    /// generic glyph.
    func option(id: String) -> IconOption? {
        first { $0.id == id }
    }
}
