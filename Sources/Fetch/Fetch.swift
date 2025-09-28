import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
// #elseif canImport(JavaScriptKit)
//     import JavaScriptKit
#endif

/// Fetches data from a URL.
public func fetch(_ url: URL) async throws -> Data {
    #if os(WASI)
        //     let jsFetch = JSObject.global.fetch.function!
        //     let response = try await JSPromise(jsFetch(url.absoluteString).object!)!.jsValue
        //     let buffer = try await JSPromise(response.arrayBuffer().object!)!.jsValue
        //     return Data()
        throw NSError(
            domain: "Fetch",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Fetch is not supported on JavaScriptKit"]
        )
    #else
        return try await URLSession.shared.data(from: url).0
    #endif
}
