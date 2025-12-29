import Foundation

/// Snap Shared Module
/// iOS와 macOS 간 공유되는 코드 (Protobuf, 네트워크 프로토콜 등)
public enum Shared {
    public static let version = "1.0.0"
}

// MARK: - Re-exports

// Network
@_exported import struct Foundation.Data

// Protocol Messages are exported via their respective files
