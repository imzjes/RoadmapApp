import SwiftUI
import UIKit

enum Theme {
    enum Accent {
        static let moss = Color(red: 0x5C / 255, green: 0x8B / 255, blue: 0x5A / 255)
        static let mossSoft = Color(red: 0xED / 255, green: 0xF2 / 255, blue: 0xEC / 255)
        static let mossMid = Color(red: 0xBB / 255, green: 0xCF / 255, blue: 0xB6 / 255)
        static let mossStrong = Color(red: 0x4A / 255, green: 0x75 / 255, blue: 0x48 / 255)
        static let mossDeep = Color(red: 0x38 / 255, green: 0x5C / 255, blue: 0x36 / 255)
    }

    static let accent = Color.accentColor
    static let accentSoft = Accent.mossSoft
    static let accentMid = Accent.mossMid
    static let accentStrong = Accent.mossStrong

    enum Stage {
        static let intakeBG = Color(red: 120/255, green: 120/255, blue: 128/255).opacity(0.14)
        static let intakeFG = Color(red: 60/255, green: 60/255, blue: 67/255).opacity(0.85)
        static let assessBG = Color(red: 212/255, green: 184/255, blue: 128/255).opacity(0.22)
        static let assessFG = Color(red: 0x7A/255, green: 0x5B/255, blue: 0x1E/255)
        static let generateBG = Color(red: 92/255, green: 139/255, blue: 90/255).opacity(0.18)
        static let generateFG = Accent.mossStrong
        static let enrichBG = Color(red: 120/255, green: 90/255, blue: 160/255).opacity(0.16)
        static let enrichFG = Color(red: 0x5E/255, green: 0x44/255, blue: 0x93/255)
        static let reviseBG = Color(red: 60/255, green: 140/255, blue: 180/255).opacity(0.16)
        static let reviseFG = Color(red: 0x1F/255, green: 0x6F/255, blue: 0x92/255)
    }

    enum Surface {
        static let card = Color(uiColor: .secondarySystemGroupedBackground)
        static let groupedBG = Color(uiColor: .systemGroupedBackground)
    }

    enum Radius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 16
        static let xl: CGFloat = 22
        static let xxl: CGFloat = 28
    }

    enum Space {
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 20
        static let s6: CGFloat = 24
        static let s7: CGFloat = 32
        static let s8: CGFloat = 40
    }
}

extension View {
    func appBackground() -> some View {
        background(
            LinearGradient(
                colors: [
                    Theme.Accent.mossSoft.opacity(0.55),
                    Color(uiColor: .systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
    }
}
