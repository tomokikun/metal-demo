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

struct Constants {
    float rotateBy;
};

float4 rotate2d(float4 x, float theta) {
    float2x2 r = float2x2(float2(cos(theta), -sin(theta)),
                          float2(sin(theta), cos(theta)));
    return float4(x.xy * r, 0, 1);
}

vertex MyVertex vertexShader(device float4 *position [[ buffer(0) ]],
                             device float2 *textureCoordinate [[ buffer(1) ]],
                             constant Constants &constants [[ buffer(2) ]],
                             uint vertexId [[vertex_id]]) {
    MyVertex v;
    v.position = rotate2d(position[vertexId], constants.rotateBy);
    v.textureCoordinate = textureCoordinate[vertexId];
    return v;
}

fragment half4 fragmentShader(MyVertex vertexIn [[stage_in]],
                               texture2d<float> texture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    return half4(texture.sample(defaultSampler, vertexIn.textureCoordinate));
}

