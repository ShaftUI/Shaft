import Foundation

#if canImport(JavaScriptKit)
    import JavaScriptKit
#elseif canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Fetches data from a URL.
public func fetch(_ url: URL) async throws -> Data {
    #if canImport(JavaScriptKit)
        let jsFetch = JSObject.global.fetch.function!
        let response = try await JSPromise(jsFetch(url.absoluteString).object!)!.jsValue
        let buffer = try await JSPromise(response.arrayBuffer().object!)!.jsValue
        print(buffer)
        return Data()
    #else
        return try await URLSession.shared.data(from: url).0
    #endif
}
