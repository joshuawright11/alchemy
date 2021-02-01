import AsyncHTTPClient
import Fusion
import Lifecycle
import NIO
import RediStack

/// Provides easy access to some commonly used services in Alchemy.
/// These services are Injected from the global `Container`. You
/// can add your own services in extensions if you'd like.
///
/// ```swift
/// DB
/// // equivalant to
/// Container.global.resolve(Database.self)
/// // equivalent to
/// @Inject
/// var db: Database
/// ```
public enum Services {}

extension Services {
    // MARK: Alchemy Services
    
    
//    public static var db: Database {
//        get { Container.main.resolve(Database.self) }
//        set { Container.main.register(singleton: Database.self) { _ in newValue } }
//    }
    
//    /// The router to which all incoming requests in your application
//    /// are routed.
//    public static var router: Router {
//        Container.main.resolve(Router.self)
//    }
    
    /// A scheduler for scheduling recurring tasks.
//    public static var scheduler: Scheduler {
//        Container.main.resolve(Scheduler.self)
//    }
    
    /// An `HTTPClient` for making HTTP requests.
    ///
    /// - Note: See
    /// [async-http-client](https://github.com/swift-server/async-http-client)
    ///
    /// Usage:
    /// ```swift
    /// Services.client
    ///     .get(url: "https://swift.org")
    ///     .whenComplete { result in
    ///         switch result {
    ///         case .failure(let error):
    ///             ...
    ///         case .success(let response):
    ///             ...
    ///         }
    ///     }
    /// ```
//    public static var client: HTTPClient {
//        Container.main.resolve(HTTPClient.self)
//    }
    
//    public static var redis: RedisClient {
//        get { Container.main.resolve(RedisClient.self) }
//        set { Container.main.register(singleton: RedisClient.self, factory: { _ in newValue }) }
//    }
}
