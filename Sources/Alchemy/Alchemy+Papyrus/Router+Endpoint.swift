import Foundation
import Papyrus
import NIO

public extension Application {
    /// Registers a `Papyrus.Endpoint` to a `Router`. When an incoming request matches the path of
    /// the `Endpoint`, the `Endpoint.Request` will automatically be decoded from the incoming
    /// `HTTPRequest` for use in the provided handler.
    ///
    /// - Parameters:
    ///   - endpoint: the endpoint to register on this router.
    ///   - closure: the handler for handling incoming requests that match this endpoint's path.
    ///              This handler expects a future containing an instance of the endpoint's response
    ///              type.
    /// - Returns: `self`, for chaining more requests.
    @discardableResult
    func on<Req, Res>(
        _ endpoint: Endpoint<Req, Res>,
        use closure: @escaping (Request, Req) throws -> EventLoopFuture<Res>
    ) -> Self where Res: Codable {
        self.on(endpoint.method.nio, at: endpoint.path) {
            try closure($0, try Req(from: $0))
        }
    }
    
    /// Registers a `Papyrus.Endpoint` that has an `Empty` request type, to a `Router`.
    ///
    /// - Parameters:
    ///   - endpoint: the endpoint to register on this router.
    ///   - closure: the handler for handling incoming requests that match this endpoint's path.
    ///              This handler expects a future containing an instance of the endpoint's response
    ///              type.
    /// - Returns: `self`, for chaining more requests.
    @discardableResult
    func on<Res>(
        _ endpoint: Endpoint<Empty, Res>,
        handler: @escaping (Request) throws -> EventLoopFuture<Res>
    ) -> Self {
        self.on(endpoint.method.nio, at: endpoint.path, handler: handler)
    }
    
    /// Registers a `Papyrus.Endpoint` that has an `Empty` response type, to a `Router`. When an
    /// incoming request matches the path of the `Endpoint`, the `Endpoint.Request` will
    /// automatically be decoded from the incoming `Request` for use in the provided handler.
    ///
    /// - Parameters:
    ///   - endpoint: the endpoint to register on this router.
    ///   - closure: the handler for handling incoming requests that match this endpoint's path.
    /// - Returns: `self`, for chaining more requests.
    @discardableResult
    func on<Req>(
        _ endpoint: Endpoint<Req, Empty>,
        handler: @escaping (Request, Req) throws -> EventLoopFuture<Void>
    ) -> Self {
        self.on(endpoint.method.nio, at: endpoint.path) {
            try handler($0, try Req(from: $0))
                .map { Empty.value }
        }
    }
}

// Provide a custom response for when `PapyrusValidationError`s are thrown.
extension PapyrusValidationError: ResponseConvertible {
    // MARK: ResponseConvertible
    
    public func convert() throws -> EventLoopFuture<Response> {
        let body = try HTTPBody(json: ["validation_error": self.message])
        return .new(Response(status: .badRequest, body: body))
    }
}

extension Request: DecodableRequest {
    // MARK: DecodableRequest
    
    public func header(for key: String) -> String? {
        self.headers.first(name: key)
    }
    
    public func query(for key: String) -> String? {
        self.queryItems
            .filter ({ $0.name == key })
            .first?
            .value
    }
    
    public func pathComponent(for key: String) -> String? {
        self.pathParameters.first(where: { $0.parameter == key })?
            .stringValue
    }
    
    public func decodeBody<T>(encoding: BodyEncoding = .json) throws -> T where T: Decodable {
        let body = try self.body.unwrap(or: PapyrusValidationError("Expecting a request body."))
        do {
            return try body.decodeJSON(as: T.self)
        } catch let DecodingError.keyNotFound(key, _) {
            throw PapyrusValidationError("Missing field `\(key.stringValue)` from request body.")
        } catch let DecodingError.typeMismatch(type, context) {
            let key = context.codingPath.last?.stringValue ?? "unknown"
            throw PapyrusValidationError("Request body field `\(key)` should be a `\(type)`.")
        } catch {
            throw PapyrusValidationError("Invalid request body.")
        }
    }
}

extension EndpointMethod {
    /// Converts the Papyrus HTTP verb type to it's NIO equivalent.
    fileprivate var nio: HTTPMethod {
        HTTPMethod(rawValue: self.rawValue)
    }
}

extension EndpointGroup {
    /// Initializes an EndpointGroup with an empty `baseURL`. Should only be used when _providing_
    /// (i.e. `router.register(group.someEndpoint)`) not _consuming_ endpoints.
    public convenience init() {
        self.init(baseURL: "")
    }
}
