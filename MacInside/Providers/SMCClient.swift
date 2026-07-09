import Foundation
import IOKit

/// Client SMC bas niveau (System Management Controller) via IOKit.
/// Réimplémentation du protocole binaire documenté par les projets open
/// source `smcFanControl`, `macs-fan-control` et `Stats` (github.com/exelban/stats) :
/// ouverture du service `AppleSMC`, puis échange de la structure `SMCKeyData_t`
/// (80 octets, layout C) via `IOConnectCallStructMethod` (sélecteur
/// `kSMCHandleYPCEvent` = 2). La structure est manipulée sous forme de buffer
/// d'octets brut avec des offsets explicites plutôt qu'un struct Swift miroir,
/// pour ne dépendre d'aucune hypothèse sur l'alignement/padding choisi par le
/// compilateur Swift — le layout C exact (avec son padding) est documenté et
/// stable, un buffer d'octets le reproduit fidèlement sans ambiguïté.
final class SMCClient {
    private var connection: io_connect_t = 0
    private(set) var isOpen = false

    private static let structSize = 80

    /// Offsets (en octets) des champs utilisés dans `SMCKeyData_t`.
    private enum Offset {
        static let key = 0
        static let keyInfoDataSize = 28
        static let keyInfoDataType = 32
        static let result = 40
        static let data8 = 42
        static let bytes = 48
    }

    private enum Command: UInt8 {
        case readBytes = 5
        case readKeyInfo = 9
    }

    private static let selectorHandleYPCEvent: UInt32 = 2
    private static let successResult: UInt8 = 0

    init() {
        isOpen = openService()
    }

    deinit {
        guard isOpen else { return }
        _ = IOServiceClose(connection)
    }

    private func openService() -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }

        return IOServiceOpen(service, mach_task_self_, 0, &connection) == kIOReturnSuccess
    }

    /// Lit une clé SMC à 4 caractères (ex. "TC0P", "FNum", "F0Ac"). Retourne
    /// les octets bruts de la charge utile et le type de donnée SMC associé
    /// ("flt ", "sp78", "fpe2", "ui8 "...), ou `nil` si la clé n'existe pas
    /// sur ce Mac ou si l'appel échoue.
    func read(_ key: String) -> (bytes: [UInt8], dataType: String)? {
        guard isOpen, let keyCode = Self.fourCharCode(key) else { return nil }

        var infoInput = Self.makeBuffer()
        Self.writeUInt32(keyCode, at: Offset.key, into: &infoInput)
        infoInput[Offset.data8] = Command.readKeyInfo.rawValue
        guard let infoOutput = call(infoInput) else { return nil }

        let dataSize = Self.readUInt32(at: Offset.keyInfoDataSize, from: infoOutput)
        guard dataSize > 0, dataSize <= 32 else { return nil }
        let dataType = Self.fourCharString(Self.readUInt32(at: Offset.keyInfoDataType, from: infoOutput))

        var readInput = Self.makeBuffer()
        Self.writeUInt32(keyCode, at: Offset.key, into: &readInput)
        Self.writeUInt32(dataSize, at: Offset.keyInfoDataSize, into: &readInput)
        readInput[Offset.data8] = Command.readBytes.rawValue
        guard let readOutput = call(readInput) else { return nil }

        let bytes = Array(readOutput[Offset.bytes..<(Offset.bytes + Int(dataSize))])
        return (bytes, dataType)
    }

    private func call(_ input: [UInt8]) -> [UInt8]? {
        guard isOpen else { return nil }
        var input = input
        var output = Self.makeBuffer()
        var outputSize = Self.structSize

        let result = input.withUnsafeMutableBytes { inputPtr -> kern_return_t in
            output.withUnsafeMutableBytes { outputPtr -> kern_return_t in
                IOConnectCallStructMethod(connection, Self.selectorHandleYPCEvent,
                                           inputPtr.baseAddress, Self.structSize,
                                           outputPtr.baseAddress, &outputSize)
            }
        }

        guard result == kIOReturnSuccess, output[Offset.result] == Self.successResult else { return nil }
        return output
    }

    private static func makeBuffer() -> [UInt8] {
        [UInt8](repeating: 0, count: structSize)
    }

    private static func writeUInt32(_ value: UInt32, at offset: Int, into buffer: inout [UInt8]) {
        buffer[offset] = UInt8(value & 0xFF)
        buffer[offset + 1] = UInt8((value >> 8) & 0xFF)
        buffer[offset + 2] = UInt8((value >> 16) & 0xFF)
        buffer[offset + 3] = UInt8((value >> 24) & 0xFF)
    }

    private static func readUInt32(at offset: Int, from buffer: [UInt8]) -> UInt32 {
        UInt32(buffer[offset])
            | (UInt32(buffer[offset + 1]) << 8)
            | (UInt32(buffer[offset + 2]) << 16)
            | (UInt32(buffer[offset + 3]) << 24)
    }

    private static func fourCharCode(_ string: String) -> UInt32? {
        let bytes = Array(string.utf8)
        guard bytes.count == 4 else { return nil }
        return bytes.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }

    private static func fourCharString(_ code: UInt32) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF)
        ]
        return String(bytes: bytes, encoding: .ascii) ?? ""
    }
}

extension SMCClient {
    /// Décode une valeur numérique brute selon le type de donnée SMC
    /// annoncé par la clé (formats fixes documentés par convention SMC,
    /// pas de cast direct octets → Int).
    static func decodeValue(bytes: [UInt8], dataType: String) -> Double? {
        switch dataType {
        case "flt ":
            guard bytes.count >= 4 else { return nil }
            let raw = UInt32(bytes[0]) | (UInt32(bytes[1]) << 8) | (UInt32(bytes[2]) << 16) | (UInt32(bytes[3]) << 24)
            return Double(Float(bitPattern: raw))
        case "sp78":
            guard bytes.count >= 2 else { return nil }
            let raw = Int16(bitPattern: (UInt16(bytes[0]) << 8) | UInt16(bytes[1]))
            return Double(raw) / 256.0
        case "fpe2":
            guard bytes.count >= 2 else { return nil }
            let raw = (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
            return Double(raw) / 4.0
        case "ui8 ":
            guard bytes.count >= 1 else { return nil }
            return Double(bytes[0])
        case "ui16":
            guard bytes.count >= 2 else { return nil }
            return Double((UInt16(bytes[0]) << 8) | UInt16(bytes[1]))
        case "ui32":
            guard bytes.count >= 4 else { return nil }
            let raw = (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
            return Double(raw)
        default:
            return nil
        }
    }
}
