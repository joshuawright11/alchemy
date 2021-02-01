import NIO

public struct Loop {
    public static var current: EventLoop {
        Container.main.resolve(EventLoop.self)
    }
    
    public static var group: EventLoopGroup {
        Container.main.resolve(EventLoopGroup.self)
    }
}
