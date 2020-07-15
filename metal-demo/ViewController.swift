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
    0, 0,
    1, 0,
    0, 1,
    1, 1,
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
    private var posBuffer: MTLBuffer!
    private var texture: MTLTexture!
    private var mtkView: MTKView!
    private let imageName: String = "image"
    private var threadgroupSize: MTLSize = MTLSize(width: 256, height: 256, depth: 1)
    private var width: Int = 810
    private var height: Int = 540
    private var threadgroupCount: MTLSize!
    private var outTexture: MTLTexture!
    private var sampler: MTLSamplerState!
    private var count: Int = 0
    private var queue: DispatchQueue!
    private var outTextures: [MTLTexture] = []
    private var offscreen: MTLTexture!
    
    override func loadView() {
        view = MTKView(frame: NSRect(x: 0, y: 0, width: width, height: height), device: device)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        loadTexture(name: imageName)
        mtkView.framebufferOnly = false
        makeBuffers()
        makePipeline(format: texture.pixelFormat)
        makeSampler()
        setupComputeFunc()
        createDir("output")
        queue = DispatchQueue.global(qos: .userInteractive)
    }
    
    private func createDir(_ dirpath: String) {
        let fileManager = FileManager.default
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = URL(fileURLWithPath: path + "/" + dirpath)
        if !fileManager.fileExists(atPath: dirpath) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("fail to create dir: \(dirpath)")
            }
        }
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
        posBuffer = device.makeBuffer(length: texture.width * texture.height, options: .storageModeShared)
    }
    
    private func makePipeline(format: MTLPixelFormat) {
        
        guard let library = device.makeDefaultLibrary() else { return }
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = format
        renderPipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        let function = library.makeFunction(name: "computeShader")!
        computePipelineState = try! device.makeComputePipelineState(function: function)
    }
    
    private func animate() {
        time += 1 / Float(mtkView.preferredFramesPerSecond)
        constants.rotateBy = time
    }
    
    private func setupComputeFunc() {
        let w = threadgroupSize.width
        let h = threadgroupSize.height
        threadgroupCount = MTLSize(
            width: (texture.width + w - 1) / w,
            height: (texture.height + h - 1) / h,
            depth: 1
        )
    }
    
    private func saveImage(_commandBuffer: MTLCommandBuffer) {
        
        guard let tex: MTLTexture = outTextures.popLast() else { return }
        queue.async{
            let commandBuffer: MTLCommandBuffer = _commandBuffer.commandQueue.makeCommandBuffer()!
            let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
            blitEncoder.synchronize(resource: tex)
            blitEncoder.endEncoding()
            commandBuffer.addCompletedHandler({_ in
                self.saveImage(tex)
            })
            commandBuffer.commit()
        }
    }
    
    private func saveImage(_ tex: MTLTexture) {
        autoreleasepool(invoking: {
            guard let outImage = CIImage(mtlTexture: tex, options: nil),
                    let jpgData = CIContext().jpegRepresentation(of: outImage, colorSpace: outImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(), options: [:]) else { return }
            
                do {
                    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
                    let filename = NSString(format: "/output/%05d.jpg", count) as String
                    defer {
                        count += 1
                    }
                    let url: URL = URL(fileURLWithPath: path+filename)
                    try jpgData.write(to: url)
                } catch {
                    print("fail to save image.")
                }
        })
    }
    
    private func makeSampler() {
        let samplerDescriptor: MTLSamplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .nearest
        sampler = device.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }
    
    func draw(in view: MTKView) {
        autoreleasepool {
            render(to: view)
        }
    }
    
    func render(to view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        // offscreen
        do {
            let offscreenDescriptor: MTLTextureDescriptor = .texture2DDescriptor(pixelFormat: texture.pixelFormat, width: width, height: height, mipmapped: false)
            offscreenDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
            offscreen = device.makeTexture(descriptor: offscreenDescriptor)

            let offscreenRenderPassDescriptor: MTLRenderPassDescriptor = MTLRenderPassDescriptor()
            offscreenRenderPassDescriptor.colorAttachments[0].texture = offscreen
            offscreenRenderPassDescriptor.colorAttachments[0].loadAction = .clear
            offscreenRenderPassDescriptor.colorAttachments[0].storeAction = .store
            offscreenRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 0.0, 1.0, 1.0)

            let offscreenRenderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: offscreenRenderPassDescriptor)!
            offscreenRenderEncoder.setRenderPipelineState(renderPipelineState)
            offscreenRenderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            offscreenRenderEncoder.setVertexBuffer(textureCoordinateBuffer, offset: 0, index: 1)
            offscreenRenderEncoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 2)
            offscreenRenderEncoder.setFragmentTexture(texture, index: 0)
            offscreenRenderEncoder.setFragmentBuffer(posBuffer, offset: 0, index: 0)
            offscreenRenderEncoder.setFragmentSamplerState(sampler, index: 0)
            offscreenRenderEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexData.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
            offscreenRenderEncoder.endEncoding()
        }

        // display
        guard let drawable = view.currentDrawable else { return }
        do {
                guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
                renderPassDescriptor.colorAttachments[0].texture = drawable.texture
                renderPassDescriptor.colorAttachments[0].loadAction = .clear
                renderPassDescriptor.colorAttachments[0].storeAction = .store
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 1.0, 1.0)

                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
                renderEncoder.setRenderPipelineState(renderPipelineState)
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                renderEncoder.setVertexBuffer(textureCoordinateBuffer, offset: 0, index: 1)
                renderEncoder.setVertexBytes(&constants, length: MemoryLayout<Constants>.stride, index: 2)

                renderEncoder.setFragmentTexture(texture, index: 0)
                renderEncoder.setFragmentBuffer(posBuffer, offset: 0, index: 0)
                renderEncoder.setFragmentSamplerState(sampler, index: 0)
                renderEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexData.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
                renderEncoder.endEncoding()
        }
        
        do {
            let descriptor: MTLTextureDescriptor = .texture2DDescriptor(pixelFormat: offscreen.pixelFormat, width: offscreen.width, height: offscreen.height, mipmapped: false)
            descriptor.usage = [.shaderRead, .shaderWrite]
            descriptor.storageMode = .managed
            outTextures.insert(device.makeTexture(descriptor: descriptor)!, at: 0)
            let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
            computeEncoder.setComputePipelineState(computePipelineState)
            computeEncoder.setTexture(offscreen, index: 0)
            computeEncoder.setTexture(outTextures[0], index: 1)
            computeEncoder.dispatchThreadgroups(threadgroupSize, threadsPerThreadgroup: threadgroupCount)
            computeEncoder.endEncoding()
        }
        commandBuffer.addCompletedHandler(saveImage)
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        animate()
    }
}
