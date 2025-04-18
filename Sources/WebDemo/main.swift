import JavaScriptEventLoop
import JavaScriptKit
import Shaft
import ShaftWeb

Shaft.backend = ShaftWebBackend(onCreateElement: { viewID in
    let document = JSObject.global.document
    return document.querySelector("canvas")
})

print("Hello, Web!")

runApp(
    Column(crossAxisAlignment: .start) {
        Button {
            print("Hello, Button!")
        } child: {
            Text("Hello World")
        }
    }
)
