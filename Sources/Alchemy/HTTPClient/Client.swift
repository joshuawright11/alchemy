/// Something to make HTTP requests from the server.
///
/// Might not be necessary with the newly christened https://github.com/swift-server/async-http-client
/// Haven't looked @ the docs but maybe they could be prettified.
import AsyncHTTPClient

/// Global singleton accessor & convenient typealias for a default database.
public typealias Client = HTTPClientDefault
public struct HTTPClientDefault {
    public static var `default`: HTTPClient {
        get {
            guard let _default = HTTPClientDefault._default else {
                fatalError("A default `Database` has not been set up yet. You can do so via `DB.default = ...`")
            }
            
            return _default
        }
        set { HTTPClientDefault._default = newValue }
    }
    
    private static var _default: HTTPClient?
}
