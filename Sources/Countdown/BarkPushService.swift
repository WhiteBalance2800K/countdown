import Foundation

enum BarkPushService {
    static func send(pushAddress: String, itemName: String, daysUntilExpiry: Int) async throws {
        guard let url = pushURL(pushAddress: pushAddress, itemName: itemName, daysUntilExpiry: daysUntilExpiry) else {
            throw BarkPushError.invalidAddress
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 12

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw BarkPushError.requestFailed
        }
    }

    private static func pushURL(pushAddress: String, itemName: String, daysUntilExpiry: Int) -> URL? {
        let trimmed = pushAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard var base = URL(string: trimmed) else { return nil }

        let title = "Countdown"
        let body: String
        if daysUntilExpiry == 0 {
            body = "\(itemName) 今天到期"
        } else {
            body = "\(itemName) \(daysUntilExpiry) 天后到期"
        }

        base.appendPathComponent(title)
        base.appendPathComponent(body)
        return base
    }
}

enum BarkPushError: Error {
    case invalidAddress
    case requestFailed
}
