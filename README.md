![ShaftDemo](/docs/demo.png)

## Get Stared
```
swift package plugin setup-skia

swift run Playground
```

These commands will launch the built-in [Playground](/Sources/Playground/main.swift) application, which serves as both an interactive demonstration and comprehensive documentation for the Shaft framework.

> The `setup-skia` command downloads prebuilt Skia binaries to the `./.shaft` directory for the package to use. In the future we may get rid of this when [swift-package-manager#7035](https://github.com/swiftlang/swift-package-manager/issues/7035) has made progress.

To create a new project with Shaft, the [CounterTemplate](https://github.com/ShaftUI/CounterTemplate) is a good starting point.

## Features

- **Simple & Hackable**
  
No build infrastructure or special toolchain required - just a regular Swift package containing both engine and framework, makes it easy to customize, extend, and adapt to your specific needs.

- **Built for demanding workloads**

Built for demanding workloads with native multi-threading support, direct low-level graphics API access, and deterministic memory management through ARC. Scales effortlessly from simple apps to complex, resource-intensive applications.

- **Modular design**

Shaft's modular design enables integration of custom backends and renderers without much effort. This flexibility allows for unique use cases like [terminal-based UI](https://en.wikipedia.org/wiki/Text-based_user_interface) or creating [Wayland](https://wayland.freedesktop.org/) compositors, enabling developers to adapt the framework for specialized use cases.

- **Automatic UI-data synchronization**

Data marked with `@Observable` enables automatic UI updates when values change. The framework automatically tracks these objects and efficiently refreshes only the affected UI components, eliminating the need for manual state management and reducing boilerplate code. This reactive approach ensures your UI stays synchronized with your data in a performant way:

```swift
@Observable class Counter {
    var count = 0
}

let counter = Counter()

class CounterView: StatelessWidget {
    func build(context: any BuildContext) -> any Widget {
        Column {
            Text("Count: \(counter.count)")

            Button {
                counter.count += 1
            } child: {
                Text("Increment")
            }
        }
    }
}
```

## Concepts

![Architecture](/docs/architecture.png)

- **Shaft Framework**: Basicly a port of [Flutter](https://flutter.dev/)'s framework part to Swift with minor changes. Most of Flutter's concepts should be applicable.
- **Shaft.Backend**: An protocol that provides everything that the framework requires to run, such as event loop, text input, etc. It's a layer that abstracts the platform specific code.
- **Shaft.Renderer**: An protocol that abstracts the underlying graphics API, such as Skia or CoreGraphics.
- **ShaftKit**: The built-in customizable widget toolkit that provides high-level widgets for rapid application development.
- **ShaftApp**: The application that developer writes. 

More documentation can be found in the [Playground]() app.