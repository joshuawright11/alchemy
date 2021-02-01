import Fusion
import Lifecycle
import LifecycleNIOCompat
import NIO
import NIOHTTP1

/// The core type for an Alchemy application. Implement this & it's
/// `setup` function, then call `MyApplication.launch()` in your
/// `main.swift`.
///
/// ```swift
/// // MyApplication.swift
/// struct App: Application {
///     func setup() {
///         self.get("/hello") { _ in
///             "Hello, world!"
///         }
///         ...
///     }
/// }
///
/// // main.swift
/// App.launch()
/// ```
public protocol Application {
    /// Called before any launch command is run. Called AFTER any
    /// environment is loaded and the global
    /// `MultiThreadedEventLoopGroup` is set. Called on an event loop,
    /// so `Loop.current` is available for use if needed.
    func setup()
    
    /// Required empty initializer.
    init()
}

extension Application {
    func boot(_ lifecycle: ServiceLifecycle) {
        // `Router`
        Container.main.register(singleton: Router.self) { _ in
            Router()
        }
        
        // `Scheduler`
        Container.main.register(singleton: Scheduler.self) { container in
            Scheduler(scheduleLoop: container.resolve(EventLoop.self))
        }
        
        // `HTTPClient`
        Container.main.register(singleton: HTTPClient.self) { container in
            let group = container.resolve(EventLoopGroup.self)
            return HTTPClient(eventLoopGroupProvider: .shared(group))
        }
        
        // `EventLoopGroup`
        Container.main.register(singleton: EventLoopGroup.self) { _ in
            MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        }
        
        // `EventLoop`
        Container.main.register(EventLoop.self) { _ in
            guard let current = MultiThreadedEventLoopGroup.currentEventLoop else {
                fatalError("This code isn't running on an `EventLoop`!")
            }

            return current
        }
        
        // `NIOThreadPool`
        Container.main.register(singleton: NIOThreadPool.self) { _ in
            let pool = NIOThreadPool(numberOfThreads: System.coreCount)
            pool.start()
            return pool
        }
        
        // `ServiceLifecycle`
        Container.main.register(singleton: ServiceLifecycle.self) { _ in
            return lifecycle
        }
    }
    
    /// Shutdown some commonly used services registered to
    /// `Container.global`.
    ///
    /// This should not be run on an `EventLoop`!
    func shutdown() throws {
        try HTTP.syncShutdown()
        // Shutdown the main database, if it exists.
        try Container.main.resolveOptional(Database.self)?.shutdown()
        try Thread.pool.syncShutdownGracefully()
        try Loop.group.syncShutdownGracefully()
    }
    
    /// Mocks many common services. Can be called in the `setUp()`
    /// function of test cases.
    public func mock() {
        Container.main = Container()
        Container.main.register(singleton: Router.self) { _ in Router() }
        Container.main.register(EventLoop.self) { _ in EmbeddedEventLoop() }
        Container.main.register(singleton: EventLoopGroup.self) { _ in MultiThreadedEventLoopGroup(numberOfThreads: 1) }
    }
}

extension Application {
    /// Launch the application with the provided runner. It will setup
    /// core services, call `self.setup()`, and then it's behavior
    /// will be defined by the runner.
    ///
    /// - Parameter runner: The runner that defines what the
    ///   application does when it's launched.
    /// - Throws: Any error that may be encountered in booting the
    ///   application.
    func launch(_ runner: Runner) throws {
        let lifecycle = ServiceLifecycle(
            configuration: ServiceLifecycle.Configuration(
                logger: Log.logger,
                installBacktrace: true
            )
        )
        
        lifecycle.register(
            label: "AlchemyCore",
            start: .sync { self.boot(lifecycle) },
            shutdown: .sync(self.shutdown)
        )
        
        lifecycle.register(
            label: "\(Self.self)",
            start: .eventLoopFuture {
                Loop.group.next()
                    // Run setup
                    .submit(self.setup)
                    // Start the runner
                    .flatMap(runner.start)
            },
            shutdown: .eventLoopFuture(runner.shutdown)
        )
        
        try lifecycle.startAndWait()
    }
}
