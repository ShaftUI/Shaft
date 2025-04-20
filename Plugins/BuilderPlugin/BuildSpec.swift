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
//             "name": "Copy ShaftBrowser Helper.app to ShaftBrowser.app/Contents/Frameworks",
//             "type": "copy",
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
    case copy = "copy"
}

enum BuildStep: Codable {
    case macOSBundle(MacOSBundleInput)
    case copy(CopyInput)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(BuildStepType.self, forKey: .type)
        switch type {
        case .macOSBundle:
            self = .macOSBundle(try container.decode(MacOSBundleInput.self, forKey: .with))
        case .copy:
            self = .copy(try container.decode(CopyInput.self, forKey: .with))
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case .macOSBundle(let input):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(BuildStepType.macOSBundle, forKey: .type)
            try container.encode(input, forKey: .with)
        case .copy(let input):
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(BuildStepType.copy, forKey: .type)
            try container.encode(input, forKey: .with)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case with
    }
}
