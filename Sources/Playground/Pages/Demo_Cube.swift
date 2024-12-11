import Shaft

final class Demo_Cube: StatelessWidget {
    func build(context: BuildContext) -> Widget {
        PageContent {
            Text("3D Cube")
                .textStyle(.playgroundTitle)

            Text("Drawing some cubes using Metal.")
                .textStyle(.playgroundAbstract)

            HorizontalDivider()

            Text("Overview")
                .textStyle(.playgroundHeading)

            Text(
                """
                One of the core design principles of Shaft is to provide direct and unlimited access to the underlying platform APIs, \
                even without the need of bindings or wrappers in most cases.

                This demo showcases how to draw 1000 3D cubes using Metal, Apple's low-level graphics API.
                """
            )

            .textStyle(.playgroundBody)

            #if canImport(Metal)
                CubeView()
            #else
                Background {
                    Text(
                        "This demo is only available on apple platforms. OpenGL and DirectX demos are coming soon."
                    )
                    .textStyle(.playgroundBody)
                }
            #endif
        }
    }
}

#if canImport(Metal)
    import Metal
    import simd

    final class CubeView: StatefulWidget {
        func createState() -> some State<CubeView> {
            CubeViewState()
        }
    }

    final class CubeViewState: State<CubeView> {
        private var renderer: CubeRenderer!
        private var texture: MTLTexture!

        var metalRenderer: MetalRenderer {
            backend.renderer as! MetalRenderer
        }

        let size = Size(800, 800)

        override func initState() {
            super.initState()
            initTexture()
            initRenderer()
            renderer.draw(texture)
        }

        func initRenderer() {
            renderer = CubeRenderer(
                device: metalRenderer.device,
                commandQueue: metalRenderer.queue
            )
        }

        func initTexture() {
            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.width = Int(size.width)
            textureDescriptor.height = Int(size.height)
            textureDescriptor.pixelFormat = .bgra8Unorm
            textureDescriptor.textureType = .type2D
            textureDescriptor.storageMode = .managed
            textureDescriptor.usage = [.shaderWrite, .renderTarget]
            texture = metalRenderer.device.makeTexture(descriptor: textureDescriptor)!
        }

        override func build(context: BuildContext) -> Widget {
            return MouseRegion(cursor: .system(.grabbing)) {
                GestureDetector(
                    onPanUpdate: onPanUpdate
                ) {
                    RawImage(
                        image: metalRenderer.createMetalImage(texture: texture)
                    )
                }
            }
            .decoration(
                .box(
                    border: .all(
                        .init(
                            color: .init(0xFF_000000),
                            width: 5,
                            style: .solid
                        )
                    )
                )
            )
        }

        private func onPanUpdate(details: DragUpdateDetails) {
            renderer.updateAngle(
                deltaX: Float(details.delta.dx) * 0.01,
                deltaY: Float(details.delta.dy) * 0.01
            )
            scheduleDraw()
            setState {}
        }

        var hasScheduledDraw = false

        private func scheduleDraw() {
            if hasScheduledDraw {
                return
            }
            _ = SchedulerBinding.shared.scheduleFrameCallback { [self] _ in
                renderer.draw(texture)
                hasScheduledDraw = false
            }
        }
    }

    private enum math {
        static func add(_ a: simd.float3, _ b: simd.float3) -> simd.float3 {
            return simd.float3(a.x + b.x, a.y + b.y, a.z + b.z)
        }

        static func makeIdentity() -> simd_float4x4 {
            return simd_float4x4(
                simd.float4(1.0, 0.0, 0.0, 0.0),
                simd.float4(0.0, 1.0, 0.0, 0.0),
                simd.float4(0.0, 0.0, 1.0, 0.0),
                simd.float4(0.0, 0.0, 0.0, 1.0)
            )
        }

        static func makePerspective(fovRadians: Float, aspect: Float, znear: Float, zfar: Float)
            -> simd_float4x4
        {
            let ys = 1.0 / tanf(fovRadians * 0.5)
            let xs = ys / aspect
            let zs = zfar / (znear - zfar)
            return simd_matrix_from_rows(
                simd.float4(xs, 0.0, 0.0, 0.0),
                simd.float4(0.0, ys, 0.0, 0.0),
                simd.float4(0.0, 0.0, zs, znear * zs),
                simd.float4(0, 0, -1, 0)
            )
        }

        static func makeXRotate(_ angleRadians: Float) -> simd_float4x4 {
            let a = angleRadians
            return simd_matrix_from_rows(
                simd.float4(1.0, 0.0, 0.0, 0.0),
                simd.float4(0.0, cosf(a), sinf(a), 0.0),
                simd.float4(0.0, -sinf(a), cosf(a), 0.0),
                simd.float4(0.0, 0.0, 0.0, 1.0)
            )
        }

        static func makeYRotate(_ angleRadians: Float) -> simd_float4x4 {
            let a = angleRadians
            return simd_matrix_from_rows(
                simd.float4(cosf(a), 0.0, sinf(a), 0.0),
                simd.float4(0.0, 1.0, 0.0, 0.0),
                simd.float4(-sinf(a), 0.0, cosf(a), 0.0),
                simd.float4(0.0, 0.0, 0.0, 1.0)
            )
        }

        static func makeZRotate(_ angleRadians: Float) -> simd_float4x4 {
            let a = angleRadians
            return simd_matrix_from_rows(
                simd.float4(cosf(a), sinf(a), 0.0, 0.0),
                simd.float4(-sinf(a), cosf(a), 0.0, 0.0),
                simd.float4(0.0, 0.0, 1.0, 0.0),
                simd.float4(0.0, 0.0, 0.0, 1.0)
            )
        }

        static func makeTranslate(_ v: simd.float3) -> simd_float4x4 {
            let col0 = simd.float4(1.0, 0.0, 0.0, 0.0)
            let col1 = simd.float4(0.0, 1.0, 0.0, 0.0)
            let col2 = simd.float4(0.0, 0.0, 1.0, 0.0)
            let col3 = simd.float4(v.x, v.y, v.z, 1.0)
            return simd_matrix(col0, col1, col2, col3)
        }

        static func makeScale(_ v: simd.float3) -> simd_float4x4 {
            return simd_matrix(
                simd.float4(v.x, 0, 0, 0),
                simd.float4(0, v.y, 0, 0),
                simd.float4(0, 0, v.z, 0),
                simd.float4(0, 0, 0, 1.0)
            )
        }

        static func discardTranslation(_ m: simd_float4x4) -> simd_float3x3 {
            return simd_float3x3(
                simd_float3(m.columns.0.x, m.columns.0.y, m.columns.0.z),
                simd_float3(m.columns.1.x, m.columns.1.y, m.columns.1.z),
                simd_float3(m.columns.2.x, m.columns.2.y, m.columns.2.z)
            )
        }
    }

    private class CubeRenderer {
        init(device: MTLDevice, commandQueue: MTLCommandQueue) {
            self.device = device
            self.commandQueue = commandQueue
            self.angleX = 0.0
            self.angleY = 0.0
            self.frame = 0

            buildShaders()
            buildDepthStencilStates()
            buildTextures()
            buildBuffers()
        }

        let device: MTLDevice
        let commandQueue: MTLCommandQueue

        private var shaderLibrary: MTLLibrary!
        private var renderPipelineState: MTLRenderPipelineState!
        private var depthStencilState: MTLDepthStencilState!
        private var texture: MTLTexture!
        private var vertexDataBuffer: MTLBuffer!
        private var instanceDataBuffer: [MTLBuffer] = []
        private var cameraDataBuffer: [MTLBuffer] = []
        private var indexBuffer: MTLBuffer!

        private var angleX: Float
        private var angleY: Float
        private var frame: Int

        static let kMaxFramesInFlight = 3
        static let kInstanceRows: Int = 10
        static let kInstanceColumns: Int = 10
        static let kInstanceDepth: Int = 10
        static let kNumInstances: Int = (kInstanceRows * kInstanceColumns * kInstanceDepth)

        enum ShaderTypes {
            struct VertexData {
                var position: simd.float3
                var normal: simd.float3
                var texcoord: simd.float2
            }

            struct InstanceData {
                var instanceTransform: simd_float4x4
                var instanceNormalTransform: simd_float3x3
                var instanceColor: simd_float4
            }

            struct CameraData {
                var perspectiveTransform: simd_float4x4
                var worldTransform: simd_float4x4
                var worldNormalTransform: simd_float3x3
            }
        }

        private func buildShaders() {
            let shaderSrc = """
                #include <metal_stdlib>
                using namespace metal;

                struct v2f
                {
                    float4 position [[position]];
                    float3 normal;
                    half3 color;
                    float2 texcoord;
                };

                struct VertexData
                {
                    float3 position;
                    float3 normal;
                    float2 texcoord;
                };

                struct InstanceData
                {
                    float4x4 instanceTransform;
                    float3x3 instanceNormalTransform;
                    float4 instanceColor;
                };

                struct CameraData
                {
                    float4x4 perspectiveTransform;
                    float4x4 worldTransform;
                    float3x3 worldNormalTransform;
                };

                v2f vertex vertexMain( device const VertexData* vertexData [[buffer(0)]],
                                       device const InstanceData* instanceData [[buffer(1)]],
                                       device const CameraData& cameraData [[buffer(2)]],
                                       uint vertexId [[vertex_id]],
                                       uint instanceId [[instance_id]] )
                {
                    v2f o;

                    const device VertexData& vd = vertexData[ vertexId ];
                    float4 pos = float4( vd.position, 1.0 );
                    pos = instanceData[ instanceId ].instanceTransform * pos;
                    pos = cameraData.perspectiveTransform * cameraData.worldTransform * pos;
                    o.position = pos;

                    float3 normal = instanceData[ instanceId ].instanceNormalTransform * vd.normal;
                    normal = cameraData.worldNormalTransform * normal;
                    o.normal = normal;

                    o.texcoord = vd.texcoord.xy;

                    o.color = half3( instanceData[ instanceId ].instanceColor.rgb );
                    return o;
                }

                half4 fragment fragmentMain( v2f in [[stage_in]], texture2d< half, access::sample > tex [[texture(0)]] )
                {
                    constexpr sampler s( address::repeat, filter::linear );
                    half3 texel = tex.sample( s, in.texcoord ).rgb;

                    // assume light coming from (front-top-right)
                    float3 l = normalize(float3( 1.0, 1.0, 0.8 ));
                    float3 n = normalize( in.normal );

                    half ndotl = half( saturate( dot( n, l ) ) );

                    half3 illum = (in.color * texel * 0.1) + (in.color * texel * ndotl);
                    return half4( illum, 1.0 );
                }
                """

            let library = try! device.makeLibrary(source: shaderSrc, options: nil)

            let vertexFn = library.makeFunction(name: "vertexMain")
            let fragFn = library.makeFunction(name: "fragmentMain")

            let renderPipeline = MTLRenderPipelineDescriptor()
            renderPipeline.vertexFunction = vertexFn
            renderPipeline.fragmentFunction = fragFn
            renderPipeline.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
            renderPipeline.depthAttachmentPixelFormat = .depth16Unorm

            renderPipelineState = try! device.makeRenderPipelineState(descriptor: renderPipeline)
            shaderLibrary = library
        }

        private func buildDepthStencilStates() {
            let stencil = MTLDepthStencilDescriptor()
            stencil.depthCompareFunction = .less
            stencil.isDepthWriteEnabled = true

            depthStencilState = device.makeDepthStencilState(descriptor: stencil)!
        }

        private func buildTextures() {
            let tw: UInt32 = 128
            let th: UInt32 = 128

            let textureDescriptor = MTLTextureDescriptor()
            textureDescriptor.width = Int(tw)
            textureDescriptor.height = Int(th)
            textureDescriptor.pixelFormat = .rgba8Unorm
            textureDescriptor.textureType = .type2D
            textureDescriptor.storageMode = .managed
            textureDescriptor.usage = [.shaderRead, .shaderWrite]

            let texture = device.makeTexture(descriptor: textureDescriptor)!
            self.texture = texture

            var textureData = [UInt8](repeating: 0, count: Int(tw * th * 4))
            for y in 0..<th {
                for x in 0..<tw {
                    let isWhite = (Int(x) ^ Int(y)) & 0b1000000 != 0
                    let c: UInt8 = isWhite ? 0xFF : 0x0A

                    let i = Int(y * tw + x)

                    textureData[i * 4 + 0] = c
                    textureData[i * 4 + 1] = c
                    textureData[i * 4 + 2] = c
                    textureData[i * 4 + 3] = 0xFF
                }
            }

            texture.replace(
                region: MTLRegion(
                    origin: MTLOrigin(x: 0, y: 0, z: 0),
                    size: MTLSize(width: Int(tw), height: Int(th), depth: 1)
                ),
                mipmapLevel: 0,
                withBytes: textureData,
                bytesPerRow: Int(tw * 4)
            )
        }

        private func buildBuffers() {
            let s: Float = 0.5

            let verts: [ShaderTypes.VertexData] = [
                //                                         Texture
                //   Positions           Normals         Coordinates
                .init(position: [-s, -s, +s], normal: [0.0, 0.0, 1.0], texcoord: [0.0, 1.0]),
                .init(position: [+s, -s, +s], normal: [0.0, 0.0, 1.0], texcoord: [1.0, 1.0]),
                .init(position: [+s, +s, +s], normal: [0.0, 0.0, 1.0], texcoord: [1.0, 0.0]),
                .init(position: [-s, +s, +s], normal: [0.0, 0.0, 1.0], texcoord: [0.0, 0.0]),

                .init(position: [+s, -s, +s], normal: [1.0, 0.0, 0.0], texcoord: [0.0, 1.0]),
                .init(position: [+s, -s, -s], normal: [1.0, 0.0, 0.0], texcoord: [1.0, 1.0]),
                .init(position: [+s, +s, -s], normal: [1.0, 0.0, 0.0], texcoord: [1.0, 0.0]),
                .init(position: [+s, +s, +s], normal: [1.0, 0.0, 0.0], texcoord: [0.0, 0.0]),

                .init(position: [+s, -s, -s], normal: [0.0, 0.0, -1.0], texcoord: [0.0, 1.0]),
                .init(position: [-s, -s, -s], normal: [0.0, 0.0, -1.0], texcoord: [1.0, 1.0]),
                .init(position: [-s, +s, -s], normal: [0.0, 0.0, -1.0], texcoord: [1.0, 0.0]),
                .init(position: [+s, +s, -s], normal: [0.0, 0.0, -1.0], texcoord: [0.0, 0.0]),

                .init(position: [-s, -s, -s], normal: [-1.0, 0.0, 0.0], texcoord: [0.0, 1.0]),
                .init(position: [-s, -s, +s], normal: [-1.0, 0.0, 0.0], texcoord: [1.0, 1.0]),
                .init(position: [-s, +s, +s], normal: [-1.0, 0.0, 0.0], texcoord: [1.0, 0.0]),
                .init(position: [-s, +s, -s], normal: [-1.0, 0.0, 0.0], texcoord: [0.0, 0.0]),

                .init(position: [-s, +s, +s], normal: [0.0, 1.0, 0.0], texcoord: [0.0, 1.0]),
                .init(position: [+s, +s, +s], normal: [0.0, 1.0, 0.0], texcoord: [1.0, 1.0]),
                .init(position: [+s, +s, -s], normal: [0.0, 1.0, 0.0], texcoord: [1.0, 0.0]),
                .init(position: [-s, +s, -s], normal: [0.0, 1.0, 0.0], texcoord: [0.0, 0.0]),

                .init(position: [-s, -s, -s], normal: [0.0, -1.0, 0.0], texcoord: [0.0, 1.0]),
                .init(position: [+s, -s, -s], normal: [0.0, -1.0, 0.0], texcoord: [1.0, 1.0]),
                .init(position: [+s, -s, +s], normal: [0.0, -1.0, 0.0], texcoord: [1.0, 0.0]),
                .init(position: [-s, -s, +s], normal: [0.0, -1.0, 0.0], texcoord: [0.0, 0.0]),
            ]

            let indices: [UInt16] = [
                0, 1, 2, 2, 3, 0, /* front */
                4, 5, 6, 6, 7, 4, /* right */
                8, 9, 10, 10, 11, 8, /* back */
                12, 13, 14, 14, 15, 12, /* left */
                16, 17, 18, 18, 19, 16, /* top */
                20, 21, 22, 22, 23, 20 /* bottom */,
            ]

            let vertexDataSize = MemoryLayout<ShaderTypes.VertexData>.stride * verts.count
            let indexDataSize = MemoryLayout<UInt16>.stride * indices.count

            vertexDataBuffer = device.makeBuffer(
                bytes: verts,
                length: vertexDataSize,
                options: .storageModeManaged
            )!
            indexBuffer = device.makeBuffer(
                bytes: indices,
                length: indexDataSize,
                options: .storageModeManaged
            )!

            let instanceDataSize =
                Self.kMaxFramesInFlight * Self.kNumInstances
                * MemoryLayout<ShaderTypes.InstanceData>.stride
            for _ in 0..<Self.kMaxFramesInFlight {
                instanceDataBuffer.append(
                    device.makeBuffer(
                        length: instanceDataSize,
                        options: .storageModeManaged
                    )!
                )
            }

            let cameraDataSize =
                Self.kMaxFramesInFlight * MemoryLayout<ShaderTypes.CameraData>.stride
            for _ in 0..<Self.kMaxFramesInFlight {
                cameraDataBuffer.append(
                    device.makeBuffer(
                        length: cameraDataSize,
                        options: .storageModeManaged
                    )!
                )
            }
        }

        public func updateAngle(deltaX: Float, deltaY: Float) {
            angleX += deltaX
            angleY += deltaY
        }

        public func draw(_ renderTarget: MTLTexture) {
            let instanceDataBuffer = instanceDataBuffer[frame]

            let commandBuffer = commandQueue.makeCommandBuffer()!

            let scl: Float = 0.2
            let instanceData = instanceDataBuffer.contents().assumingMemoryBound(
                to: ShaderTypes.InstanceData.self
            )

            let objectPosition = simd.float3(0.0, 0.0, -10.0)

            let rt = math.makeTranslate(objectPosition)
            let rr1 = math.makeYRotate(angleX)
            let rr0 = math.makeXRotate(-angleY)
            let rtInv = math.makeTranslate(
                simd.float3(-objectPosition.x, -objectPosition.y, -objectPosition.z)
            )
            let fullObjectRot = rt * rr1 * rr0 * rtInv

            var ix: Int = 0
            var iy: Int = 0
            var iz: Int = 0
            for i in 0..<Self.kNumInstances {
                if ix == Self.kInstanceRows {
                    ix = 0
                    iy += 1
                }
                if iy == Self.kInstanceRows {
                    iy = 0
                    iz += 1
                }

                let scale = math.makeScale(simd.float3(scl, scl, scl))
                let zrot = math.makeZRotate(angleY * sin(Float(ix)))
                let yrot = math.makeYRotate(angleX * cos(Float(iy)))

                let x = (Float(ix) - Float(Self.kInstanceRows) / 2.0) * (2.0 * scl) + scl
                let y = (Float(iy) - Float(Self.kInstanceColumns) / 2.0) * (2.0 * scl) + scl
                let z = (Float(iz) - Float(Self.kInstanceDepth) / 2.0) * (2.0 * scl)
                let translate = math.makeTranslate(math.add(objectPosition, simd.float3(x, y, z)))

                instanceData[i].instanceTransform = fullObjectRot * translate * yrot * zrot * scale
                instanceData[i].instanceNormalTransform = math.discardTranslation(
                    instanceData[i].instanceTransform
                )

                let iDivNumInstances = Float(i) / Float(Self.kNumInstances)
                let r = iDivNumInstances
                let g = 1.0 - r
                let b = sin(.pi * 2.0 * iDivNumInstances)
                instanceData[i].instanceColor = simd.float4(r, g, b, 1.0)

                ix += 1
            }
            instanceDataBuffer.didModifyRange(0..<instanceDataBuffer.length)

            // Update camera state:

            let cameraDataBuffer = cameraDataBuffer[frame]
            let cameraData = cameraDataBuffer.contents().assumingMemoryBound(
                to: ShaderTypes.CameraData.self
            )
            cameraData.pointee.perspectiveTransform = math.makePerspective(
                fovRadians: 45.0 * .pi / 180.0,
                aspect: 1.0,
                znear: 0.03,
                zfar: 500.0
            )
            cameraData.pointee.worldTransform = math.makeIdentity()
            cameraData.pointee.worldNormalTransform = math.discardTranslation(
                cameraData.pointee.worldTransform
            )
            cameraDataBuffer.didModifyRange(0..<MemoryLayout<ShaderTypes.CameraData>.size)

            // Begin render pass:

            let renderPass = MTLRenderPassDescriptor()
            renderPass.colorAttachments[0].texture = renderTarget
            renderPass.colorAttachments[0].loadAction = .clear
            renderPass.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0)

            let encoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPass
            )!

            encoder.setRenderPipelineState(renderPipelineState)
            encoder.setDepthStencilState(depthStencilState)

            encoder.setVertexBuffer(vertexDataBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(instanceDataBuffer, offset: 0, index: 1)
            encoder.setVertexBuffer(cameraDataBuffer, offset: 0, index: 2)

            encoder.setFragmentTexture(texture, index: 0)

            encoder.setCullMode(.back)
            encoder.setFrontFacing(.counterClockwise)

            encoder.drawIndexedPrimitives(
                type: .triangle,
                indexCount: 6 * 6,
                indexType: .uint16,
                indexBuffer: indexBuffer,
                indexBufferOffset: 0,
                instanceCount: Self.kNumInstances
            )

            encoder.endEncoding()
            commandBuffer.commit()
        }
    }

