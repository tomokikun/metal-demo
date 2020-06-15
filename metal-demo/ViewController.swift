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

class ViewController: NSViewController, MTKViewDelegate {
    
    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private var renderPassDescriptor: MTLRenderPassDescriptor!
    private var renderPipelineState: MTLRenderPipelineState!
    private var texture: MTLTexture!
    private var mView: MTKView!
    private let imageName: String = "planet"
    
    override func loadView() {
        view = MTKView(frame: NSRect(x: 0, y: 0, width: 960, height: 540))
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        loadTexture(name: imageName)
        mView.enableSetNeedsDisplay = true
        mView.framebufferOnly = false
    }
    
    private func setupMetal() {
        mView = self.view as? MTKView
        mView.device = device
        mView.colorPixelFormat = .bgra8Unorm
        mView.delegate = self
        commandQueue = device.makeCommandQueue()
        renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.1, 0.2, 1.0)
    }
    
    private func loadTexture(name: String) {
        let textureLoader = MTKTextureLoader(device: device)
        texture = try! textureLoader.newTexture(name: name, scaleFactor: 1, bundle: nil)
        mView.colorPixelFormat = texture.pixelFormat
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
        
        let w = min(texture.width, drawable.texture.width)
        let h = min(texture.height, drawable.texture.height)
        
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        blitEncoder.copy(from: texture,
                         sourceSlice: 0,
                         sourceLevel: 0,
                         sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                         sourceSize: MTLSizeMake(w, h, texture.depth),
                         to: drawable.texture,
                         destinationSlice: 0,
                         destinationLevel: 0,
                         destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        blitEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
