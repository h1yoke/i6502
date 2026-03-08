import SwiftUI

enum AppTheme: Int {
    case defaultDark
    case defaultLight
    case civic

    var palette: ThemePalette {
        ThemePalette(theme: self)
    }
}

struct ThemePalette {
    let theme: AppTheme

    var backgroundPrimary: Color {
        colorForTheme("BackgroundPrimary")
    }

    var foregroundPrimary: Color {
        colorForTheme("ForegroundPrimary")
    }

    var directives: Color {
        colorForTheme("Directives")
    }

    var literals: Color {
        colorForTheme("Literals")
    }

    var labels: Color {
        colorForTheme("Labels")
    }

    var comments: Color {
        colorForTheme("Comments")
    }

    private func colorForTheme(_ colorName: String) -> Color {
        switch theme {
        case .defaultDark: Color(colorName + "+DefaultDark")
        case .defaultLight: Color(colorName + "+DefaultLight")
        case .civic: Color(colorName + "+Civic")
        }
    }

    private var bundle: Bundle? {
        switch theme {
        case .defaultDark: Bundle(identifier: "ThemeDefaultDark")
        case .defaultLight: Bundle(identifier: "ThemeDefaultLight")
        case .civic: Bundle(identifier: "ThemeCivic")
        }
    }
}
