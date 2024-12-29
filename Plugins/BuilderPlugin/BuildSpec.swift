// {
//     "app": {
//         "name": "Playground",
//         "identifier": "dev.shaftui.playground",
//         "version": "1.0.0",
//         "product": "Playground"
//     }
// }
struct BuildSpec: Codable {
    let app: AppSpec?
}

/// The specification for the app
struct AppSpec: Codable {
    /// The name of the app
    let name: String

    /// The identifier of the app. This is usually a reverse domain name.
    let identifier: String

    /// The version of the app
    let version: String

    /// Name of the product defined in the package. The product will be used to
    /// create the bundle.
    let product: String
}
