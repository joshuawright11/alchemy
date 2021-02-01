/// A scheduler for scheduling recurring tasks.
public var Schedule: Scheduler {
    Container.main.resolve(Scheduler.self)
}
