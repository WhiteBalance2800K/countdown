import Foundation

enum V06Text {
    static func text(_ key: String, _ language: AppLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            return zh[key] ?? en[key] ?? key
        default:
            return en[key] ?? key
        }
    }

    private static let zh: [String: String] = [
        "data": "数据",
        "openDataFolder": "打开数据文件夹",
        "openBackupFolder": "打开备份文件夹",
    ]

    private static let en: [String: String] = [
        "data": "Data",
        "openDataFolder": "Open Data Folder",
        "openBackupFolder": "Open Backup Folder",
    ]
}
