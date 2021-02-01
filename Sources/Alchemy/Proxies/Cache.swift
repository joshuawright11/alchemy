var Cache: CacheService & CacheProxy { CacheProxy() }

typealias CacheProxy = Proxy<CacheService>

protocol CacheService {
    func get(key: String) -> EventLoopFuture<String?>
    func pull(key: String) -> EventLoopFuture<Void>
    func put(key: String, value: String, for time: TimeAmount) -> EventLoopFuture<Void>
    func has(key: String) -> EventLoopFuture<Bool>
    func increment(key: String) -> EventLoopFuture<Int>
    func decrement(key: String) -> EventLoopFuture<Int>
    func forget(key: String) -> EventLoopFuture<Bool>
    func wipe() -> EventLoopFuture<Void>
}

extension Proxy: CacheService where Service == CacheService {
    func get(key: String) -> EventLoopFuture<String?> { self.service.get(key: key) }
    func pull(key: String) -> EventLoopFuture<Void> { self.service.pull(key: key) }
    func put(key: String, value: String, for time: TimeAmount) -> EventLoopFuture<Void> { self.service.put(key: key, value: value, for: time) }
    func has(key: String) -> EventLoopFuture<Bool> { self.service.has(key: key) }
    func increment(key: String) -> EventLoopFuture<Int> { self.service.increment(key: key) }
    func decrement(key: String) -> EventLoopFuture<Int> { self.service.decrement(key: key) }
    func forget(key: String) -> EventLoopFuture<Bool> { self.service.forget(key: key) }
    func wipe() -> EventLoopFuture<Void> { self.service.wipe() }
}

struct Sample {
    func prod() {
        Cache.config(.disk())
        let val = Cache.get(key: "ddd")
//        Cache.config(driver: .disk())
//        Cache.config(driver: .memcache(), name: "memcache")
//        Cache.config(driver: .disk(), name: "disk")
    }
    
    func testing() {
        
//        Cache.mock()
    }
}

extension Proxy.Config where Service == CacheService {
    static func memcache() -> Self {
        Self(MemcacheCache())
    }
    
    static func redis() -> Self {
        Self(RedisCache())
    }
    
    static func disk() -> Self {
        Self(DiskCache())
    }
}
