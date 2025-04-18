import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#elseif os(wasi)
    import JavaScriptKit
#endif

/// Fetches data from a URL.
public func fetch(_ url: URL) async throws -> Data {
    #if os(wasi)
        let jsFetch = JSObject.global.fetch.function!
        let response = try await JSPromise(jsFetch(url.absoluteString).object!)!.jsValue
        let buffer = try await JSPromise(response.arrayBuffer().object!)!.jsValue
        return Data()
    #else
        return try await URLSession.shared.data(from: url).0
    #endif
}
