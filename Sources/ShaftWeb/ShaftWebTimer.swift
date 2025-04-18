import JavaScriptKit
import Shaft

public class ShaftWebTimer: Shaft.Timer {
    public init(delay: Duration, f: @escaping () -> Void) {
        self.callback = f
        self.timeoutID = .number(0)
        self.timeoutID = JSObject.global.setTimeout!(
            JSClosure { _ in
                self.onTimeout()
                return .undefined
            },
            Int(delay.inMilliseconds)
        )
    }

    public let callback: () -> Void

    /// The ID of the timeout used to cancel the timer.
    private var timeoutID: JSValue

    /// Whether the timer has been cancelled.
    private var isCancelled = false

    /// Whether the timer has fired.
    private var hasFired = false

    private func onTimeout() {
        if isCancelled {
            return
        }

        hasFired = true
        callback()
    }

    public func cancel() {
        let _ = JSObject.global.clearTimeout!(timeoutID)
    }

    public var isActive: Bool {
        !hasFired && !isCancelled
    }
}
