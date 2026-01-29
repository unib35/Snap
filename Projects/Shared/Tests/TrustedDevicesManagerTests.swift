import Testing
@testable import Shared
import Foundation

// MARK: - TrustedDevice Tests

@Suite("TrustedDevice Tests")
struct TrustedDeviceTests {
    @Test("TrustedDevice initialization")
    func initialization() {
        let device = TrustedDevice(
            deviceID: "test-device-123",
            deviceName: "Test iPhone"
        )

        #expect(device.deviceID == "test-device-123")
        #expect(device.deviceName == "Test iPhone")
        #expect(device.id == device.deviceID)
    }

    @Test("TrustedDevice with custom pairedAt date")
    func customPairedAt() {
        let customDate = Date(timeIntervalSince1970: 1_000_000)
        let device = TrustedDevice(
            deviceID: "device-1",
            deviceName: "Device",
            pairedAt: customDate
        )

        #expect(device.pairedAt == customDate)
    }

    @Test("TrustedDevice Equatable conformance")
    func equatable() {
        let date = Date()
        let device1 = TrustedDevice(deviceID: "id", deviceName: "name", pairedAt: date)
        let device2 = TrustedDevice(deviceID: "id", deviceName: "name", pairedAt: date)
        let device3 = TrustedDevice(deviceID: "different", deviceName: "name", pairedAt: date)

        #expect(device1 == device2)
        #expect(device1 != device3)
    }

    @Test("TrustedDevice Codable round-trip")
    func codableRoundTrip() throws {
        let original = TrustedDevice(
            deviceID: "codable-test",
            deviceName: "Codable Device",
            pairedAt: Date(timeIntervalSince1970: 1_234_567_890)
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TrustedDevice.self, from: encoded)

        #expect(decoded.deviceID == original.deviceID)
        #expect(decoded.deviceName == original.deviceName)
        #expect(decoded.pairedAt == original.pairedAt)
    }
}

// MARK: - TrustedDevicesManager Tests

@Suite("TrustedDevicesManager Tests")
struct TrustedDevicesManagerTests {
    /// Creates a manager with isolated UserDefaults for testing
    private func createTestManager() -> TrustedDevicesManager {
        let suiteName = "com.snap.test.\(UUID().uuidString)"
        // swiftlint:disable:next force_unwrapping
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let persistence = UserDefaultsPersistence(userDefaults: testDefaults)
        return TrustedDevicesManager(persistence: persistence)
    }

    /// Waits for async barrier operations to complete
    private func waitForBarrier() {
        // Give time for async barrier operations
        Thread.sleep(forTimeInterval: 0.1)
    }

    @Test("Initially empty")
    func initiallyEmpty() {
        let manager = createTestManager()

        #expect(manager.trustedDevices.isEmpty)
    }

    @Test("Add trusted device")
    func addTrustedDevice() {
        let manager = createTestManager()
        let device = TrustedDevice(deviceID: "device-1", deviceName: "iPhone 1")

        manager.addTrustedDevice(device)
        waitForBarrier()

        #expect(manager.trustedDevices.count == 1)
        #expect(manager.trustedDevices.first?.deviceID == "device-1")
        #expect(manager.trustedDevices.first?.deviceName == "iPhone 1")
    }

    @Test("Add trusted device with ID and name")
    func addTrustedDeviceWithIDAndName() {
        let manager = createTestManager()

        manager.addTrustedDevice(deviceID: "device-2", deviceName: "iPad Pro")
        waitForBarrier()

        #expect(manager.trustedDevices.count == 1)
        #expect(manager.trustedDevices.first?.deviceID == "device-2")
        #expect(manager.trustedDevices.first?.deviceName == "iPad Pro")
    }

    @Test("Add multiple devices")
    func addMultipleDevices() {
        let manager = createTestManager()

        manager.addTrustedDevice(deviceID: "device-1", deviceName: "Device 1")
        manager.addTrustedDevice(deviceID: "device-2", deviceName: "Device 2")
        manager.addTrustedDevice(deviceID: "device-3", deviceName: "Device 3")
        waitForBarrier()

        #expect(manager.trustedDevices.count == 3)
    }

