//
//  ViewController.swift
//  FilteringWithMetal
//
//  Created by 前川　知紀 on 2020/07/22.
//  Copyright © 2020 Maekawa Tomoki. All rights reserved.
//

import Cocoa
import MetalKit

private let vertexData: [Float] = [
    -1, -1, 0, 1,
    1, -1, 0, 1,
    -1, 1, 0, 1,
    1, 1, 0, 1,
]

private let textureCoorData: [Float] = [
    0, 0,
    1, 0,
    0, 1,
    1, 1,
]

private let indexData: [UInt16] = [
    0, 1, 2,
    2, 3, 1,
]

private let weights: [Float] = [
    1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0,
    1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0,
    1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0,
    1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0,
    1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0, 1.0 / 25.0,
]

class ViewController: NSViewController, MTKViewDelegate {
    
    private let width: Int = 800
    private let height: Int = 500
    private let name: String = "High Sierra"
    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private var mtkView: MTKView!
    private var vertexBuffer: MTLBuffer!
    private var textureCoorBuffer: MTLBuffer!
    private var indexBuffer: MTLBuffer!
    private var pipelineState: MTLRenderPipelineState!
    private var computePipelineState: MTLComputePipelineState!
    private var inTexture: MTLTexture!
    private var outTexture: MTLTexture!
    private var weightsBuffer: MTLBuffer!
    
    override func loadView() {
        view = MTKView(frame: NSRect(x: 0, y: 0, width: width, height: height), device: device)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        makeBuffers()
        makePipeline()
        makeComputePipelineState()
        loadTexture(name: name)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        autoreleasepool {
            render(to: view)
        }
    }
    
    private func setupMetal() {
        mtkView = self.view as? MTKView
        mtkView.device = device
        mtkView.delegate = self
        commandQueue = device.makeCommandQueue()
    }
    
    private func makeBuffers() {
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: MemoryLayout<Float>.size * vertexData.count)
        textureCoorBuffer = device.makeBuffer(bytes: textureCoorData, length: MemoryLayout<Float>.size * textureCoorData.count)
        indexBuffer = device.makeBuffer(bytes: indexData, length: MemoryLayout<UInt16>.size * indexData.count)
        weightsBuffer = device.makeBuffer(bytes: weights, length: MemoryLayout<Float>.size * weights.count)
    }
    
    private func makePipeline() {
        guard let library = device.makeDefaultLibrary() else { return }
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func makeComputePipelineState() {
        guard let library = device.makeDefaultLibrary() else { return }
        guard let function = library.makeFunction(name: "blur5x5") else { return }
        do {
            computePipelineState = try device.makeComputePipelineState(function: function)
        } catch let error {
            print(error)
            fatalError()
        }
    }
    
    private func render(to view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        
        // compute
        do {
            let encoder = commandBuffer.makeComputeCommandEncoder()
            encoder?.setComputePipelineState(computePipelineState)
            encoder?.setBuffer(weightsBuffer, offset: 0, index: 0)
            
            let threadgroupSize = MTLSize(width: 256, height: 256, depth: 1)
            let threadgroupCount = MTLSize(width: (inTexture.width + threadgroupSize.width - 1) / threadgroupSize.width, height: (inTexture.height + threadgroupSize.height - 1) / threadgroupSize.height, depth: 1)
            
            
            let descriptor: MTLTextureDescriptor = .texture2DDescriptor(pixelFormat: inTexture.pixelFormat, width: inTexture.width, height: inTexture.height, mipmapped: false)
            descriptor.usage = [.shaderRead, .shaderWrite]
            descriptor.storageMode = .managed
            outTexture = device.makeTexture(descriptor: descriptor)!
            encoder!.setTexture(inTexture, index: 0)
            encoder!.setTexture(outTexture, index: 1)
            encoder!.dispatchThreadgroups(threadgroupSize, threadsPerThreadgroup: threadgroupCount)
            encoder!.endEncoding()
        }
                
//        guard let drawable = view.currentDrawable else { return }
//        do {
//            guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
//            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
//            renderPassDescriptor.colorAttachments[0].loadAction = .clear
//            renderPassDescriptor.colorAttachments[0].storeAction = .store
//            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 1.0, 1.0)
//
//            let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
//            renderCommandEncoder.setRenderPipelineState(pipelineState)
//            renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//            renderCommandEncoder.setVertexBuffer(textureCoorBuffer, offset: 0, index: 1)
//
//            renderCommandEncoder.setFragmentTexture(outTexture, index: 0)
//            renderCommandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexData.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
//            renderCommandEncoder.endEncoding()
//        }
        commandBuffer.addCompletedHandler(saveImage)
//        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
    }
    
    private func loadTexture(name: String) {
        let textureLoader = MTKTextureLoader(device: device)
        let scaleFactor: CGFloat = 2
        inTexture = try! textureLoader.newTexture(name: name, scaleFactor: scaleFactor, bundle: nil)
        //        mtkView.colorPixelFormat = texture.pixelFormat
    }
    
    
    private func saveImage(_commandBuffer: MTLCommandBuffer) {
        
        guard let tex: MTLTexture = outTexture else { return }
        DispatchQueue.main.async{
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
            var count = 1
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
            } catch let err {
                print(err)
                print("fail to save image.")
            }
        })
    }
}


