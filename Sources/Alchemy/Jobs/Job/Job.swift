import NIO

/// A task that can be persisted and queued for future handling.
public protocol Job: Codable {
    /// The name of this Job. Defaults to the type name.
    static var name: String { get }
    /// The recovery strategy for this job. Defaults to none.
    var recoveryStrategy: RecoveryStrategy { get }
    /// Called when a job finishes, either successfully or with too
    /// many failed attempts.
    func finished(result: Result<Void, Error>)
    /// Run this Job.
    func run() -> EventLoopFuture<Void>
}

// Defaults
extension Job {
    public static var name: String { Alchemy.name(of: Self.self) }
    public var recoveryStrategy: RecoveryStrategy { .none }
    
    public func finished(result: Result<Void, Error>) {
        switch result {
        case .success:
            Log.info("Job '\(Self.name)' succeeded.")
        case .failure(let error):
            Log.error("Job '\(Self.name)' failed with error: \(error).")
        }
    }
}

public enum RecoveryStrategy {
    /// Removes task from the queue
    case none
    /// Retries the task a specified amount of times
    case retry(Int)
    
    var maximumRetries: Int {
        switch self {
        case .none:
            return 0
        case .retry(let maxRetries):
            return maxRetries
        }
    }
}

extension RecoveryStrategy: Codable {
    enum CodingKeys: String, CodingKey {
        case none, retry
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let intValue = try container.decodeIfPresent(Int.self, forKey: .retry) {
            self = .retry(intValue)
        }
        else {
            self = .none
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encodeNil(forKey: .none)
        case .retry(let value):
            try container.encode(value, forKey: .retry)
        }
    }
}