    @Test("Update existing device")
    func updateExistingDevice() {
        let manager = createTestManager()

        manager.addTrustedDevice(deviceID: "device-1", deviceName: "Old Name")
        waitForBarrier()
        manager.addTrustedDevice(deviceID: "device-1", deviceName: "New Name")
        waitForBarrier()

        #expect(manager.trustedDevices.count == 1)
        #expect(manager.trustedDevices.first?.deviceName == "New Name")
    }

    @Test("Remove trusted device")
    func removeTrustedDevice() {
        let manager = createTestManager()

        manager.addTrustedDevice(deviceID: "device-1", deviceName: "Device 1")
        manager.addTrustedDevice(deviceID: "device-2", deviceName: "Device 2")
        waitForBarrier()

        manager.removeTrustedDevice(deviceID: "device-1")
        waitForBarrier()

        #expect(manager.trustedDevices.count == 1)
        #expect(manager.trustedDevices.first?.deviceID == "device-2")
    }

    @Test("Remove non-existent device does nothing")
    func removeNonExistentDevice() {
        let manager = createTestManager()

        manager.addTrustedDevice(deviceID: "device-1", deviceName: "Device 1")
        waitForBarrier()

        manager.removeTrustedDevice(deviceID: "non-existent")
        waitForBarrier()

        #expect(manager.trustedDevices.count == 1)
    }

    @Test("Remove all trusted devices")
    func removeAllTrustedDevices() {
        let manager = createTestManager()

        manager.addTrustedDevice(deviceID: "device-1", deviceName: "Device 1")
        manager.addTrustedDevice(deviceID: "device-2", deviceName: "Device 2")
        manager.addTrustedDevice(deviceID: "device-3", deviceName: "Device 3")
        waitForBarrier()

        manager.removeAllTrustedDevices()
        waitForBarrier()

        #expect(manager.trustedDevices.isEmpty)
    }

    @Test("isTrusted returns true for trusted device")
    func isTrustedReturnsTrue() {
        let manager = createTestManager()

        manager.addTrustedDevice(deviceID: "trusted-device", deviceName: "Trusted")
        waitForBarrier()

        #expect(manager.isTrusted(deviceID: "trusted-device") == true)
    }

    @Test("isTrusted returns false for untrusted device")
    func isTrustedReturnsFalse() {
        let manager = createTestManager()

        manager.addTrustedDevice(deviceID: "trusted-device", deviceName: "Trusted")
        waitForBarrier()

        #expect(manager.isTrusted(deviceID: "untrusted-device") == false)
    }

    @Test("isTrusted returns false when empty")
    func isTrustedReturnsFalseWhenEmpty() {
        let manager = createTestManager()

        #expect(manager.isTrusted(deviceID: "any-device") == false)
    }

    @Test("deviceName returns name for trusted device")
    func deviceNameReturnsName() {
        let manager = createTestManager()

        manager.addTrustedDevice(deviceID: "device-1", deviceName: "My iPhone")
        waitForBarrier()

        #expect(manager.deviceName(for: "device-1") == "My iPhone")
    }

    @Test("deviceName returns nil for untrusted device")
    func deviceNameReturnsNil() {
        let manager = createTestManager()

        manager.addTrustedDevice(deviceID: "device-1", deviceName: "Device 1")
        waitForBarrier()

        #expect(manager.deviceName(for: "unknown-device") == nil)
    }

    @Test("Persistence across manager instances")
    func persistenceAcrossInstances() {
        let suiteName = "com.snap.test.persistence.\(UUID().uuidString)"
        // swiftlint:disable:next force_unwrapping
        let testDefaults = UserDefaults(suiteName: suiteName)!
        let persistence = UserDefaultsPersistence(userDefaults: testDefaults)

        // First manager instance
        let manager1 = TrustedDevicesManager(persistence: persistence)
        manager1.addTrustedDevice(deviceID: "persistent-device", deviceName: "Persistent")
        waitForBarrier()

        // Second manager instance with same persistence
        let manager2 = TrustedDevicesManager(persistence: persistence)

        #expect(manager2.trustedDevices.count == 1)
        #expect(manager2.isTrusted(deviceID: "persistent-device") == true)
        #expect(manager2.deviceName(for: "persistent-device") == "Persistent")

        // Cleanup
        testDefaults.removePersistentDomain(forName: suiteName)
    }

