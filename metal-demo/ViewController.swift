//
//  ViewController.swift
//  metal-demo
//
//  Created by 前川　知紀 on 2020/06/10.
//  Copyright © 2020 前川　知紀. All rights reserved.
//

import Cocoa
import MetalKit


class ViewController: NSViewController {

    private let positionData: [Float] = [
        0.3, 0.3, 0.0, 1.0,
        0.3, -0.3, 0.0, 1.0,
        -0.3, -0.3, 0.0, 1.0,
        -0.3, 0.3, 0.0, 1.0,
        ]

    private let colorData: [Float] = [
        1, 0, 0, 1,
        0, 1, 0, 1,
        0, 0, 1, 1,
        1, 0, 1, 1,
    ]
    
    private let indexData: [UInt16] = [
        0, 1, 2,
        2, 3, 0
    ]
    
    struct Constants {
        var animateXBy: Float = 0.0
        var animateYBy: Float = 0.0
    }
    private var constants = Constants()
    private var time: Float = 0.0
    
    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private var renderPassDescriptor: MTLRenderPassDescriptor!
    private var bufferPosition: MTLBuffer!
    private var bufferColor: MTLBuffer!
    private var bufferIndex: MTLBuffer!
    private var renderPipelineState: MTLRenderPipelineState!
    private var metalLayer: CAMetalLayer!;
    private var library: MTLLibrary!

    override func loadView() {
        view = MTKView(frame: NSRect(x: 0, y: 0, width: 960, height: 540))
//        view.layer = CAMetalLayer()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let view = self.view as! MTKView
        
        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.delegate = self
        library = device.makeDefaultLibrary()

        // setup
        commandQueue = device.makeCommandQueue()
        renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.1, 0.2, 1.0)
        
        // create buffer
        let size = positionData.count * MemoryLayout<Float>.size
        bufferPosition = device.makeBuffer(bytes: positionData, length: size)
        bufferColor = device.makeBuffer(bytes: colorData, length: size)
        bufferIndex = device.makeBuffer(bytes: indexData, length: indexData.count * MemoryLayout<UInt16>.size)
        }
}

extension ViewController: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    func draw(in view: MTKView) {
        autoreleasepool {
            render(to: view)
        }
    }
    
    func render(to view: MTKView) {
        guard let library = device.makeDefaultLibrary() else {fatalError()}
        
        // Make renderPipelineState only once because it's heavy proces
        if (renderPipelineState == nil) {
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "myVertexShader")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "myFragmentShader")
            pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            renderPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        
        time += 1 / Float(view.preferredFramesPerSecond)  // default value: 60?
        constants.animateXBy = cos(time) / 4
        constants.animateYBy = sin(time) / 4
        
        // draw
        guard let drawable = view.currentDrawable else { return }
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        let encoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor
        )!
        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setVertexBuffer(bufferPosition, offset: 0, index: 0)
        encoder.setVertexBuffer(bufferColor, offset: 0, index:1)
        encoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 2)
        
        encoder.drawIndexedPrimitives(type: .triangle,
                               indexCount: indexData.count,
                               indexType: .uint16,
                               indexBuffer: bufferIndex,
                               indexBufferOffset: 0)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
