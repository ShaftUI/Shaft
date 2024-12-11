// import Metal
// import QuartzCore
// import SwiftSDL3

// func runMetalApp() {
//     let device = MTLCreateSystemDefaultDevice()!
//     let commandQueue = device.makeCommandQueue()!

//     let vertexData: [Float] = [
//         0.0, 1.0, 0.0, 1.0,
//         -1.0, -1.0, 0.0, 1.0,
//         1.0, -1.0, 0.0, 1.0,
//     ]
//     let vertexArray = device.makeBuffer(
//         bytes: vertexData,
//         length: vertexData.count * MemoryLayout<Float>.size,
//         options: []
//     )!

//     let pipelineDescriptor = MTLRenderPipelineDescriptor()
//     // let library = device.makeDefaultLibrary()!
//     // let library = try! device.makeDefaultLibrary(bundle: Bundle.module)
//     let library = try! device.makeLibrary(
//         source: """
//             struct Vertex
//             {
//                 float4 position;
//                 // float4 color;
//             };

//             struct VertexOut
//             {
//                 float4 position [[position]];
//                 float4 color;
//             };

//             vertex VertexOut vertexShader(
//                 const device Vertex *vertices [[buffer(0)]],
//                 unsigned int vid [[vertex_id]]
//             ) {
//                 VertexOut out;
//                 out.position = vertices[vid].position;
//                 // out.color = vertices[vid].color;
//                 out.color = float4(1.0, 1.0, 0.0, 1.0);
//                 return out;
//             }

//             fragment float4 fragmentShader(
//                 VertexOut interpolated [[stage_in]]
//             ) {
//                 return interpolated.color;
//             }
//             """,
//         options: nil
//     )

//     let vertexFunction = library.makeFunction(name: "vertexShader")
//     let fragmentFunction = library.makeFunction(name: "fragmentShader")
//     pipelineDescriptor.vertexFunction = vertexFunction
//     pipelineDescriptor.fragmentFunction = fragmentFunction
//     pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
//     let pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)

//     let props = SDL_CreateProperties()
//     defer { SDL_DestroyProperties(props) }
//     SDL_SetBooleanProperty(props, SDL_PROP_WINDOW_CREATE_HIGH_PIXEL_DENSITY_BOOLEAN, true)
//     SDL_SetBooleanProperty(props, SDL_PROP_WINDOW_CREATE_METAL_BOOLEAN, true)
//     SDL_SetBooleanProperty(props, SDL_PROP_WINDOW_CREATE_RESIZABLE_BOOLEAN, true)

//     let window = SDL_CreateWindowWithProperties(props)!
//     SDL_ShowWindow(window)

//     let metalView = SDL_Metal_CreateView(window)!
//     let metalLayer = unsafeBitCast(SDL_Metal_GetLayer(metalView)!, to: CAMetalLayer.self)
//     metalLayer.device = device
//     metalLayer.pixelFormat = .bgra8Unorm
//     metalLayer.framebufferOnly = true
//     metalLayer.drawableSize = CGSize(width: 320, height: 240)

//     let drawable = metalLayer.nextDrawable()!
//     // commandBuffer.present(drawable)
//     // commandBuffer.commit()

//     let renderPassDescriptor = MTLRenderPassDescriptor()
//     renderPassDescriptor.colorAttachments[0].texture = drawable.texture
//     renderPassDescriptor.colorAttachments[0].loadAction = .clear
//     renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0)

//     let commandBuffer = commandQueue.makeCommandBuffer()!
//     let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
//     renderEncoder.setRenderPipelineState(pipelineState)
//     renderEncoder.setVertexBuffer(vertexArray, offset: 0, index: 0)
//     renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
//     renderEncoder.endEncoding()

//     commandBuffer.present(drawable)
//     commandBuffer.commit()

//     SDL_ShowWindow(window)
//     while true {
//         var event = SDL_Event()
//         SDL_WaitEvent(&event)

//         // SDL_Delay(10)
//         if event.type == SDL_EVENT_QUIT.rawValue {
//             break
//         }
//     }

// }
