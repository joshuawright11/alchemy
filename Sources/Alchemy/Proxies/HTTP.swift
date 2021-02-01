import AsyncHTTPClient
import Lifecycle

/// An HTTPClient injected from the main service container.
///
/// - Note: See
/// [async-http-client](https://github.com/swift-server/async-http-client)
///
/// Usage:
/// ```swift
/// HTTP
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
public var HTTP: HTTPClient {
    get { Container.main.resolve(HTTPClient.self) }
}
