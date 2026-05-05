import Foundation

enum DateFormatters {
    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        // Fixed-format for display: 2026年3月15日
        f.locale = Locale(identifier: "zh_CN")
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = .current
        f.dateFormat = "yyyy年M月d日"
        return f
    }()

    static func shortDateString(from date: Date, language: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language.localeIdentifier)
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current

        switch language {
        case .simplifiedChinese:
            formatter.dateFormat = "yyyy年M月d日"
        case .japanese:
            formatter.dateFormat = "yyyy年M月d日"
        default:
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
        }

        return formatter.string(from: date)
    }
}
