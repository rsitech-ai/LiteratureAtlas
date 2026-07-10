import Foundation

enum DisplayText {
    static func clusterName(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
