import JavaScriptKit

/// The HTML engine used by the current browser.
enum BrowserEngine: String {
    /// The engine that powers Chrome, Samsung Internet Browser, UC Browser,
    /// Microsoft Edge, Opera, and others.
    ///
    /// Blink is assumed in case when a more precise browser engine wasn't
    /// detected.
    case blink
    /// The engine that powers Safari.
    case webkit
    /// The engine that powers Firefox.
    case firefox
}

/// Operating system where the current browser runs.
///
/// Taken from the navigator platform.
/// <https://developer.mozilla.org/en-US/docs/Web/API/NavigatorID/platform>
enum OperatingSystem: String {
    /// iOS: <http://www.apple.com/ios/>
    case iOS
    /// Android: <https://www.android.com/>
    case android
    /// Linux: <https://www.linux.org/>
    case linux
    /// Windows: <https://www.microsoft.com/windows/>
    case windows
    /// MacOS: <https://www.apple.com/macos/>
    case macOS
    /// We were unable to detect the current operating system.
    case unknown
}

// List of Operating Systems we know to be working on laptops/desktops.
//
// These devices tend to behave differently on many core issues such as events,
// screen readers, input devices.
private let _desktopOperatingSystems: Set<OperatingSystem> = [
    .macOS,
    .linux,
    .windows,
]

/// The core Browser Detection functionality from the Flutter web engine.
class BrowserDetection {
    private init() {}

    /// The singleton instance of the [BrowserDetection] class.
    static let instance = BrowserDetection()

    /// Returns the User Agent of the current browser.
    var userAgent: String {
        return debugUserAgentOverride ?? _userAgent
    }

    /// Override value for [userAgent].
    ///
    /// Setting this to `null` uses the default [domWindow.navigator.userAgent].
    package var debugUserAgentOverride: String?

    // Lazily initialized current user agent.
    private lazy var _userAgent: String = _detectUserAgent()

    private func _detectUserAgent() -> String {
        return JSObject.global.navigator.userAgent.string!
    }

    /// Returns the [BrowserEngine] used by the current browser.
    ///
    /// This is used to implement browser-specific behavior.
    var browserEngine: BrowserEngine {
        return debugBrowserEngineOverride ?? _browserEngine
    }

    /// Override the value of [browserEngine].
    ///
    /// Setting this to `null` lets [browserEngine] detect the browser that the
    /// app is running on.
    package var debugBrowserEngineOverride: BrowserEngine?

    // Lazily initialized current browser engine.
    private lazy var _browserEngine: BrowserEngine = _detectBrowserEngine()

    private func _detectBrowserEngine() -> BrowserEngine {
        let vendor = JSObject.global.navigator.vendor.string!
        let agent = userAgent.lowercased()
        return detectBrowserEngineByVendorAgent(vendor: vendor, agent: agent)
    }

    /// Detects browser engine for a given vendor and agent string.
    package func detectBrowserEngineByVendorAgent(vendor: String, agent: String) -> BrowserEngine {
        if vendor == "Google Inc." {
            return .blink
        } else if vendor == "Apple Computer, Inc." {
            return .webkit
        } else if agent.contains("Edg/") {
            // Chromium based Microsoft Edge has `Edg` in the user-agent.
            // https://docs.microsoft.com/en-us/microsoft-edge/web-platform/user-agent-string
            return .blink
        } else if vendor == "" && agent.contains("firefox") {
            // An empty string means firefox:
            // https://developer.mozilla.org/en-US/docs/Web/API/Navigator/vendor
            return .firefox
        }

        // Assume Blink otherwise, but issue a warning.
        print(
            "WARNING: failed to detect current browser engine. Assuming this is a Chromium-compatible browser."
        )
        return .blink
    }

    /// Returns the [OperatingSystem] the current browsers works on.
    ///
    /// This is used to implement operating system specific behavior such as
    /// soft keyboards.
    var operatingSystem: OperatingSystem {
        return debugOperatingSystemOverride ?? _operatingSystem
    }

    /// Override the value of [operatingSystem].
    ///
    /// Setting this to `null` lets [operatingSystem] detect the real OS that the
    /// app is running on.
    ///
    /// This is intended to be used for testing and debugging only.
    package var debugOperatingSystemOverride: OperatingSystem?

