import RediStack

public typealias RedisProxy = Proxy<RedisClient>

/// The main `Redis` client of your app. If using Redis, don't
/// forget to set this in your `Application.setup` before
/// accessing!
public var redis: RedisClient & RedisProxy {
    RedisProxy()
}

extension RedisProxy: RedisClient {
    public var eventLoop: EventLoop {
        self.resolve().eventLoop
    }
    
    public func logging(to logger: Logger) -> RedisClient {
        self.resolve().logging(to: logger)
    }
    
    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        self.resolve().send(command: command, with: arguments).hop(to: Loop.current)
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        self.resolve()
            .subscribe(
                to: channels,
                messageReceiver: receiver,
                onSubscribe: subscribeHandler,
                onUnsubscribe: unsubscribeHandler
            )
    }

    public func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        self.resolve()
            .psubscribe(
                to: patterns,
                messageReceiver: receiver,
                onSubscribe: subscribeHandler,
                onUnsubscribe: unsubscribeHandler
            )
    }
    
    public func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        self.resolve().unsubscribe(from: channels)
    }
    
    public func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        self.resolve().punsubscribe(from: patterns)
    }
}