// func renderSimple(size: Size) -> Image {
//     let renderer = backend.renderer as! MetalRenderer
//     let device = renderer.device
//     let commandQueue = renderer.queue

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

//     let textureDescriptor = MTLTextureDescriptor()
//     textureDescriptor.width = Int(size.width)
//     textureDescriptor.height = Int(size.height)
//     textureDescriptor.pixelFormat = .bgra8Unorm
//     textureDescriptor.textureType = .type2D
//     textureDescriptor.storageMode = .managed
//     textureDescriptor.usage = [.shaderWrite, .renderTarget]
//     let texture = device.makeTexture(descriptor: textureDescriptor)!

//     let renderPassDescriptor = MTLRenderPassDescriptor()
//     renderPassDescriptor.colorAttachments[0].texture = texture
//     renderPassDescriptor.colorAttachments[0].loadAction = .clear
//     renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.5, 1.0, 1.0)

//     let commandBuffer = commandQueue.makeCommandBuffer()!
//     let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
//     renderEncoder.setRenderPipelineState(pipelineState)
//     renderEncoder.setVertexBuffer(vertexArray, offset: 0, index: 0)
//     renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
//     renderEncoder.endEncoding()

//     commandBuffer.commit()

//     return renderer.createMetalImage(texture: texture)
// }

#endif
