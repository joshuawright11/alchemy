extension Proxy: Database where Service == Database {
    var migrations: [Migration] {
        get { self.service.migrations }
        set { self.service.migrations = newValue }
    }
    
    var grammar: Grammar {
        self.service.grammar
    }
    
    func shutdown() throws {
        try self.service.shutdown()
    }
    
    func query() -> Query {
        Query(database: self.service)
    }
    
    func runRawQuery(_ sql: String, values: [DatabaseValue]) -> EventLoopFuture<[DatabaseRow]> {
        self.service.runRawQuery(sql, values: values)
    }
}

