import SwiftUI

enum RadixPalette {
    static func appBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.067, green: 0.067, blue: 0.067)
            : Color(red: 0.988, green: 0.988, blue: 0.988)
    }

    static func subtleBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.098, green: 0.098, blue: 0.098)
            : Color(red: 0.976, green: 0.976, blue: 0.976)
    }

    static func elementBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.133, green: 0.133, blue: 0.133)
            : Color(red: 0.941, green: 0.941, blue: 0.941)
    }

    static func hoverBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.165, green: 0.165, blue: 0.165)
            : Color(red: 0.910, green: 0.910, blue: 0.910)
    }

    static func border(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.282, green: 0.282, blue: 0.282)
            : Color(red: 0.808, green: 0.808, blue: 0.808)
    }

    static func borderHover(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.376, green: 0.376, blue: 0.376)
            : Color(red: 0.733, green: 0.733, blue: 0.733)
    }

    static func text(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.933, green: 0.933, blue: 0.933)
            : Color(red: 0.125, green: 0.125, blue: 0.125)
    }

    static func mutedText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.706, green: 0.706, blue: 0.706)
            : Color(red: 0.392, green: 0.392, blue: 0.392)
    }

    static func faintText(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.482, green: 0.482, blue: 0.482)
            : Color(red: 0.514, green: 0.514, blue: 0.514)
    }

    static func accentSolid(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 1.000, green: 0.592, blue: 0.200)
            : Color(red: 0.969, green: 0.384, blue: 0.051)
    }

    static func accentElement(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.310, green: 0.145, blue: 0.043)
            : Color(red: 1.000, green: 0.933, blue: 0.878)
    }

    static func dangerSolid(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 1.000, green: 0.388, blue: 0.337)
            : Color(red: 0.898, green: 0.141, blue: 0.153)
    }

    static func dangerElement(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.357, green: 0.098, blue: 0.086)
            : Color(red: 1.000, green: 0.918, blue: 0.914)
    }

    static func warningSolid(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 1.000, green: 0.773, blue: 0.259)
            : Color(red: 0.945, green: 0.588, blue: 0.000)
    }

    static func warningElement(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.306, green: 0.212, blue: 0.055)
            : Color(red: 1.000, green: 0.961, blue: 0.839)
    }

    static func successSolid(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.333, green: 0.812, blue: 0.467)
            : Color(red: 0.180, green: 0.639, blue: 0.290)
    }

    static func successElement(_ scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.086, green: 0.243, blue: 0.133)
            : Color(red: 0.910, green: 0.976, blue: 0.929)
    }
}
