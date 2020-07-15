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

uint2 rotate2d(uint2 x, float theta) {
    float2x2 r = float2x2(float2(cos(theta), -sin(theta)),
                          float2(sin(theta), cos(theta)));
    return uint2(float2(x) * r);
}

vertex MyVertex vertexShader(device float4 *position [[ buffer(0) ]],
                             device float2 *textureCoordinate [[ buffer(1) ]],
                             constant Constants &constants [[ buffer(2) ]],
                             uint vertexId [[vertex_id]]) {
    return {
        rotate2d(position[vertexId], constants.rotateBy),
        textureCoordinate[vertexId]
    };
}

fragment half4 fragmentShader(MyVertex vertexIn [[stage_in]],
                              sampler sampler [[ sampler(0) ]],
                              texture2d<float, access::sample> texture [[ texture(0) ]]) {
    vertexIn.textureCoordinate.y = 1.0 - vertexIn.textureCoordinate.y;
    return half4(texture.sample(sampler, vertexIn.textureCoordinate));
}

kernel void computeShader(texture2d<float, access::read> inTexture [[ texture(0) ]],
                          texture2d<float, access::write> outTexture [[ texture(1) ]],
                          uint2 gridId [[ thread_position_in_grid ]]) {
    float4 inColor = inTexture.read(gridId);
    outTexture.write(inColor, gridId);
}
