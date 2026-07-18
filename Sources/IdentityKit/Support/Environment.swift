//
//  Environment.swift
//  IdentityKit
//
//  Host-app integration points for motion and haptics, plus the internal
//  modifier that folds them together with the system Reduce Motion setting.
//

import SwiftUI

extension EnvironmentValues {
    /// Whether IdentityKit components may play their selection and preview
    /// animations. Defaults to `true`.
    ///
    /// The system **Reduce Motion** accessibility setting is always honored
    /// on top of this value — animations play only when this is `true` *and*
    /// Reduce Motion is off. Set it from an app-level "animations" preference
    /// to keep the kit's components in step with the rest of your app:
    ///
    /// ```swift
    /// IdentityCard(...)
    ///     .environment(\.identityAnimationsEnabled, animationsPreference)
    /// ```
    @Entry public var identityAnimationsEnabled: Bool = true

    /// Whether IdentityKit components emit haptic selection feedback
    /// (via `sensoryFeedback`). Defaults to `true`.
    ///
    /// Set it from an app-level "haptics" preference to silence the kit
    /// together with the rest of your app:
    ///
    /// ```swift
    /// AppearancePickerSheet(...)
    ///     .environment(\.identityHapticsEnabled, hapticsPreference)
    /// ```
    @Entry public var identityHapticsEnabled: Bool = true
}

// MARK: - Internal motion gating

extension EnvironmentValues {
    /// Effective motion state: the host opt-in AND the system accessibility
    /// setting. Views use this for explicit `withAnimation` blocks.
    var identityMotionEnabled: Bool {
        identityAnimationsEnabled && !accessibilityReduceMotion
    }
}

private struct IdentityAnimationModifier<V: Equatable>: ViewModifier {
    let animation: Animation
    let value: V
    @Environment(\.identityMotionEnabled) private var motionEnabled

    func body(content: Content) -> some View {
        content.animation(motionEnabled ? animation : nil, value: value)
    }
}

extension View {
    /// `animation(_:value:)` gated by ``EnvironmentValues/identityAnimationsEnabled``
    /// and the system Reduce Motion setting.
    func identityAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        modifier(IdentityAnimationModifier(animation: animation, value: value))
    }
}
