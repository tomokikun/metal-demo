//
//  Shader.metal
//  FilteringWithMetal
//
//  Created by 前川　知紀 on 2020/07/22.
//  Copyright © 2020 Maekawa Tomoki. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[ position ]];
    float2 texCoor;
};

vertex VertexIn vertexShader(device float4 *position [[ buffer(0) ]],
                           device float2 *texCoor [[ buffer(1) ]],
                           uint vid [[ vertex_id]]) {
    return {
        position[vid],
        texCoor[vid],
    };
}

fragment half4 fragmentShader(VertexIn vertexIn [[ stage_in ]],
                              texture2d<float, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    vertexIn.texCoor.y = 1 - vertexIn.texCoor.y;
    return half4(texture.sample(defaultSampler, vertexIn.texCoor.xy));
}