    /// Lazily initialized current operating system.
    private lazy var _operatingSystem: OperatingSystem = detectOperatingSystem()

    /// Detects operating system using platform and UA used for unit testing.
    package func detectOperatingSystem(
        overridePlatform: String? = nil,
        overrideMaxTouchPoints: Int? = nil
    ) -> OperatingSystem {
        let platform = overridePlatform ?? JSObject.global.navigator.platform.string!

        if platform.starts(with: "Mac") {
            // iDevices requesting a "desktop site" spoof their UA so it looks like a Mac.
            // This checks if we're in a touch device, or on a real mac.
            let maxTouchPoints =
                overrideMaxTouchPoints ?? Int(JSObject.global.navigator.maxTouchPoints.number ?? 0)
            if maxTouchPoints > 2 {
                return .iOS
            }
            return .macOS
        } else if platform.lowercased().contains("iphone") || platform.lowercased().contains("ipad")
            || platform.lowercased().contains("ipod")
        {
            return .iOS
        } else if userAgent.contains("Android") {
            // The Android OS reports itself as "Linux armv8l" in
            // [domWindow.navigator.platform]. So we have to check the user-agent to
            // determine if the OS is Android or not.
            return .android
        } else if platform.starts(with: "Linux") {
            return .linux
        } else if platform.starts(with: "Win") {
            return .windows
        } else {
            return .unknown
        }
    }

    /// A flag to check if the current [operatingSystem] is a laptop/desktop
    /// operating system.
    var isDesktop: Bool {
        return _desktopOperatingSystems.contains(operatingSystem)
    }

    /// A flag to check if the current browser is running on a mobile device.
    ///
    /// Flutter web considers "mobile" everything that not [isDesktop].
    var isMobile: Bool {
        return !isDesktop
    }

    /// Whether the current [browserEngine] is [BrowserEngine.blink] (Chrom(e|ium)).
    var isChromium: Bool {
        return browserEngine == .blink
    }

    /// Whether the current [browserEngine] is [BrowserEngine.webkit] (Safari).
    var isSafari: Bool {
        return browserEngine == .webkit
    }

    /// Whether the current [browserEngine] is [BrowserEngine.firefox].
    var isFirefox: Bool {
        return browserEngine == .firefox
    }

    /// Whether the current browser is Edge.
    var isEdge: Bool {
        return userAgent.contains("Edg/")
    }

    /// Whether we are running from a wasm module compiled with dart2wasm.
    // var isWasm: Bool {
    //     return !Bool.fromEnvironment("dart.library.html")
    // }
}

/// A short-hand accessor to the [BrowserDetection.instance] singleton.
let browser = BrowserDetection.instance

/// A flag to check if the current browser is running on a laptop/desktop device.
var isDesktop: Bool {
    return browser.isDesktop
}

/// A flag to check if the current browser is running on a mobile device.
///
/// Flutter web considers "mobile" everything that's not [isDesktop].
var isMobile: Bool {
    return browser.isMobile
}

/// Whether the current browser is [BrowserEngine.blink] (Chrom(e|ium)).
var isChromium: Bool {
    return browser.isChromium
}

/// Whether the current browser is [BrowserEngine.webkit] (Safari).
var isSafari: Bool {
    return browser.isSafari
}

/// Whether the current browser is [BrowserEngine.firefox].
var isFirefox: Bool {
    return browser.isFirefox
}

/// Whether the current browser is Edge.
var isEdge: Bool {
    return browser.isEdge
}

/// Whether we are running from a wasm module compiled with dart2wasm.
///
/// Note: Currently the ffi library is available from dart2wasm but not dart2js
/// or dartdevc.
// var isWasm: Bool {
//     return browser.isWasm
// }

// Whether the detected `operatingSystem` is `OperatingSystem.iOs`.
private var isIOS: Bool {
    return browser.operatingSystem == .iOS
}

/// Whether the browser is running on macOS or iOS.
///
/// - See [operatingSystem].
/// - See [OperatingSystem].
var isMacOrIOS: Bool {
    return isIOS || browser.operatingSystem == .macOS
}

/// Detect iOS 15.
var isIOS15: Bool {
    return (isIOS && browser.userAgent.contains("OS 15_"))
}
