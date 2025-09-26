import JavaScriptKit
import Shaft

public class ShaftWebTimer: Shaft.Timer {
    public init(delay: Duration, repeats: Bool, callback: @escaping () -> Void) {
        self.callback = callback
        self.repeats = repeats

        let closure = JSClosure { [weak self] _ in
            guard let self else { return .undefined }
            self.handleFire()
            return .undefined
        }
        self.jsClosure = closure

        let milliseconds = max(0, Int(delay.inMilliseconds))
        if repeats {
            timerID = JSObject.global.setInterval!(closure, milliseconds)
        } else {
            timerID = JSObject.global.setTimeout!(closure, milliseconds)
        }
    }

    deinit {
        cancel()
    }

    public let callback: () -> Void

    private let repeats: Bool
    private var timerID: JSValue?
    private var jsClosure: JSClosure?
    private var isCancelled = false
    private var hasFired = false

    private func handleFire() {
        if isCancelled { return }

        hasFired = true
        callback()

        if !repeats {
            clearScheduledTimer()
            releaseClosure()
        }
    }

    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true

        clearScheduledTimer()
        releaseClosure()
    }

    public var isActive: Bool {
        if isCancelled { return false }
        return repeats || !hasFired
    }

    private func clearScheduledTimer() {
        guard let timerID else { return }

        if repeats {
            let _ = JSObject.global.clearInterval!(timerID)
        } else {
            let _ = JSObject.global.clearTimeout!(timerID)
        }

        self.timerID = nil
    }

    private func releaseClosure() {
        jsClosure = nil
    }
}
