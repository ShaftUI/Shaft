import Foundation
import Shaft

#if os(macOS) || os(Linux) || os(Windows)
    import ShaftSDL3
    import ShaftSkia
#endif

/// Sets up the default backend and renderer for the Shaft framework. Use this
/// when you just want to build regular applications with Shaft.
///
/// Shaft itself does have direct dependencies on any platform-specific code.
/// Everything is abstracted away behind the [Backend] protocol. Thus, you need
/// to set up the `backend` global variable to use Shaft in your application.
public func useDefault() {
    #if os(macOS) || os(Linux) || os(Windows)
        Shaft.backend = SDLBackend(renderer: defaultSkiaRenderer())
        return
    #endif

    preconditionFailure("No backend available for this platform")
}
