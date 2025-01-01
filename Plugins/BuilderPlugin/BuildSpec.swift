// {
//     "steps": [
//         {
//             "name": "Build ShaftBrowser.app",
//             "type": "macos-bundle",
//             "with": {
//                 "name": "ShaftBrowser",
//                 "identifier": "dev.shaftui.browser",
//                 "version": "1.0.0",
//                 "product": "ShaftBrowser",
//                 "output": ".build/ShaftBrowser.app"
//             }
//         },
//         {
//             "name": "Build ShaftBrowser Helper.app",
//             "type": "macos-bundle",
//             "with": {
//                 "name": "ShaftBrowser Helper",
//                 "identifier": "dev.shaftui.browserhelper",
//                 "version": "1.0.0",
//                 "product": "ShaftBrowserHelper",
//                 "output": ".build/ShaftBrowser Helper.app"
//             }
//         },
//         {
//             "name": "Move ShaftBrowser Helper.app to ShaftBrowser.app/Contents/Frameworks",
//             "type": "move",
//             "with": {
//                 "source": ".build/ShaftBrowser Helper.app",
//                 "destination": ".build/ShaftBrowser.app/Contents/Frameworks"
//             }
//         }
//     ]
// }

struct BuildSpec: Codable {
    let steps: [BuildStep]
}

enum BuildStepType: String, Codable {
    case macOSBundle = "macos-bundle"
    case move = "move"
}

enum BuildStep: Codable {
    case macOSBundle(MacOSBundleInput)
    case move(MoveInput)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BuildStepType.self, forKey: .type)
        switch type {
        case .macOSBundle:
            self = .macOSBundle(try container.decode(MacOSBundleInput.self, forKey: .with))
        case .move:
            self = .move(try container.decode(MoveInput.self, forKey: .with))
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .macOSBundle(let input):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(BuildStepType.macOSBundle, forKey: .type)
            try container.encode(input, forKey: .with)
        case .move(let input):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(BuildStepType.move, forKey: .type)
            try container.encode(input, forKey: .with)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case with
    }
}

struct MacOSBundleInput: Codable {
    let name: String
    let identifier: String
    let version: String
    let product: String
    let output: String
}

struct MoveInput: Codable {
    let source: String
    let destination: String
}
