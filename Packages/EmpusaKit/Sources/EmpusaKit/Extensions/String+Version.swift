import Foundation

public extension String {
    func isHigherThan(_ otherVersion: String) -> Bool {
        let versionDelimiter = "."

        var versionComponents = self.components(separatedBy: versionDelimiter)
        var otherVersionComponents = otherVersion.components(separatedBy: versionDelimiter)

        let zeroDiff = versionComponents.count - otherVersionComponents.count

        let result: ComparisonResult = {
            if zeroDiff == 0 {
                return self.compare(otherVersion, options: .numeric)
            } else {
                let zeros = Array(repeating: "0", count: abs(zeroDiff))
                if zeroDiff > 0 {
                    otherVersionComponents.append(contentsOf: zeros)
                } else {
                    versionComponents.append(contentsOf: zeros)
                }
                return versionComponents.joined(separator: versionDelimiter)
                    .compare(otherVersionComponents.joined(separator: versionDelimiter), options: .numeric)
            }
        }()

        return result == .orderedDescending
    }
}
