//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import Fusion
import NIO
import NIOHTTP1
import NIOHTTP2
import ArgumentParser

public struct Alchemy<A: Application>: ParsableCommand {
    @Option
    var host = "::1"

    @Option
    var port = 8888
    
    @Flag(help: "Run migrations, instead of serving")
    var migrate = false
    
    public init() {}
    
    public func run() throws {
        try A.init().run()
    }
}

public protocol Application {
    init()
    
    func setup()
}

enum BindTo {
    case ip(host: String, port: Int)
    case unixDomainSocket(path: String)
}

enum StartupArgs {
    case serve(target: BindTo)
    case migrate
}

public extension Application {
    private func parseArgs() -> StartupArgs {
        // First argument is the program path
        let arguments = CommandLine.arguments.dropFirst(0) // just to get an ArraySlice<String> from [String]
        let arg1 = arguments.dropFirst().first
        let arg2 = arguments.dropFirst(2).first
        
        let defaultHost = "::1"
        let defaultPort = 8888

        let bindTarget: BindTo

        switch (arg1, arg1.flatMap(Int.init), arg2, arg2.flatMap(Int.init)) {
        case (.some(let h), _ , _, .some(let p)):
            /* second arg an integer --> host port [htdocs] */
            bindTarget = .ip(host: h, port: p)
        case (_, .some(let p), _, _):
            /* first arg an integer --> port [htdocs] */
            bindTarget = .ip(host: defaultHost, port: p)
        case (.some(let portString), .none, _, .none):
            bindTarget = .unixDomainSocket(path: portString)
        default:
            bindTarget = .ip(host: defaultHost, port: defaultPort)
        }
        
        return .serve(target: bindTarget)
    }
    
    func run() throws {
        // Setup environment
        _ = Env.current
        
        // Get the global MultiThreadedEventLoopGroup
        let group = try Container.global.resolve(MultiThreadedEventLoopGroup.self)

        // First, setup the application (on an `EventLoop` from the global group so `Loop.current` can be
        // used.)
        _ = group.next().submit(self.setup)
        
        let args = self.parseArgs()

        switch args {
        case .migrate:
            self.migrate(group: group)
        case .serve(let target):
            try self.startServing(target: target, group: group)
        }
    }
    
    private func migrate(group: MultiThreadedEventLoopGroup) {
        print("Migrate time")
    }
    
    private func startServing(target: BindTo, group: MultiThreadedEventLoopGroup) throws {
        func childChannelInitializer(channel: Channel) -> EventLoopFuture<Void> {
            channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                channel.pipeline.addHandler(HTTPHandler(responder: HTTPRouterResponder()))
            }
        }

        let socketBootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)

            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer(childChannelInitializer(channel:))

            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)

        defer {
            try! group.syncShutdownGracefully()
        }

        let channel = try { () -> Channel in
            switch target {
            case .ip(let host, let port):
                return try socketBootstrap.bind(host: host, port: port).wait()
            case .unixDomainSocket(let path):
                return try socketBootstrap.bind(unixDomainSocketPath: path).wait()
            }
        }()

        guard let channelLocalAddress = channel.localAddress else {
            fatalError("Address was unable to bind. Please check that the socket was not closed or that the address family was understood.")
        }
        
        let localAddress: String = "\(channelLocalAddress)"
        
        print("Server started and listening on \(localAddress).")

        // This will never unblock as we don't close the ServerChannel
        try channel.closeFuture.wait()

        print("Server closed")
    }
}
