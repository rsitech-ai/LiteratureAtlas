import Foundation

enum DisplayText {
    static func clusterName(_ raw: String) -> String {
        let cleaned = raw
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = cleaned.split(whereSeparator: \.isWhitespace)
        if parts.count == 2,
           parts[0].caseInsensitiveCompare("cluster") == .orderedSame,
           Int(parts[1]) != nil {
            return "Unnamed topic"
        }
        return cleaned
    }
}
