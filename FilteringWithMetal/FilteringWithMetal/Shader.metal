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

struct Constants {
    float width;
    float height;
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
                              constant Constants &constants [[ buffer(0) ]],
                              texture2d<float, access::sample> texture [[ texture(0) ]]) {
    constexpr sampler defaultSampler;
    
    const float width = constants.width;
    const float height = constants.height;
    const float dw = 1.0 / width;
    const float dh = 1.0 / height;
    vertexIn.texCoor.y = 1 - vertexIn.texCoor.y;
    
    float4 accumColor(0, 0, 0, 0);
    float size = 5;
    for (int j = 0; j < size; j++)
    {
       for (int i = 0; i < size; i++)
       {
           float2 kernelIndex(i* dw + vertexIn.texCoor.x, j * dh + vertexIn.texCoor.y);
           float4 color = texture.sample(defaultSampler, kernelIndex);
           accumColor += color;
       }
    }
    return half4(accumColor.rgba / (size * size));
    
}
