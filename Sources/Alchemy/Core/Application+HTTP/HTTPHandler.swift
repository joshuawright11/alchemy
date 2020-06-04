import NIO
import NIOHTTP1

/// Ripped from
/// https://www.raywenderlich.com/8016626-swiftnio-tutorial-practical-guide-for-asynchronous-problems

/// Any type that can respond to HTTP requests
protocol HTTPResponder {
    func respond(to request: HTTPRequest) -> EventLoopFuture<HTTPResponse>
}

/// Responds to incoming HTTPRequests with an HTTPResponse generated by the Responder
final class HTTPHandler<Responder: HTTPResponder>: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
  
    // Indicates that the TCP connection needs to be closed after a response has been sent
    private var closeAfterResponse = true
  
    /// A temporary local HTTPRequest that is used to accumulate data into
    private var request: HTTPRequest?
  
    /// The Responder type that responds to requests
    private let responder: Responder
  
    init(responder: Responder) {
        self.responder = responder
    }
  
    /// Received incoming `InboundIn` data
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = self.unwrapInboundIn(data)
    
        switch part {
        case .head(let requestHead):
            // If the part is a `head`, a new Request is received
            self.closeAfterResponse = !requestHead.isKeepAlive
      
            let contentLength: Int
      
            // We need to check the content length to reserve memory for the body
            if let length = requestHead.headers["content-length"].first {
                contentLength = Int(length) ?? 0
            } else {
                contentLength = 0
            }
      
            // Disallows bodies over 50 megabytes of data
            // 50MB is a huge amount of data to receive and accumulate in one request
            // This is normal for video uploading, but this implementation isn't optimized for thats
            if contentLength > 50_000_000 {
                context.close(promise: nil)
                return
            }
      
            let body: ByteBuffer?
      
            // Allocates the memory for accumulation
            if contentLength > 0 {
                body = context.channel.allocator.buffer(capacity: contentLength)
            } else {
                body = nil
            }
      
            self.request = HTTPRequest(eventLoop: context.eventLoop,
                                       head: requestHead,
                                       bodyBuffer: body)
        case .body(var newData):
            // Appends new data to the already reserved buffer
            self.request?.bodyBuffer?.writeBuffer(&newData)
        case .end:
            guard let request = request else { return }
      
            // Responds to the request
            let response = responder.respond(to: request)
                .flatMapErrorThrowing { error in
                    print("Encountered error: \(error).")
                    if let error = error as? HTTPError {
                        return HTTPResponse(
                            status: error.status,
                            body: HTTPBody(text: error.message ?? "error")
                        )
                    } else {
                        return HTTPResponse(status: .internalServerError, body: HTTPBody(text: "server error"))
                    }
                }
            self.request = nil
      
            // Writes the response when done
            self.writeResponse(response, to: context)
        }
    }
  
    /// Writes the response after the response has been created
    @discardableResult
    private func writeResponse(_ response: EventLoopFuture<HTTPResponse>, to context: ChannelHandlerContext)
        -> EventLoopFuture<Void>
    {
        func writeBody(_ buffer: ByteBuffer) {
            context.write(self.wrapOutboundOut(.body(IOData.byteBuffer(buffer))), promise: nil)
        }
    
        func writeHead(_ head: HTTPResponseHead) {
            context.write(self.wrapOutboundOut(.head(head)), promise: nil)
        }
    
        let responded = response.map { response -> Void in
            var responseHead = response.head
            responseHead.headers.remove(name: "content-length")
      
            if let body = response.body {
                let buffer = body.buffer
                responseHead.headers.add(name: "content-length", value: String(buffer.writerIndex))
        
                if let mimeType = body.mimeType {
                    responseHead.headers.remove(name: "content-type")
                    responseHead.headers.add(name: "content-type", value: mimeType)
                }
        
                writeHead(response.head)
                writeBody(buffer)
            } else {
                writeHead(response.head)
            }
        }.flatMap {
            return context.writeAndFlush(self.wrapOutboundOut(.end(nil)))
        }
    
        responded.whenComplete { _ in
            if self.closeAfterResponse {
                context.close(promise: nil)
            }
        }
    
        return responded
    }
  
    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
}
