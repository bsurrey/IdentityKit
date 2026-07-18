//
//  Contrast.swift
//  IdentityKit
//
//  A small, self-contained luminance helper so selection checkmarks can pick
//  black or white content over an arbitrary swatch without the host app
//  providing a contrast color.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Pure contrast math, separated from UIKit so it can be unit-tested.
enum ContrastMath {
    /// Colors at or above this perceived brightness are treated as "light"
    /// and get dark content on top; darker colors get white content.
    static let lightThreshold: Double = 0.6

    /// Perceived brightness, 0 (black) … 1 (white) — Rec. 601 luma weights on
    /// gamma-encoded sRGB components. Components are clamped so extended-sRGB
    /// (wide gamut) values can't push the result out of range.
    static func luminance(red: Double, green: Double, blue: Double) -> Double {
        func clamped(_ component: Double) -> Double { min(max(component, 0), 1) }
        return 0.299 * clamped(red) + 0.587 * clamped(green) + 0.114 * clamped(blue)
    }

    /// Whether content drawn over a fill of the given luminance should be
    /// dark (black) rather than light (white).
    static func prefersDarkContent(luminance: Double) -> Bool {
        luminance > lightThreshold
    }
}

extension Color {
    /// Black or white, whichever contrasts with this color — resolved per
    /// trait collection so it tracks light/dark appearances automatically.
    /// This is the default ``PaletteColor/contrastingForeground``.
    var contrastingMonochrome: Color {
        #if canImport(UIKit)
        Color(
            UIColor { traits in
                let resolved = UIColor(self).resolvedColor(with: traits)
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                guard resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                    return .white
                }
                let luminance = ContrastMath.luminance(red: red, green: green, blue: blue)
                return ContrastMath.prefersDarkContent(luminance: luminance) ? .black : .white
            }
        )
        #else
        // No UIKit (not a supported platform today): assume a dark fill.
        return .white
        #endif
    }
}
