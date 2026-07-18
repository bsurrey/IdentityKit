//
//  IdentityKitTests.swift
//  IdentityKit
//
//  Covers the package's pure logic: catalog id resolution and the contrast
//  math behind the default `contrastingForeground`.
//

import SwiftUI
import Testing
@testable import IdentityKit

@Suite("Palette resolution")
struct PaletteResolutionTests {
    private let palette: [PaletteColor] = [
        PaletteColor(id: "blue", color: .blue, title: "Blue"),
        PaletteColor(id: "red", color: .red, title: "Red"),
    ]

    @Test("A known id resolves to its entry")
    func knownID() {
        #expect(palette.resolved(id: "red")?.id == "red")
    }

    @Test("An unknown id falls back to the first entry")
    func unknownIDFallsBack() {
        #expect(palette.resolved(id: "chartreuse")?.id == "blue")
    }

    @Test("An empty palette resolves to nil")
    func emptyPalette() {
        #expect([PaletteColor]().resolved(id: "blue") == nil)
    }
}

@Suite("Icon resolution")
struct IconResolutionTests {
    private let catalog: [IconOption] = [
        IconOption(id: "star", symbolName: "star.fill", title: "Star"),
        IconOption(id: "heart", symbolName: "heart.fill", title: "Heart"),
    ]

    @Test("A known id resolves to its option")
    func knownID() {
        #expect(catalog.option(id: "heart")?.symbolName == "heart.fill")
    }

    @Test("An unknown id resolves to nil so callers fall back to their generic glyph")
    func unknownIDIsNil() {
        #expect(catalog.option(id: "none") == nil)
        #expect(catalog.option(id: "") == nil)
    }
}

@Suite("Contrast math")
struct ContrastMathTests {
    @Test("Luminance spans 0 (black) to 1 (white)")
    func extremes() {
        #expect(ContrastMath.luminance(red: 0, green: 0, blue: 0) == 0)
        #expect(abs(ContrastMath.luminance(red: 1, green: 1, blue: 1) - 1) < 0.0001)
    }

    @Test("Green dominates the perceived brightness weighting")
    func greenWeighting() {
        let green = ContrastMath.luminance(red: 0, green: 1, blue: 0)
        let red = ContrastMath.luminance(red: 1, green: 0, blue: 0)
        let blue = ContrastMath.luminance(red: 0, green: 0, blue: 1)
        #expect(green > red)
        #expect(red > blue)
    }

    @Test("Out-of-gamut extended-sRGB components are clamped into range")
    func clamping() {
        let luminance = ContrastMath.luminance(red: 1.4, green: -0.2, blue: 0.5)
        #expect(luminance >= 0 && luminance <= 1)
    }

    @Test("Light fills get dark content; dark fills get light content")
    func contentChoice() {
        // A white-ish fill (e.g. selected swatch in yellow/mint territory).
        #expect(ContrastMath.prefersDarkContent(luminance: 0.9))
        // A saturated dark fill keeps white content.
        #expect(!ContrastMath.prefersDarkContent(luminance: 0.3))
        // The threshold itself is treated as dark-enough for white content.
        #expect(!ContrastMath.prefersDarkContent(luminance: ContrastMath.lightThreshold))
    }
}
