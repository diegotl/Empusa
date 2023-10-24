import Foundation

enum UserDefaultsKey: String {
    case preferPreReleaseVersions
}

protocol UserDefaultsServiceProtocol {
    func boolForKey(_ key: UserDefaultsKey) -> Bool
}

final class UserDefaultsService: UserDefaultsServiceProtocol {
    // MARK: - Dependencies
    private let userDefaults: UserDefaults = .standard

    // MARK: - Public functions
    func boolForKey(_ key: UserDefaultsKey) -> Bool {
        userDefaults.bool(
            forKey: UserDefaultsKey.preferPreReleaseVersions.rawValue
        )
    }
}
