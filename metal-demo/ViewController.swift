//
//  ViewController.swift
//  metal-demo
//
//  Created by 前川　知紀 on 2020/06/10.
//  Copyright © 2020 前川　知紀. All rights reserved.
//

import Cocoa
import MetalKit
import simd


let vertexData: [Float] = [
    -1, -1, 0, 1,
    1, -1, -1, 1,
    -1, 1, 0, 1,
    1, 1, 0, 1
]

let textureCoordinateData: [Float] = [
    0, 1,
    1, 1,
    0, 0,
    1, 0
]

class ViewController: NSViewController, MTKViewDelegate {
    
    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private let renderPassDescriptor = MTLRenderPassDescriptor()
    private var renderPipelineState: MTLRenderPipelineState!
    private var vertexBuffer: MTLBuffer!
    private var textureCoordinateBuffer: MTLBuffer!
    private var texture: MTLTexture!
    private var mView: MTKView!
    private let imageName: String = "planet"
    
    override func loadView() {
        view = MTKView(frame: NSRect(x: 0, y: 0, width: 1920, height: 1080), device: device)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        loadTexture(name: imageName)
//        mView.enableSetNeedsDisplay = true
//        mView.framebufferOnly = false
        makeBuffers()
        makePipeline(format: texture.pixelFormat)
//        view.setNeedsDisplay(NSRect(x: 0, y: 0, width: 960, height: 540))
    }
    
    private func setupMetal() {
        mView = self.view as? MTKView
        mView.device = device
        mView.delegate = self
//        mView.drawableSize = CGSize(width: 1920, height: 1080)
        commandQueue = device.makeCommandQueue()
//        renderPassDescriptor.colorAttachments[0].loadAction = .clear
//        renderPassDescriptor.colorAttachments[0].storeAction = .store
//        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 1.0, 1.0)
    }
    
    private func loadTexture(name: String) {
        let textureLoader = MTKTextureLoader(device: device)
        let scaleFactor: CGFloat = 2
        texture = try! textureLoader.newTexture(name: name, scaleFactor: scaleFactor, bundle: nil)
        mView.colorPixelFormat = texture.pixelFormat
    }
    
    private func makeBuffers() {
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: MemoryLayout<Float>.size * vertexData.count)
        textureCoordinateBuffer = device.makeBuffer(bytes: textureCoordinateData, length: MemoryLayout<Float>.size * textureCoordinateData.count)
        
    }
    
    private func makePipeline(format: MTLPixelFormat) {
        guard let library = device.makeDefaultLibrary() else { return }
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = format
        renderPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
    
    func draw(in view: MTKView) {
        autoreleasepool {
            render(to: view)
        }
    }
    
    func render(to view: MTKView) {
//        print(drawable.texture.width, drawable.texture.height)
//        print(view.drawableSize)
        guard let drawable = view.currentDrawable else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        
        guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
    
        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(textureCoordinateBuffer, offset: 0, index: 1)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
