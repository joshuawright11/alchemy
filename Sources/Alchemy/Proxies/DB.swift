public typealias DatabaseProxy = Proxy<Database>

/// The main database of your app. By default, this isn't
/// registered, so don't forget to do so in your
/// `Application.setup`!
///
/// ```swift
/// struct MyServer: Application {
///     func setup() {
///         DB = PostgresDatabase(
///             DatabaseConfig(
///                 socket: .ip(host: "localhost", port: 5432),
///                 database: "alchemy",
///                 username: "admin",
///                 password: "password"
///             )
///         )
///     }
/// }
///
/// // Now, `DB` is usable elsewhere.
/// DB // `PostgresDatabase(...)` registered above
///     .runRawQuery("select * from users;")
///     .whenSuccess { rows in
///         print("Got \(rows.count) results!")
///     }
/// ```
public var DB: Database & DatabaseProxy { DatabaseProxy() }

extension Proxy: Database where Service == Database {
    public var migrations: [Migration] {
        get { self.resolve().migrations }
        set { self.resolve().migrations = newValue }
    }
    
    public var grammar: Grammar {
        self.resolve().grammar
    }
    
    public func shutdown() throws {
        try self.resolve().shutdown()
    }
    
    public func query() -> Query {
        Query(database: self.resolve())
    }
    
    public func runRawQuery(_ sql: String, values: [DatabaseValue]) -> EventLoopFuture<[DatabaseRow]> {
        self.resolve().runRawQuery(sql, values: values)
    }
}

extension Proxy.Config where Service == Database {
    static func mysql(_ socket: Socket, database: String, username: String, password: String) -> Self {
        return Self(
            MySQLDatabase(
                config: DatabaseConfig(
                    socket: socket,
                    database: database,
                    username: username,
                    password: password
                )
            )
        )
    }
    
    static func postgres(_ socket: Socket, database: String, username: String, password: String) -> Self {
        return Self(
            PostgresDatabase(
                config: DatabaseConfig(
                    socket: socket,
                    database: database,
                    username: username,
                    password: password
                )
            )
        )
    }
}

