import Foundation

/// Lightweight wrapper around injecting & registering services to the
/// service container.
public final class Proxy<Service> {
    private let id: String?
    
    init(id: String? = nil) {
        self.id = id
    }
    
    public func callAsFunction(_ id: String) -> Self {
        Self(id: id)
    }
    
    public func config(_ config: Config) {
        if let id = self.id {
            Container.main.register(singleton: Service.self, identifier: id, factory: { _ in config.service })
        } else {
            Container.main.register(singleton: Service.self, factory: { _ in config.service })
        }
    }
    
    func resolve() -> Service {
        Container.main.resolve(Service.self, identifier: id)
    }
}

extension Proxy {
    public struct Config {
        let service: Service
        
        public init(_ service: Service) {
            self.service = service
        }
    }
}
