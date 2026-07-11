import Foundation

enum Formatters {
    static func bytes(_ value: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .binary)
    }

    static func bytesPerSecond(_ value: Double) -> String {
        bytes(UInt64(max(value, 0))) + "/s"
    }

    static func percent(_ value: Double, decimals: Int = 0) -> String {
        String(format: "%.\(decimals)f%%", value)
    }

    static func uptime(_ interval: TimeInterval) -> String {
        let totalSeconds = Int(interval)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    static func celsius(_ value: Double) -> String {
        String(format: "%.1f °C", value)
    }

    static func minutes(_ value: Int) -> String {
        let hours = value / 60
        let mins = value % 60
        return hours > 0
            ? String(localized: "\(hours) h \(mins) min")
            : String(localized: "\(mins) min")
    }
}
