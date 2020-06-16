//
//  Shader.metal
//  metal-demo
//
//  Created by 前川　知紀 on 2020/06/10.
//  Copyright © 2020 前川　知紀. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MyVertex {
    float4 position [[position]];
    float2 textureCoordinate;
};

vertex MyVertex vertexShader(device float4 *position [[ buffer(0) ]],
                             device float2 *textureCoordinate [[ buffer(1) ]],
                             uint vertexId [[vertex_id]]) {
    MyVertex v;
    v.position = position[vertexId];
    v.textureCoordinate = textureCoordinate[vertexId];
    return v;
}

fragment half4 fragmentShader(MyVertex vertexIn [[stage_in]],
                               texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    return half4(texture.sample(defaultSampler, vertexIn.textureCoordinate));
}