    @Test("Thread safety - concurrent adds")
    func threadSafetyConcurrentAdds() async {
        let manager = createTestManager()
        let iterations = 100

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    manager.addTrustedDevice(deviceID: "device-\(i)", deviceName: "Device \(i)")
                }
            }
        }

        // Wait for all barrier operations to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        #expect(manager.trustedDevices.count == iterations)
    }

    @Test("Thread safety - concurrent reads")
    func threadSafetyConcurrentReads() async {
        let manager = createTestManager()

        // Add some devices first
        for i in 0..<10 {
            manager.addTrustedDevice(deviceID: "device-\(i)", deviceName: "Device \(i)")
        }
        waitForBarrier()

        // Concurrent reads should not crash
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<100 {
                group.addTask {
                    manager.isTrusted(deviceID: "device-\(i % 10)")
                }
            }
        }

        #expect(manager.trustedDevices.count == 10)
    }

    @Test("Thread safety - concurrent reads and writes")
    func threadSafetyConcurrentReadsAndWrites() async {
        let manager = createTestManager()

        // First add devices
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    manager.addTrustedDevice(deviceID: "device-\(i)", deviceName: "Device \(i)")
                }
            }
        }

        // Wait for barrier operations
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Then perform concurrent reads (should not crash)
        await withTaskGroup(of: Bool.self) { group in
            for i in 0..<100 {
                group.addTask {
                    _ = manager.trustedDevices
                    return manager.isTrusted(deviceID: "device-\(i % 50)")
                }
            }
        }

        // Should have added all devices
        #expect(manager.trustedDevices.count == 50)
    }
}

// MARK: - PINCodeGenerator Tests

@Suite("PINCodeGenerator Tests")
struct PINCodeGeneratorTests {
    @Test("Generate returns 4-digit string")
    func generateReturns4DigitString() {
        let pin = PINCodeGenerator.generate()

        #expect(pin.count == 4)
        #expect(pin.allSatisfy { $0.isNumber })
    }

    @Test("Generate returns different values")
    func generateReturnsDifferentValues() {
        var pins = Set<String>()

        // Generate multiple PINs and check for variety
        for _ in 0..<100 {
            pins.insert(PINCodeGenerator.generate())
        }

        // Should have at least some variety (extremely unlikely to get same PIN 100 times)
        #expect(pins.count > 1)
    }

    @Test("Generate covers full range")
    func generateCoversFullRange() {
        var seenLeadingZero = false
        var seenNonZeroStart = false

        for _ in 0..<1000 {
            let pin = PINCodeGenerator.generate()
            if pin.hasPrefix("0") {
                seenLeadingZero = true
            } else {
                seenNonZeroStart = true
            }

            if seenLeadingZero && seenNonZeroStart {
                break
            }
        }

        // Should see both leading zeros and non-zero starts
        #expect(seenLeadingZero == true)
        #expect(seenNonZeroStart == true)
    }

    @Test("isValid returns true for valid PINs")
    func isValidReturnsTrue() {
        #expect(PINCodeGenerator.isValid("0000") == true)
        #expect(PINCodeGenerator.isValid("1234") == true)
        #expect(PINCodeGenerator.isValid("9999") == true)
        #expect(PINCodeGenerator.isValid("0001") == true)
    }

    @Test("isValid returns false for invalid PINs")
    func isValidReturnsFalse() {
        // Too short
        #expect(PINCodeGenerator.isValid("123") == false)
        #expect(PINCodeGenerator.isValid("") == false)

        // Too long
        #expect(PINCodeGenerator.isValid("12345") == false)

        // Contains non-digits
        #expect(PINCodeGenerator.isValid("12ab") == false)
        #expect(PINCodeGenerator.isValid("abcd") == false)
        #expect(PINCodeGenerator.isValid("12 4") == false)
        #expect(PINCodeGenerator.isValid("12-4") == false)
    }

    @Test("Generated PIN is always valid")
    func generatedPINIsAlwaysValid() {
        for _ in 0..<100 {
            let pin = PINCodeGenerator.generate()
            #expect(PINCodeGenerator.isValid(pin) == true)
        }
    }
}
