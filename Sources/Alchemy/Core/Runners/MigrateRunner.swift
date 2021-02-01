import NIO

/// Run migrations on `DB`, optionally rolling back the
/// latest batch.
struct MigrateRunner: Runner {
    /// Indicates whether migrations should be run (`false`) or rolled
    /// back (`true`).
    let rollback: Bool
    
    // MARK: Runner
    
    func start() -> EventLoopFuture<Void> {
        Loop.group
            .next()
            .flatSubmit(self.rollback ? DB.rollbackMigrations : DB.migrate)
            // Shut down everything when migrations are finished.
            .map {
                Log.info("[Migration] migrations finished, shutting down.")
                Lifecycle.main.shutdown()
            }
    }
    
    func shutdown() -> EventLoopFuture<Void> {
        Loop.group.future()
    }
}
