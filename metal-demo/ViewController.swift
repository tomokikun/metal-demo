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
    -1, -1, 0, 1, // 左下
    1, -1, 0, 1, // 右下
    -1, 1, 0, 1, // 左上
    1, 1, 0, 1 // 右上
]

let textureCoordinateData: [Float] = [
    0, 0, // 左下
    1, 0, // 右下
    0, 1, // 左上
    1, 1, // 右上
]

private let indexData: [UInt16] = [
    0, 1, 2,
    2, 3, 1
]

struct Constants {
    var rotateBy: Float = 0.0;
}

private var constants = Constants()
private var time: Float = 0.0


class ViewController: NSViewController, MTKViewDelegate {
    
    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private var renderPipelineState: MTLRenderPipelineState!
    private var computePipelineState: MTLComputePipelineState!
    private var vertexBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    private var textureCoordinateBuffer: MTLBuffer!
    private var texture: MTLTexture!
    private var mtkView: MTKView!
    private let imageName: String = "planet"
    private var threadgroupSize: MTLSize = MTLSize(width:64, height: 64, depth: 1)
    private var w: Int = 0
    private var h: Int = 0
    private var threadgroupCount: MTLSize!
    private var outTexture: MTLTexture!
    
    override func loadView() {
        view = MTKView(frame: NSRect(x: 0, y: 0, width: 810, height: 540), device: device)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        loadTexture(name: imageName)
        mtkView.framebufferOnly = false
        makeBuffers()
        makePipeline(format: texture.pixelFormat)
        setupComputeFunc()
    }
    
    private func setupMetal() {
        mtkView = self.view as? MTKView
        mtkView.device = device
        mtkView.delegate = self
        commandQueue = device.makeCommandQueue()
    }
    
    private func loadTexture(name: String) {
        let textureLoader = MTKTextureLoader(device: device)
        let scaleFactor: CGFloat = 2
        texture = try! textureLoader.newTexture(name: name, scaleFactor: scaleFactor, bundle: nil)
        mtkView.colorPixelFormat = texture.pixelFormat
    }
        
    private func makeBuffers() {
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: MemoryLayout<Float>.size * vertexData.count)
        textureCoordinateBuffer = device.makeBuffer(bytes: textureCoordinateData, length: MemoryLayout<Float>.size * textureCoordinateData.count)
        indexBuffer = device.makeBuffer(bytes: indexData, length: indexData.count * MemoryLayout<UInt16>.size)
    }
    
    private func makePipeline(format: MTLPixelFormat) {
        guard let library = device.makeDefaultLibrary() else { return }
        let function = library.makeFunction(name: "computeShader")!
        computePipelineState = try! device.makeComputePipelineState(function: function)
    }
    
    private func animate() {
        time += 1 / Float(mtkView.preferredFramesPerSecond)
        constants.rotateBy = time
    }
    
    private func setupComputeFunc() {
        w = threadgroupSize.width
        h = threadgroupSize.height
        threadgroupCount = MTLSize(
            width: (texture.width + w - 1) / w,
            height: (texture.height + h - 1) / h,
            depth: 1
        )
    }
    
    private func saveImage(commandBuffer: MTLCommandBuffer) {

        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        blitEncoder.synchronize(resource: outTexture)
        blitEncoder.endEncoding()
        commandBuffer.waitUntilCompleted()
        
        // texture to image
        
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
    
    func draw(in view: MTKView) {
        autoreleasepool {
            render(to: view)
        }
    }
    
    func render(to view: MTKView) {
        guard let drawable = view.currentDrawable else { return }
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        let descriptor: MTLTextureDescriptor = .texture2DDescriptor(pixelFormat: .bgra8Unorm, width: texture.width, height: texture.height, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite]
        descriptor.storageMode = .managed
        outTexture = device.makeTexture(descriptor: descriptor)!
        
        let encoder = commandBuffer.makeComputeCommandEncoder()!
        encoder.setComputePipelineState(computePipelineState)
        encoder.setTexture(texture, index: 0)
        encoder.setTexture(outTexture, index: 1)

        encoder.dispatchThreadgroups(threadgroupSize, threadsPerThreadgroup: threadgroupCount)
        encoder.endEncoding()
        commandBuffer.addCompletedHandler(saveImage)
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
