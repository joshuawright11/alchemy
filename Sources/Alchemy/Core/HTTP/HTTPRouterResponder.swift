import Fusion
import NIO

/// Used for responding to all incoming `Request`s in a serving
/// `Application`.
struct HTTPRouterResponder: HTTPResponder {
    func respond(to request: Request) -> EventLoopFuture<Response> {
        var handlerClosure = Route.handle
        
        for middleware in Route.globalMiddlewares.reversed() {
            let lastHandler = handlerClosure
            handlerClosure = { request in
                catchError {
                    try middleware.intercept(request) { request in
                        catchError {
                            try lastHandler(request)
                        }
                    }
                }
            }
        }
        
        return catchError {
            try handlerClosure(request)
        }
    }
}
