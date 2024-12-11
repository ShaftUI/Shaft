/// Provides [Ticker] objects that are configured to only tick while the current
/// tree is enabled, as defined by [TickerMode].
///
/// To create an [AnimationController] in a class that uses this mixin, pass
/// `vsync: this` to the animation controller constructor whenever you
/// create a new animation controller.
///
/// If you only have a single [Ticker] (for example only a single
/// [AnimationController]) for the lifetime of your [State], then using a
/// [SingleTickerProviderStateMixin] is more efficient. This is the common case.
public class TickerProviderStateMixin: TickerProvider, StateMixin {
    public func initState() {}

    public func didUpdateWidget(_ oldWidget: any Widget) {}

    public func didChangeDependencies() {}

    public func deactivate() {}

    private var _tickers: [Ticker]?

    // private var _tickerModeNotifier: any ValueListenable<Bool>?

    public func createTicker(_ onTick: @escaping TickerCallback) -> Ticker {
        // if _tickerModeNotifier == nil {
        //     // Setup TickerMode notifier before we vend the first ticker.
        //     _updateTickerModeNotifier()
        // }
        // assert(_tickerModeNotifier != nil)
        _tickers = _tickers ?? [_WidgetTicker]()
        let result = _WidgetTicker(
            onTick,
            self
        )
        // result.muted = !_tickerModeNotifier!.value
        _tickers!.append(result)
        return result
    }

    fileprivate func _removeTicker(_ ticker: _WidgetTicker) {
        assert(_tickers != nil)
        assert(_tickers!.contains(object: ticker))
        _tickers!.remove(object: ticker)
    }

    public func activate() {
        // // We may have a new TickerMode ancestor, get its Notifier.
        // _updateTickerModeNotifier()
        _updateTickers()
    }

    private func _updateTickers() {
        // if let tickers = _tickers {
        //     let muted = !_tickerModeNotifier!.value
        //     for ticker in tickers {
        //         ticker.muted = muted
        //     }
        // }
    }

    // private func _updateTickerModeNotifier() {
    //     let newNotifier = TickerMode.getNotifier(context)
    //     if newNotifier === _tickerModeNotifier {
    //         return
    //     }
    //     _tickerModeNotifier?.removeListener(_updateTickers)
    //     newNotifier.addListener(_updateTickers)
    //     _tickerModeNotifier = newNotifier
    // }

    public func dispose() {
        assert(
            {
                if let tickers = _tickers {
                    for ticker in tickers {
                        if ticker.isActive {

                            assertionFailure("\(self) was disposed with an active Ticker.")
                        }
                    }
                }
                return true
            }()
        )
        // _tickerModeNotifier?.removeListener(_updateTickers)
        // _tickerModeNotifier = nil
    }
}

// This class should really be called _DisposingTicker or some such, but this
// class name leaks into stack traces and error messages and that name would be
// confusing. Instead we use the less precise but more anodyne "_WidgetTicker",
// which attracts less attention.
private class _WidgetTicker: Ticker {
    private weak var _creator: TickerProviderStateMixin?

    init(_ onTick: @escaping TickerCallback, _ creator: TickerProviderStateMixin) {
        _creator = creator
        super.init(onTick)
    }

    override func dispose() {
        _creator?._removeTicker(self)
        super.dispose()
    }
}
