import Foundation

// MARK: - PersistenceManager Protocol

/// 데이터 영속성 관리 프로토콜
public protocol PersistenceManager: Sendable {
    /// Codable 객체 저장
    func save<T: Codable>(_ value: T, forKey key: String)

    /// Codable 객체 로드
    func load<T: Codable>(forKey key: String) -> T?

    /// 키 삭제
    func remove(forKey key: String)

    /// 키 존재 여부 확인
    func exists(forKey key: String) -> Bool
}

// MARK: - UserDefaultsPersistence

/// UserDefaults 기반 영속성 구현
public final class UserDefaultsPersistence: PersistenceManager, @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = UserDefaultsPersistence()

    // MARK: - Private Properties

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(label: "com.snap.persistence", attributes: .concurrent)

    // MARK: - Initialization

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // MARK: - PersistenceManager

    public func save<T: Codable>(_ value: T, forKey key: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            do {
                let data = try self.encoder.encode(value)
                self.userDefaults.set(data, forKey: key)
            } catch {
                // Silently fail - encoding errors are programming errors
                assertionFailure("[PersistenceManager] Failed to save \(key): \(error)")
            }
        }
    }

    public func load<T: Codable>(forKey key: String) -> T? {
        queue.sync {
            guard let data = userDefaults.data(forKey: key) else {
                return nil
            }
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                // Silently fail - may occur when data format changes
                assertionFailure("[PersistenceManager] Failed to load \(key): \(error)")
                return nil
            }
        }
    }

    public func remove(forKey key: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.userDefaults.removeObject(forKey: key)
        }
    }

    public func exists(forKey key: String) -> Bool {
        queue.sync {
            userDefaults.object(forKey: key) != nil
        }
    }
}

// MARK: - Convenience Extensions

public extension PersistenceManager {
    /// 값이 없으면 기본값 반환
    func load<T: Codable>(forKey key: String, default defaultValue: T) -> T {
        load(forKey: key) ?? defaultValue
    }

    /// 값이 없으면 기본값 저장 후 반환
    func loadOrCreate<T: Codable>(forKey key: String, default defaultValue: T) -> T {
        if let value: T = load(forKey: key) {
            return value
        }
        save(defaultValue, forKey: key)
        return defaultValue
    }
}

// MARK: - Mock Persistence (for testing)

#if DEBUG
/// 테스트용 메모리 기반 영속성 구현
public final class MockPersistence: PersistenceManager, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "com.snap.mockPersistence", attributes: .concurrent)

    public init() {}

    public func save<T: Codable>(_ value: T, forKey key: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            if let data = try? self.encoder.encode(value) {
                self.storage[key] = data
            }
        }
    }

    public func load<T: Codable>(forKey key: String) -> T? {
        queue.sync {
            guard let data = storage[key] else { return nil }
            return try? decoder.decode(T.self, from: data)
        }
    }

    public func remove(forKey key: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.storage.removeValue(forKey: key)
        }
    }

    public func exists(forKey key: String) -> Bool {
        queue.sync {
            storage[key] != nil
        }
    }

    /// 모든 데이터 삭제 (테스트용)
    public func clear() {
        queue.async(flags: .barrier) { [weak self] in
            self?.storage.removeAll()
        }
    }
}
#endif
