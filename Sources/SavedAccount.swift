import Foundation

struct SavedAccount: Codable, Identifiable, Equatable {
    var name: String
    var username: String
    var password: String
    var id: String { name }
}

enum AccountStore {
    private static let key = "accounts"

    static func load() -> [SavedAccount] {
        guard let json = Keychain.load(key),
              let data = json.data(using: .utf8),
              let list = try? JSONDecoder().decode([SavedAccount].self, from: data) else { return [] }
        return list
    }

    static func save(_ list: [SavedAccount]) {
        guard let data = try? JSONEncoder().encode(list),
              let json = String(data: data, encoding: .utf8) else { return }
        Keychain.save(json, for: key)
    }
}