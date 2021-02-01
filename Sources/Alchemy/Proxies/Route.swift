/// The router to which all incoming requests in your application
/// are routed.
public var Route: Router {
    get { Container.main.resolve(Router.self) }
}
