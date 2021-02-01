import Foundation

/// An injected Alchemy service.
final class Proxy<Service> {
    struct Config {
        let service: Service
        
        init(_ service: Service) {
            self.service = service
        }
        
        func create() -> Service {
            self.service
        }
    }
    
    var service: Service {
        Container.global.resolve(Service.self, identifier: id)
    }
    
    private let id: String?
    
    init(id: String? = nil) {
        self.id = id
    }
    
    func callAsFunction(_ id: String) -> Self {
        Self(id: id)
    }
    
    func config(_ config: Config) {
        if let id = self.id {
            Container.global.register(singleton: Service.self, identifier: id, factory: { _ in config.service })
        } else {
            Container.global.register(singleton: Service.self, factory: { _ in config.service })
        }
    }
}
