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
        guard let drawable = view.currentDrawable else { return }
        do {
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 1.0, 1.0)

            let renderCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
            renderCommandEncoder.setRenderPipelineState(pipelineState)
            
            renderCommandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderCommandEncoder.setVertexBuffer(textureCoorBuffer, offset: 0, index: 1)

            renderCommandEncoder.setFragmentTexture(inTexture, index: 0)
            renderCommandEncoder.drawIndexedPrimitives(type: .triangleStrip, indexCount: indexData.count, indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
            renderCommandEncoder.endEncoding()
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
    }
    
    private func loadTexture(name: String) {
        let textureLoader = MTKTextureLoader(device: device)
        let scaleFactor: CGFloat = 2
        inTexture = try! textureLoader.newTexture(name: name, scaleFactor: scaleFactor, bundle: nil)
        //        mtkView.colorPixelFormat = texture.pixelFormat
    }
}


