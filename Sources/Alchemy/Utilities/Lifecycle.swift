import Lifecycle

public struct Lifecycle {
    public static var main: ServiceLifecycle {
        Container.main.resolve(ServiceLifecycle.self)
    }
}
