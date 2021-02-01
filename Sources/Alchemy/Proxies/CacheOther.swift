struct MemcacheCache: CacheService {
    func get(key: String) -> EventLoopFuture<String?> { fatalError() }
    func pull(key: String) -> EventLoopFuture<Void> { fatalError() }
    func put(key: String, value: String, for time: TimeAmount) -> EventLoopFuture<Void> { fatalError() }
    func has(key: String) -> EventLoopFuture<Bool> { fatalError() }
    func increment(key: String) -> EventLoopFuture<Int> { fatalError() }
    func decrement(key: String) -> EventLoopFuture<Int> { fatalError() }
    func forget(key: String) -> EventLoopFuture<Bool> { fatalError() }
    func wipe() -> EventLoopFuture<Void> { fatalError() }
}

struct RedisCache: CacheService {
    func get(key: String) -> EventLoopFuture<String?> { fatalError() }
    func pull(key: String) -> EventLoopFuture<Void> { fatalError() }
    func put(key: String, value: String, for time: TimeAmount) -> EventLoopFuture<Void> { fatalError() }
    func has(key: String) -> EventLoopFuture<Bool> { fatalError() }
    func increment(key: String) -> EventLoopFuture<Int> { fatalError() }
    func decrement(key: String) -> EventLoopFuture<Int> { fatalError() }
    func forget(key: String) -> EventLoopFuture<Bool> { fatalError() }
    func wipe() -> EventLoopFuture<Void> { fatalError() }
}

struct DiskCache: CacheService {
    func get(key: String) -> EventLoopFuture<String?> { fatalError() }
    func pull(key: String) -> EventLoopFuture<Void> { fatalError() }
    func put(key: String, value: String, for time: TimeAmount) -> EventLoopFuture<Void> { fatalError() }
    func has(key: String) -> EventLoopFuture<Bool> { fatalError() }
    func increment(key: String) -> EventLoopFuture<Int> { fatalError() }
    func decrement(key: String) -> EventLoopFuture<Int> { fatalError() }
    func forget(key: String) -> EventLoopFuture<Bool> { fatalError() }
    func wipe() -> EventLoopFuture<Void> { fatalError() }
}

struct SQLCache: CacheService {
    func get(key: String) -> EventLoopFuture<String?> { fatalError() }
    func pull(key: String) -> EventLoopFuture<Void> { fatalError() }
    func put(key: String, value: String, for time: TimeAmount) -> EventLoopFuture<Void> { fatalError() }
    func has(key: String) -> EventLoopFuture<Bool> { fatalError() }
    func increment(key: String) -> EventLoopFuture<Int> { fatalError() }
    func decrement(key: String) -> EventLoopFuture<Int> { fatalError() }
    func forget(key: String) -> EventLoopFuture<Bool> { fatalError() }
    func wipe() -> EventLoopFuture<Void> { fatalError() }
}

/// Step 1, define custom Cache

struct CustomCache: CacheService {
    func get(key: String) -> EventLoopFuture<String?> { fatalError() }
    func pull(key: String) -> EventLoopFuture<Void> { fatalError() }
    func put(key: String, value: String, for time: TimeAmount) -> EventLoopFuture<Void> { fatalError() }
    func has(key: String) -> EventLoopFuture<Bool> { fatalError() }
    func increment(key: String) -> EventLoopFuture<Int> { fatalError() }
    func decrement(key: String) -> EventLoopFuture<Int> { fatalError() }
    func forget(key: String) -> EventLoopFuture<Bool> { fatalError() }
    func wipe() -> EventLoopFuture<Void> { fatalError() }
}

/// Step 2, add to CacheDriver

extension Proxy.Config where Service == CacheService {
    static func custom() -> Self {
        Self(CustomCache())
    }
}

/// Testing
