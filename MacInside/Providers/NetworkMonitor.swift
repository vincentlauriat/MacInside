import Foundation
import SystemConfiguration

/// Débit réseau (deltas d'octets par interface via `getifaddrs`) + IP locale,
/// masque, adresse MAC. L'IP publique/pays est résolue à part par
/// `PublicAddressLookup` (appel réseau asynchrone, best-effort). La passerelle
/// et le type d'interface (Wi-Fi/Ethernet) changent rarement : mis en cache et
/// recalculés au plus toutes les 30s, pas à chaque tick.
final class NetworkMonitor {
    private var previousSample: (bytesIn: UInt64, bytesOut: UInt64, date: Date)?
    private var downloadHistory: [Double] = []
    private var uploadHistory: [Double] = []
    private let historyLimit = 60
    private var totalDownloadBytes: UInt64 = 0
    private var totalUploadBytes: UInt64 = 0

    private var cachedInterfaceName: String?
    private var cachedInterfaceType = ""
    private var cachedGateway = ""
    private var lastStaticInfoFetch: Date?
    private let staticInfoRefreshInterval: TimeInterval = 30

    func snapshot() -> NetworkStats {
        var stats = NetworkStats()

        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return stats }
        defer { freeifaddrs(ifaddrPtr) }

        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0
        var localAddress = ""
        var subnetMask = ""
        var macAddress = ""
        var primaryInterface = ""

        var pointer: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }
            let addr = current.pointee.ifa_addr.pointee
            let name = String(cString: current.pointee.ifa_name)
            guard name.hasPrefix("en") else { continue }

            if addr.sa_family == UInt8(AF_LINK), let data = current.pointee.ifa_data {
                let networkData = data.assumingMemoryBound(to: if_data.self).pointee
                bytesIn += UInt64(networkData.ifi_ibytes)
                bytesOut += UInt64(networkData.ifi_obytes)
                if primaryInterface.isEmpty {
                    primaryInterface = name
                    macAddress = Self.macAddress(from: current.pointee.ifa_addr)
                }
            } else if addr.sa_family == UInt8(AF_INET), localAddress.isEmpty {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(current.pointee.ifa_addr, socklen_t(current.pointee.ifa_addr.pointee.sa_len),
                            &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST)
                localAddress = String(cString: host)
                if let netmask = current.pointee.ifa_netmask {
                    subnetMask = Self.ipv4String(from: netmask)
                }
            }
        }

        stats.interfaceName = primaryInterface
        stats.localAddress = localAddress
        stats.subnetMask = subnetMask
        stats.macAddress = macAddress

        refreshStaticInfoIfNeeded(interfaceName: primaryInterface)
        stats.interfaceType = cachedInterfaceType
        stats.gatewayAddress = cachedGateway

        let now = Date()
        if let previous = previousSample {
            let elapsed = now.timeIntervalSince(previous.date)
            if elapsed > 0 {
                let deltaIn = bytesIn &- previous.bytesIn
                let deltaOut = bytesOut &- previous.bytesOut
                stats.downloadBytesPerSec = Double(deltaIn) / elapsed
                stats.uploadBytesPerSec = Double(deltaOut) / elapsed
                totalDownloadBytes &+= deltaIn
                totalUploadBytes &+= deltaOut
            }
        }
        previousSample = (bytesIn, bytesOut, now)
        stats.totalDownloadBytes = totalDownloadBytes
        stats.totalUploadBytes = totalUploadBytes

        downloadHistory.append(stats.downloadBytesPerSec)
        uploadHistory.append(stats.uploadBytesPerSec)
        if downloadHistory.count > historyLimit { downloadHistory.removeFirst(downloadHistory.count - historyLimit) }
        if uploadHistory.count > historyLimit { uploadHistory.removeFirst(uploadHistory.count - historyLimit) }
        stats.downloadHistory = downloadHistory
        stats.uploadHistory = uploadHistory

        return stats
    }

    private func refreshStaticInfoIfNeeded(interfaceName: String) {
        let now = Date()
        let interfaceChanged = interfaceName != cachedInterfaceName
        let staleEnough = lastStaticInfoFetch.map { now.timeIntervalSince($0) > staticInfoRefreshInterval } ?? true
        guard interfaceChanged || staleEnough else { return }

        cachedInterfaceName = interfaceName
        cachedInterfaceType = Self.interfaceType(bsdName: interfaceName)
        cachedGateway = Self.defaultGateway()
        lastStaticInfoFetch = now
    }

    private static func macAddress(from sockaddr: UnsafeMutablePointer<sockaddr>) -> String {
        let sdl = UnsafeRawPointer(sockaddr).assumingMemoryBound(to: sockaddr_dl.self).pointee
        guard sdl.sdl_alen == 6, let offset = MemoryLayout<sockaddr_dl>.offset(of: \.sdl_data) else { return "" }
        let base = UnsafeRawPointer(sockaddr) + offset + Int(sdl.sdl_nlen)
        let bytes = (0..<6).map { base.load(fromByteOffset: $0, as: UInt8.self) }
        return bytes.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    private static func ipv4String(from sockaddr: UnsafeMutablePointer<sockaddr>) -> String {
        var addr = UnsafeRawPointer(sockaddr).assumingMemoryBound(to: sockaddr_in.self).pointee.sin_addr
        var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
        inet_ntop(AF_INET, &addr, &buffer, socklen_t(buffer.count))
        return String(cString: buffer)
    }

    private static func interfaceType(bsdName: String) -> String {
        guard !bsdName.isEmpty, let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else { return "" }
        guard let match = interfaces.first(where: { SCNetworkInterfaceGetBSDName($0) as String? == bsdName }) else { return "" }
        let type = SCNetworkInterfaceGetInterfaceType(match) as String?
        if type == (kSCNetworkInterfaceTypeIEEE80211 as String) { return "Wi-Fi" }
        if type == (kSCNetworkInterfaceTypeEthernet as String) { return "Ethernet" }
        return ""
    }

    private static func defaultGateway() -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/route")
        process.arguments = ["-n", "get", "default"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let output = String(data: data, encoding: .utf8) ?? ""
            for line in output.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("gateway:") {
                    return trimmed.replacingOccurrences(of: "gateway:", with: "")
                        .trimmingCharacters(in: .whitespaces)
                }
            }
            return ""
        } catch {
            return ""
        }
    }
}

/// Résolution best-effort de l'IP publique + pays via un service HTTPS tiers.
/// Échoue silencieusement hors-ligne — ne doit jamais bloquer l'UI.
actor PublicAddressLookup {
    struct Result { var ip: String; var countryCode: String }

    private var cached: Result?
    private var lastFetch: Date?
    private let refreshInterval: TimeInterval = 300

    func current() async -> Result? {
        if let cached, let lastFetch, Date().timeIntervalSince(lastFetch) < refreshInterval {
            return cached
        }
        guard let url = URL(string: "https://ipinfo.io/json") else { return cached }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return cached }
            let result = Result(ip: json["ip"] as? String ?? "", countryCode: json["country"] as? String ?? "")
            cached = result
            lastFetch = Date()
            return result
        } catch {
            return cached
        }
    }
}
